import'dart:async';
import'dart:convert';
import'dart:io';
import'package:flutter/foundation.dart';
import'package:path_provider/path_provider.dart';
import'package:shared_preferences/shared_preferences.dart';
import'../models/reminder.dart';
import'i18n_service.dart';
import'auth_service.dart';
import'notification_service.dart';
import'hive_service.dart';
import'webrtc_service.dart';
import'cloud_sync_service.dart';

class ScheduleService extends ChangeNotifier {
 double _hydrationTargetLiters = 2.0; // Default: 2.0 Liters (8 glasses) for elder hydration
 int _hydrationCurrentGlasses = 0;

 final List<ReminderItem> _reminders = [];
 final Map<String, Timer> _scheduledTimers = {};
 final Map<String, Timer> _followUpTimers = {};
 final Map<String, String> _lastNotifiedMinutes = {};

 Timer? _hydrationTimer;
 Timer? _clockCheckTimer;
 Timer? _autoSyncTimer;
 bool _isAutoSyncRunning = false;
 String _currentElderId ='';
 String _lastSavedJson ='';

 final CloudSyncService _cloudSync = CloudSyncService();

 Map<String, dynamic>? _activeNotification;
 I18nService? _i18n;
 AuthService? _auth;
 WebRTCService? _webRtcService;

 String? _breakfastVoicePath;
 String? _lunchVoicePath;
 String? _dinnerVoicePath;

 String? get breakfastVoicePath => _breakfastVoicePath;
 String? get lunchVoicePath => _lunchVoicePath;
 String? get dinnerVoicePath => _dinnerVoicePath;

 String get currentElderId => _currentElderId;

 bool get isCaretakerMode => _auth?.isCaretaker ?? false;

 void updateAuth(AuthService auth) {
 final roleChanged = _auth?.isCaretaker != auth.isCaretaker || _auth?.currentUser?.id != auth.currentUser?.id;
 _auth = auth;
 if (auth.isCaretaker) {
 cancelAllNativeAlarms();
 _activeNotification = null;
 } else if (roleChanged) {
 syncAllNativeAlarms();
 }
 }

 void cancelAllNativeAlarms() {
 for (final item in _reminders) {
 final alarmId = item.id.hashCode.abs() % 100000;
 NotificationService.cancelAlarm(alarmId);
 }
 NotificationService.cancelAlarm(999999);
 }

 ScheduleService() {
 _startPeriodicClockChecker();
 _startAutoSyncTimer();
 loadSchedules();

 // Register callback for drag-down notification action buttons (Taken / Yet to Take / Started / Not Started / Log Water)
 NotificationService.onNotificationActionListener = (reminderId, actionType) {
 if (actionType.contains('ACTION_LOG_WATER') || reminderId =='hyd'|| reminderId.startsWith('hyd_')) {
 logWaterGlass();
 } else if (actionType.contains('ACTION_TAKEN') || actionType.contains('ACTION_STARTED')) {
 markReminderTaken(reminderId);
 } else if (actionType.contains('ACTION_YET_TO_TAKE') || actionType.contains('ACTION_NOT_STARTED')) {
 markReminderYetToTake(reminderId);
 }
 };
 }

 void attachWebRTCService(WebRTCService service) {
 _webRtcService = service;
 _webRtcService?.setOnReminderReceivedCallback((reminder, action) {
 onP2PReminderReceived(reminder, action);
 });
 }

 void setCurrentElderId(String elderId) {
 final cleanId = elderId.trim().toUpperCase();
 if (cleanId.isNotEmpty && cleanId != _currentElderId) {
 _currentElderId = cleanId;
 debugPrint('SYNC ELDER ID = $_currentElderId');
 loadSchedules(elderId: _currentElderId);
 _startAutoSyncTimer();
 notifyListeners();
 }
 }

 Future<void> updateElderId(String elderId) async {
 _currentElderId = elderId.trim().toUpperCase();
 debugPrint('SYNC ELDER ID = $_currentElderId');
 await loadSchedules(elderId: _currentElderId);
 _startAutoSyncTimer();
 notifyListeners();
 }

 Future<List<ReminderItem>> _parseAndDecodeCloudReminders(List rawList) async {
 final Directory appDir = await getApplicationDocumentsDirectory();
 final List<ReminderItem> items = [];

 for (final e in rawList) {
 final Map<String, dynamic> rMap = Map<String, dynamic>.from(e);
 final rId = (rMap['id'] ?? DateTime.now().millisecondsSinceEpoch).toString();

 // 1. Decode custom voice Base64 audio note if present
 if (rMap['customVoiceBase64'] != null && rMap['customVoiceBase64'].toString().isNotEmpty) {
 try {
 final voiceBytes = base64Decode(rMap['customVoiceBase64'].toString());
 final voiceFile = File('${appDir.path}/cloud_reminder_voice_$rId.m4a');
 await voiceFile.writeAsBytes(voiceBytes);
 rMap['customVoicePath'] = voiceFile.path;
 rMap['voiceMode'] = 1;
 debugPrint('Decoded cloud reminder voice note to: ${voiceFile.path} (${voiceBytes.length} bytes)');
 } catch (err) {
 debugPrint('Error decoding cloud reminder custom voice: $err');
 }
 }

 // 2. Decode cloned voice Base64 audio sample if present
 if (rMap['clonedVoiceBase64'] != null && rMap['clonedVoiceBase64'].toString().isNotEmpty) {
 try {
 final sampleBytes = base64Decode(rMap['clonedVoiceBase64'].toString());
 final sampleFile = File('${appDir.path}/cloud_cloned_voice_$rId.m4a');
 await sampleFile.writeAsBytes(sampleBytes);
 rMap['clonedVoiceSamplePath'] = sampleFile.path;
 if (rMap['customVoicePath'] == null || rMap['customVoicePath'].toString().isEmpty) {
 rMap['customVoicePath'] = sampleFile.path;
 }
 rMap['voiceMode'] = 2;
 } catch (err) {
 debugPrint('Error decoding cloud cloned voice sample: $err');
 }
 }

 items.add(ReminderItem.fromJson(rMap));
 }
 return items;
 }

 /// Resets and clears all in-memory and local schedule data for a newly created account
 Future<void> clearAndResetForNewUser(String newElderId) async {
 _currentElderId = newElderId.trim().toUpperCase();
 debugPrint('SYNC ELDER ID = $_currentElderId');
 _reminders.clear();
 _hydrationTargetLiters = 0.0;
 _hydrationCurrentGlasses = 0;
 _lastSavedJson ='';

 for (final timer in _scheduledTimers.values) {
 timer.cancel();
 }
 _scheduledTimers.clear();

 for (final timer in _followUpTimers.values) {
 timer.cancel();
 }
 _followUpTimers.clear();

 await HiveService.clearRemindersForElder(_currentElderId);
 await HiveService.saveHydrationStateForElder(_currentElderId, 0.0, 0);

 final prefs = await SharedPreferences.getInstance();
 if (_currentElderId.isNotEmpty) {
 await prefs.remove('aninai_schedules_$_currentElderId');
 await prefs.remove('cloud_schedules_$_currentElderId');
 }

 // Pull fresh cloud schedules for this newly logged-in/registered Elder ID
 if (_currentElderId.isNotEmpty) {
 final cloudData = await _cloudSync.pullScheduleCloud(_currentElderId);
 if (cloudData != null && cloudData['reminders'] is List) {
 final cloudRemindersRaw = cloudData['reminders'] as List;
 final cloudHydTarget = (cloudData['hydrationTargetLiters'] as num?)?.toDouble() ?? 0.0;
 final cloudHydGlasses = (cloudData['hydrationCurrentGlasses'] as num?)?.toInt() ?? 0;

 _reminders.clear();
 final decodedReminders = await _parseAndDecodeCloudReminders(cloudRemindersRaw);
 _reminders.addAll(decodedReminders);
 _hydrationTargetLiters = cloudHydTarget;
 _hydrationCurrentGlasses = cloudHydGlasses;

 await HiveService.saveAllRemindersForElder(_currentElderId, _reminders);
 await HiveService.saveHydrationStateForElder(_currentElderId, _hydrationTargetLiters, _hydrationCurrentGlasses);
 }
 }

 _startAutoSyncTimer();
 syncAllNativeAlarms();
 notifyListeners();
 }

 Future<void> loadSchedules({String? elderId}) async {
 try {
 final targetId = (elderId != null && elderId.trim().isNotEmpty) ? elderId.trim().toUpperCase() : _currentElderId;
 _currentElderId = targetId;

 debugPrint('SYNC ELDER ID = $_currentElderId');

 await HiveService.init();
 final prefs = await SharedPreferences.getInstance();
 final key ='aninai_schedules_$targetId';
 String? raw = prefs.getString(key);

 _reminders.clear();
 if (raw != null && raw.isNotEmpty) {
 _lastSavedJson = raw;
 final decoded = jsonDecode(raw) as List;
 for (var item in decoded) {
 final r = ReminderItem.fromJson(Map<String, dynamic>.from(item));
 _reminders.add(r);
 _scheduleReminderTimer(r);
 }
 } else if (targetId.isNotEmpty) {
 final hiveItems = HiveService.getRemindersForElder(targetId);
 if (hiveItems.isNotEmpty) {
 _reminders.addAll(hiveItems);
 for (var r in _reminders) {
 _scheduleReminderTimer(r);
 }
 }
 }

 if (targetId.isNotEmpty) {
 final hydKey ='aninai_hydration_$targetId';
 final hydState = HiveService.getHydrationStateForElder(targetId);
 _hydrationTargetLiters = prefs.getDouble(hydKey) ?? (hydState?['targetLiters'] as num?)?.toDouble() ?? 2.0;
 _hydrationCurrentGlasses = prefs.getInt('${hydKey}_glasses') ?? (hydState?['currentGlasses'] as num?)?.toInt() ?? 0;

 _breakfastVoicePath = prefs.getString('aninai_meal_voice_breakfast_$targetId') ?? prefs.getString('aninai_meal_voice_breakfast');
 _lunchVoicePath = prefs.getString('aninai_meal_voice_lunch_$targetId') ?? prefs.getString('aninai_meal_voice_lunch');
 _dinnerVoicePath = prefs.getString('aninai_meal_voice_dinner_$targetId') ?? prefs.getString('aninai_meal_voice_dinner');
 }

 // Fetch cloud sync schedules for active Elder ID
 if (targetId.isNotEmpty) {
 final cloudData = await _cloudSync.pullScheduleCloud(targetId);
 if (cloudData != null && cloudData['reminders'] is List) {
 final cloudRemindersRaw = cloudData['reminders'] as List;
 final cloudHydTarget = (cloudData['hydrationTargetLiters'] as num?)?.toDouble();
 final cloudHydGlasses = (cloudData['hydrationCurrentGlasses'] as num?)?.toInt();

 final cloudReminders = await _parseAndDecodeCloudReminders(cloudRemindersRaw);

 _reminders.clear();
 _reminders.addAll(cloudReminders);
 for (var r in _reminders) {
 _scheduleReminderTimer(r);
 }
 if (cloudHydTarget != null) _hydrationTargetLiters = cloudHydTarget;
 if (cloudHydGlasses != null) _hydrationCurrentGlasses = cloudHydGlasses;

 final encoded = jsonEncode(_reminders.map((r) => r.toJson()).toList());
 _lastSavedJson = encoded;
 await prefs.setString(key, encoded);
 await HiveService.saveAllRemindersForElder(targetId, _reminders);
 await HiveService.saveHydrationStateForElder(targetId, _hydrationTargetLiters, _hydrationCurrentGlasses);
 } else if (_reminders.isNotEmpty && (raw != null || HiveService.getRemindersForElder(targetId).isNotEmpty)) {
 // If local record exists for this Elder ID, sync to Cloud Relay
 await _cloudSync.pushScheduleCloud(targetId, _reminders, _hydrationTargetLiters, _hydrationCurrentGlasses);
 } else if (cloudData == null && raw == null) {
 _reminders.clear();
 _hydrationTargetLiters = 2.0;
 _hydrationCurrentGlasses = 0;
 }
 }

 await _autoFixRoutineVoicePaths();
 syncAllNativeAlarms();
 notifyListeners();
 } catch (e) {
 print('ScheduleService load error: $e');
 }
 }

 Future<void> setMealVoicePath(String mealKey, String? path) async {
 final prefs = await SharedPreferences.getInstance();
 final key = 'aninai_meal_voice_${mealKey}_$_currentElderId';
 final globalKey = 'aninai_meal_voice_$mealKey';
 if (path != null && path.isNotEmpty) {
 if (mealKey == 'breakfast') _breakfastVoicePath = path;
 if (mealKey == 'lunch') _lunchVoicePath = path;
 if (mealKey == 'dinner') _dinnerVoicePath = path;
 await prefs.setString(key, path);
 await prefs.setString(globalKey, path);
 } else {
 if (mealKey == 'breakfast') _breakfastVoicePath = null;
 if (mealKey == 'lunch') _lunchVoicePath = null;
 if (mealKey == 'dinner') _dinnerVoicePath = null;
 await prefs.remove(key);
 await prefs.remove(globalKey);
 }
 notifyListeners();
 }

 Map<String, String> getSavedVoiceRecords(I18nService i18n) {
 final isTamil = i18n.currentLang == 'ta';
 final Map<String, String> records = {};

 _scanAndLoadMealVoicesFromDiskSync();

 if (_breakfastVoicePath != null && _breakfastVoicePath!.isNotEmpty && File(_breakfastVoicePath!).existsSync()) {
 records[isTamil ? 'Morning Breakfast (காலை உணவு) Voice Note' : 'Morning Breakfast Voice Note'] = _breakfastVoicePath!;
 }
 if (_lunchVoicePath != null && _lunchVoicePath!.isNotEmpty && File(_lunchVoicePath!).existsSync()) {
 records[isTamil ? 'Afternoon Lunch (மதிய உணவு) Voice Note' : 'Afternoon Lunch Voice Note'] = _lunchVoicePath!;
 }
 if (_dinnerVoicePath != null && _dinnerVoicePath!.isNotEmpty && File(_dinnerVoicePath!).existsSync()) {
 records[isTamil ? 'Night Dinner (இரவு உணவு) Voice Note' : 'Night Dinner Voice Note'] = _dinnerVoicePath!;
 }

 return records;
 }

 void _scanAndLoadMealVoicesFromDiskSync() {
 try {
 final dir = Directory('/data/user/0/com.example.aninai/app_flutter');
 if (!dir.existsSync()) return;
 final files = dir.listSync().whereType<File>().toList();
 if (_breakfastVoicePath == null || !File(_breakfastVoicePath!).existsSync()) {
 final bf = files.where((f) => f.path.contains('meal_voice_breakfast') && f.path.endsWith('.m4a') && f.lengthSync() > 0).toList();
 if (bf.isNotEmpty) {
 bf.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
 _breakfastVoicePath = bf.first.path;
 }
 }
 if (_lunchVoicePath == null || !File(_lunchVoicePath!).existsSync()) {
 final l = files.where((f) => f.path.contains('meal_voice_lunch') && f.path.endsWith('.m4a') && f.lengthSync() > 0).toList();
 if (l.isNotEmpty) {
 l.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
 _lunchVoicePath = l.first.path;
 }
 }
 if (_dinnerVoicePath == null || !File(_dinnerVoicePath!).existsSync()) {
 final d = files.where((f) => f.path.contains('meal_voice_dinner') && f.path.endsWith('.m4a') && f.lengthSync() > 0).toList();
 if (d.isNotEmpty) {
 d.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
 _dinnerVoicePath = d.first.path;
 }
 }
 } catch (_) {}
 }

 static String? _cachedLatestCustomVoicePath;

 static Future<String> getLatestCustomVoicePath() async {
 if (_cachedLatestCustomVoicePath != null && _cachedLatestCustomVoicePath!.isNotEmpty && File(_cachedLatestCustomVoicePath!).existsSync()) {
 return _cachedLatestCustomVoicePath!;
 }
 try {
 final dir = await getApplicationDocumentsDirectory();
 if (dir.existsSync()) {
 final files = dir
 .listSync()
 .whereType<File>()
 .where((f) => f.path.contains('custom_reminder_voice_') && f.path.endsWith('.m4a') && f.lengthSync() > 0)
 .toList();
 if (files.isNotEmpty) {
 files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
 _cachedLatestCustomVoicePath = files.first.path;
 return files.first.path;
 }
 }
 } catch (e) {
 debugPrint('Error finding latest custom voice file: $e');
 }
 return'';
 }

 Future<void> _autoFixRoutineVoicePaths() async {
 final latestVoicePath = await getLatestCustomVoicePath();
 if (latestVoicePath.isEmpty) return;

 bool updated = false;
 for (int i = 0; i < _reminders.length; i++) {
 if (_reminders[i].type == ReminderType.routine) {
 if (_reminders[i].customVoicePath.isEmpty || !File(_reminders[i].customVoicePath).existsSync()) {
 _reminders[i] = ReminderItem(
 id: _reminders[i].id,
 type: _reminders[i].type,
 title: _reminders[i].title,
 time: _reminders[i].time,
 detail: _reminders[i].detail,
 pillsCount: _reminders[i].pillsCount,
 instructions: _reminders[i].instructions,
 customVoicePath: latestVoicePath,
 voiceMode: 1,
 clonedVoiceSamplePath: _reminders[i].clonedVoiceSamplePath,
 isCompleted: _reminders[i].isCompleted,
 createdByRole: _reminders[i].createdByRole,
 );
 updated = true;
 }
 }
 }
 if (updated) {
 await saveSchedules();
 }
 }

 Future<void> saveSchedules({String? elderId}) async {
 try {
 final targetId = (elderId != null && elderId.trim().isNotEmpty) ? elderId.trim().toUpperCase() : _currentElderId;

 await HiveService.saveAllRemindersForElder(targetId, _reminders);
 await HiveService.saveHydrationStateForElder(targetId, _hydrationTargetLiters, _hydrationCurrentGlasses);

 final prefs = await SharedPreferences.getInstance();
 final key ='aninai_schedules_$targetId';
 final encoded = jsonEncode(_reminders.map((r) => r.toJson()).toList());
 _lastSavedJson = encoded;
 await prefs.setString(key, encoded);

 final hydKey ='aninai_hydration_$targetId';
 await prefs.setDouble(hydKey, _hydrationTargetLiters);
 await prefs.setInt('${hydKey}_glasses', _hydrationCurrentGlasses);

 if (_webRtcService != null && _webRtcService!.isConnected) {
 _webRtcService!.syncAllRemindersOverP2P();
 }

 // Push to Cloud Relay for cross-device synchronization
 await _cloudSync.pushScheduleCloud(
 targetId,
 _reminders,
 _hydrationTargetLiters,
 _hydrationCurrentGlasses,
 );

 syncAllNativeAlarms();
 notifyListeners();
 } catch (e) {
 print('ScheduleService save error: $e');
 }
 }

 /// Handle incoming WebRTC P2P remote reminder payload
 void onP2PReminderReceived(ReminderItem item, String action) {
 if (action =='REMINDER_DELETE') {
 _reminders.removeWhere((r) => r.id == item.id);
 _scheduledTimers[item.id]?.cancel();
 _scheduledTimers.remove(item.id);
 HiveService.deleteReminder(item.id);
 saveSchedules();
 } else {
 final index = _reminders.indexWhere((r) => r.id == item.id);
 if (index != -1) {
 _reminders[index] = item;
 } else {
 _reminders.insert(0, item);
 }
 _scheduleReminderTimer(item);
 }
 syncAllNativeAlarms();
 notifyListeners();
 }

 Future<void> _applyCloudData(Map<String, dynamic> cloudData) async {
 if (cloudData['reminders'] is! List) return;

 try {
 final cloudRemindersRaw = cloudData['reminders'] as List;
 final cloudHydTarget = (cloudData['hydrationTargetLiters'] as num?)?.toDouble();
 final cloudHydGlasses = (cloudData['hydrationCurrentGlasses'] as num?)?.toInt();

 final cloudReminders = await _parseAndDecodeCloudReminders(cloudRemindersRaw);

 // Conflict resolution: preserve local completed status if elder completed it locally
 for (int idx = 0; idx < cloudReminders.length; idx++) {
 final cItem = cloudReminders[idx];
 final lIndex = _reminders.indexWhere((r) => r.id == cItem.id);
 if (lIndex != -1) {
 final localItem = _reminders[lIndex];
 if (localItem.isCompleted && !cItem.isCompleted) {
 cloudReminders[idx].isCompleted = true;
 }
 }
 }

 bool updated = false;

 if (cloudReminders.length != _reminders.length) {
 updated = true;
 } else {
 for (int i = 0; i < cloudReminders.length; i++) {
 final cItem = cloudReminders[i];
 final lIndex = _reminders.indexWhere((r) => r.id == cItem.id);
 if (lIndex == -1 ||
 _reminders[lIndex].isCompleted != cItem.isCompleted ||
 _reminders[lIndex].title != cItem.title ||
 _reminders[lIndex].time != cItem.time ||
 _reminders[lIndex].reminderAttempt != cItem.reminderAttempt) {
 updated = true;
 break;
 }
 }
 }

 if (updated) {
 _reminders.clear();
 _reminders.addAll(cloudReminders);
 for (var r in _reminders) {
 _scheduleReminderTimer(r);
 }
 await HiveService.saveAllRemindersForElder(_currentElderId, _reminders);
 }

 if (cloudHydTarget != null && cloudHydTarget != _hydrationTargetLiters) {
 _hydrationTargetLiters = cloudHydTarget;
 updated = true;
 }
 if (cloudHydGlasses != null && cloudHydGlasses != _hydrationCurrentGlasses) {
 _hydrationCurrentGlasses = cloudHydGlasses;
 updated = true;
 }

 if (updated) {
 await HiveService.saveHydrationStateForElder(_currentElderId, _hydrationTargetLiters, _hydrationCurrentGlasses);
 syncAllNativeAlarms();
 notifyListeners();
 }
 } catch (e) {
 debugPrint('Apply Cloud Data Error: $e');
 }
 }

 void _startAutoSyncTimer() {
 _autoSyncTimer?.cancel();
 if (_currentElderId.isNotEmpty) {
 _cloudSync.startRealtimeScheduleListener(_currentElderId, (data) => _applyCloudData(data));
 }

 _autoSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
 if (_isAutoSyncRunning) return;
 _isAutoSyncRunning = true;

 try {
 if (_currentElderId.isEmpty) return;

 final pullResponse = await _cloudSync.pullScheduleCloudDetailed(_currentElderId);

 if (pullResponse.status == CloudSyncStatus.networkError) {
 return;
 }

 final cloudData = pullResponse.data;
 if (cloudData != null) {
 await _applyCloudData(cloudData);
 } else if (_reminders.isNotEmpty) {
 // Push local schedule to Cloud Relay so Elder ID has a cloud record
 await _cloudSync.pushScheduleCloud(_currentElderId, _reminders, _hydrationTargetLiters, _hydrationCurrentGlasses);
 }
 } catch (e) {
 debugPrint('AUTOSYNC error: $e');
 } finally {
 _isAutoSyncRunning = false;
 }
 });
 }

 double get hydrationTargetLiters => _hydrationTargetLiters;
 int get hydrationTargetGlasses => (_hydrationTargetLiters * 4).round();
 int get hydrationCurrentGlasses => _hydrationCurrentGlasses;
 double get hydrationCurrentLiters => _hydrationCurrentGlasses * 0.25;
 List<ReminderItem> get reminders => _reminders;
 Map<String, dynamic>? get activeNotification => _activeNotification;
 bool get isHydrationTimerActive => _hydrationTimer != null && _hydrationTimer!.isActive;

 void updateI18n(I18nService i18n) {
 final langChanged = _i18n?.currentLang != i18n.currentLang;
 _i18n = i18n;
 if (langChanged) {
 syncAllNativeAlarms();
 }
 }

 @override
 void dispose() {
 _autoSyncTimer?.cancel();
 _hydrationTimer?.cancel();
 _clockCheckTimer?.cancel();
 for (final timer in _scheduledTimers.values) {
 timer.cancel();
 }
 _scheduledTimers.clear();
 for (final timer in _followUpTimers.values) {
 timer.cancel();
 }
 _followUpTimers.clear();
 super.dispose();
 }

 void markReminderTaken(String reminderId) {
 if (reminderId.isNotEmpty) {
 _followUpTimers[reminderId]?.cancel();
 _followUpTimers.remove(reminderId);

 final baseId = reminderId.hashCode.abs() % 100000;
 NotificationService.cancelAlarm(baseId);
 NotificationService.cancelAlarm(baseId * 10 + 2);
 NotificationService.cancelAlarm(baseId * 10 + 3);

 final index = _reminders.indexWhere((r) => r.id == reminderId);
 final isRoutine = (index != -1 && _reminders[index].type == ReminderType.routine) || reminderId.startsWith("act_") || reminderId.contains("act") || reminderId.contains("routine");
 if (index != -1) {
 _reminders[index].isCompleted = true;
 saveSchedules();
 speakMotivationalSuccessVoice(
 customVoicePath: _reminders[index].customVoicePath,
 voiceMode: _reminders[index].voiceMode,
 clonedVoiceSamplePath: _reminders[index].clonedVoiceSamplePath,
 isRoutine: isRoutine,
 );
 dismissNotification();
 return;
 }
 }
 final activeIndex = _reminders.indexWhere((r) => !r.isCompleted);
 final isRoutineFallback = (activeIndex != -1 && _reminders[activeIndex].type == ReminderType.routine) || reminderId.startsWith("act_") || reminderId.contains("act") || reminderId.contains("routine");
 if (activeIndex != -1) {
 _reminders[activeIndex].isCompleted = true;
 saveSchedules();
 }
 speakMotivationalSuccessVoice(isRoutine: isRoutineFallback);
 dismissNotification();
 }

 void markReminderYetToTake(String reminderId) {
 if (reminderId.isNotEmpty) {
 final index = _reminders.indexWhere((r) => r.id == reminderId);
 final isRoutine = (index != -1 && _reminders[index].type == ReminderType.routine) || reminderId.startsWith("act_") || reminderId.contains("act") || reminderId.contains("routine");
 if (index != -1) {
 _reminders[index].isCompleted = false;
 saveSchedules();
 speakGentleAdviceVoice(
 customVoicePath: _reminders[index].customVoicePath,
 voiceMode: _reminders[index].voiceMode,
 clonedVoiceSamplePath: _reminders[index].clonedVoiceSamplePath,
 isRoutine: isRoutine,
 );
 dismissNotification();
 return;
 }
 }
 final isRoutineFallback = reminderId.startsWith("act_") || reminderId.contains("act") || reminderId.contains("routine");
 speakGentleAdviceVoice(isRoutine: isRoutineFallback);
 dismissNotification();
 }

 /// Periodic 15-second background clock checker to guarantee no scheduled reminder is missed
 void _startPeriodicClockChecker() {
 _clockCheckTimer?.cancel();
 _clockCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
 _checkAndTriggerDueReminders();
 });
 }

 void _checkAndTriggerDueReminders() {
 if (isCaretakerMode) return;
 final now = DateTime.now();
 final currentMinuteKey ="${now.year}-${now.month}-${now.day}_${now.hour}:${now.minute}";

 for (final r in _reminders) {
 if (r.isCompleted) continue;

 final targetDate = parseScheduledTimeToDateTime(r.time);
 if (targetDate != null) {
 if (targetDate.hour == now.hour && targetDate.minute == now.minute) {
 if (_lastNotifiedMinutes[r.id] != currentMinuteKey) {
 _lastNotifiedMinutes[r.id] = currentMinuteKey;
 triggerScheduleNotificationItem(r, i18n: _i18n);
 }
 }
 }
 }
 }

 String _getTypeLabelKey(ReminderType type) {
 switch (type) {
 case ReminderType.medicine:
 return'addMedReminder';
 case ReminderType.appointment:
 return'scheduleAppt';
 case ReminderType.routine:
 return'scheduleDailyActivity';
 case ReminderType.hydration:
 return'hourlyHydrationTitle';
 }
 }

 /// Parses 12-hour (e.g."08:00 AM","8:30 PM") and 24-hour ("14:30") strings into a target DateTime
 DateTime? parseScheduledTimeToDateTime(String timeStr) {
 final now = DateTime.now();
 final timeUpper = timeStr.trim().toUpperCase();

 // 1. Try 12-Hour format with AM/PM (e.g.,"08:00 AM","8:30 PM","11:15 AM","12:00 PM")
 final reg12 = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)');
 final match12 = reg12.firstMatch(timeUpper);
 if (match12 != null) {
 int hour = int.parse(match12.group(1) ??'0');
 final minute = int.parse(match12.group(2) ??'0');
 final isPm = match12.group(3) =='PM';

 if (hour == 12) {
 hour = isPm ? 12 : 0;
 } else if (isPm) {
 hour += 12;
 }

 var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
 // If the target time for today has passed by more than 1 minute, schedule for tomorrow
 if (scheduledDate.isBefore(now.subtract(const Duration(minutes: 1)))) {
 scheduledDate = scheduledDate.add(const Duration(days: 1));
 }
 return scheduledDate;
 }

 // 2. Try 24-Hour format (e.g.,"14:30","08:00")
 final reg24 = RegExp(r'(\d{1,2}):(\d{2})');
 final match24 = reg24.firstMatch(timeUpper);
 if (match24 != null) {
 final hour = int.parse(match24.group(1) ??'0');
 final minute = int.parse(match24.group(2) ??'0');

 var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
 if (scheduledDate.isBefore(now.subtract(const Duration(minutes: 1)))) {
 scheduledDate = scheduledDate.add(const Duration(days: 1));
 }
 return scheduledDate;
 }

 return null;
 }

 void _scheduleReminderTimer(ReminderItem item, {I18nService? i18n}) {
 _scheduledTimers[item.id]?.cancel();
 if (isCaretakerMode) return;

 final targetDate = parseScheduledTimeToDateTime(item.time);
 if (targetDate != null) {
 final delay = targetDate.difference(DateTime.now());
 if (delay.inSeconds > 0) {
 _scheduledTimers[item.id] = Timer(delay, () {
 final now = DateTime.now();
 final currentMinuteKey ="${now.year}-${now.month}-${now.day}_${now.hour}:${now.minute}";
 _lastNotifiedMinutes[item.id] = currentMinuteKey;

 triggerScheduleNotificationItem(item, i18n: i18n ?? _i18n);
 });
 }
 }
 }

 void _startHourlyHydrationTimer() {
 _hydrationTimer?.cancel();
 if (_hydrationTargetLiters > 0) {
 // Automatic 1-Hour periodic timer for hydration reminder
 _hydrationTimer = Timer.periodic(const Duration(hours: 1), (timer) {
 triggerHourlyHydrationAlert();
 });
 } else {
 _hydrationTimer = null;
 }
 }

 void triggerHourlyHydrationAlert({bool isManualTest = false, I18nService? i18n}) {
 if (isCaretakerMode && !isManualTest) return;
 if (_hydrationTargetLiters > 0 || isManualTest) {
 final activeI1n = i18n ?? _i18n;
 final langCode = activeI1n?.currentLang ??'en';
 final isTamil = langCode.toLowerCase() =='ta';
 final title = activeI1n?.translate('hourlyHydrationTitle') ??'Hydration Reminder';
 final body = activeI1n?.translate('hourlyHydrationDesc') ??'Time to drink a glass of fresh water!';

 _activeNotification = {
'id':'hyd_${DateTime.now().millisecondsSinceEpoch}',
'title': title,
'body': body,
'isHydration': true,
'timestamp': DateTime.now(),
 };

 final logWaterBtnText = activeI1n?.translate('logWaterBtn') ??'1 Glass Water';
 final fallbackEn = isTamil
 ?'Hydration Reminder. Kudineer ninaivootal. Thannir kudika vendum. Time to drink a glass of fresh water.'
 :'Hydration Reminder. Time to drink a glass of fresh water.';

 NotificationService.showSystemNotification(
 title: title,
 body: body,
 spokenText:'$title. $body',
 fallbackEnglishText: fallbackEn,
 reminderId:'hyd',
 takenLabel: logWaterBtnText,
 yetToTakeLabel: logWaterBtnText,
 langCode: langCode,
 isHydration: true,
 showActions: true,
 speak: true,
 onAction: () => logWaterGlass(),
 );

 notifyListeners();
 }
 }

 /// Builds clean, deduplicated speech strings for medicine reminders in native and fallback TTS engines
 Map<String, String> buildMedicineSpeech({
 required String title,
 required String pillsCount,
 required String instructions,
 required String langCode,
 I18nService? i18n,
 }) {
 final isTamil = langCode.toLowerCase() =='ta';

 // 1. Clean title: strip embedded dates/times (e.g."12 Sep 2026 at 649 PM private")
 String displayTitle = title
 .replaceAll(RegExp(r'\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}', caseSensitive: false),'')
 .replaceAll(RegExp(r'\b(at\s+)?\d{1,4}\s*(AM|PM)\b', caseSensitive: false),'')
 .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]', unicode: true),'')
 .trim();

 // 2. Deduplicate consecutive repeated words (e.g."private private"->"private")
 final words = displayTitle.split(RegExp(r'\s+'));
 final dedupWords = <String>[];
 for (final w in words) {
 if (w.isEmpty) continue;
 if (dedupWords.isEmpty || dedupWords.last.toLowerCase() != w.toLowerCase()) {
 dedupWords.add(w);
 }
 }
 displayTitle = dedupWords.join('');

 // 3. Prevent duplicate number repetition when title ends with pill count (e.g. title ="private 1", pills ="1")
 final rawPills = pillsCount.replaceAll(RegExp(r'[^\d]'),'').trim().isEmpty ?'1': pillsCount.replaceAll(RegExp(r'[^\d]'),'').trim();
 if (displayTitle.endsWith('$rawPills')) {
 displayTitle = displayTitle.substring(0, displayTitle.length - (rawPills.length + 1)).trim();
 } else if (displayTitle == rawPills) {
 displayTitle ='Medicine';
 }
 if (displayTitle.isEmpty) displayTitle ='Medicine';
 final cleanInst = instructions.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]', unicode: true),'').trim();

 String tamilInst ='';
 String phoneticTamilInst ='';
 if (instructions.isNotEmpty) {
 final instLower = instructions.toLowerCase();

 // 1. Breakfast Before
 if (instLower.contains('mealbreakfastbefore') ||
 (instLower.contains('காலை') && instLower.contains('முன்')) ||
 ((instLower.contains('morning') || instLower.contains('breakfast') || instLower.contains('जलपान') || instLower.contains('প্রাতরাশ') || instLower.contains('ei hma')) && instLower.contains('before')) ||
 ((instLower.contains('morning') || instLower.contains('breakfast')) && (instLower.contains('before') || instLower.contains('aage') || instLower.contains('agoi') || instLower.contains('shuwa')))) {
 tamilInst ='காலை உணவுக்கு முன்.';
 phoneticTamilInst ='Kaalai unavukku mun.';
 }
 // 2. Breakfast After
 else if (instLower.contains('mealbreakfast') ||
 (instLower.contains('காலை') && (instLower.contains('பின்') || instLower.contains('பிନ୍'))) ||
 instLower.contains('morning') || instLower.contains('breakfast') || instLower.contains('जलपान') || instLower.contains('প্রাতরাশ') || instLower.contains('step')) {
 tamilInst ='காலை உணவுக்குப் பின்.';
 phoneticTamilInst ='Kaalai unavukku pin.';
 }
 // 3. Lunch Before
 else if (instLower.contains('meallunchbefore') ||
 (instLower.contains('மதிய') && instLower.contains('முன்')) ||
 ((instLower.contains('afternoon') || instLower.contains('lunch') || instLower.contains('ஆஹாரம்')) && instLower.contains('before'))) {
 tamilInst ='மதிய உணவுக்கு முன்.';
 phoneticTamilInst ='Mathiya unavukku mun.';
 }
 // 4. Lunch After
 else if (instLower.contains('meallunch') || instLower.contains('meallunchafter') ||
 (instLower.contains('மதிய') && (instLower.contains('பின்') || instLower.contains('பிନ୍'))) ||
 instLower.contains('afternoon') || instLower.contains('lunch')) {
 tamilInst ='மதிய உணவுக்குப் பின்.';
 phoneticTamilInst ='Mathiya unavukku pin.';
 }
 // 5. Dinner Before
 else if (instLower.contains('mealdinnerbefore') ||
 (instLower.contains('இரவு') && instLower.contains('முன்')) ||
 ((instLower.contains('night') || instLower.contains('dinner')) && instLower.contains('before'))) {
 tamilInst ='இரவு உணவுக்கு முன்.';
 phoneticTamilInst ='Iravu unavukku mun.';
 }
 // 6. Dinner After
 else if (instLower.contains('mealdinner') || instLower.contains('mealdinnerafter') ||
 (instLower.contains('இரவு') && (instLower.contains('பின்') || instLower.contains('பிନ୍'))) ||
 instLower.contains('night') || instLower.contains('dinner')) {
 tamilInst ='இரவு உணவுக்குப் பின்.';
 phoneticTamilInst ='Iravu unavukku pin.';
 }
 // 7. Bedtime / Sleep
 else if (instLower.contains('mealsleep') || instLower.contains('sleep') || instLower.contains('bedtime') || instLower.contains('தூக்க')) {
 tamilInst ='இரவு தூங்குவதற்கு முன்.';
 phoneticTamilInst ='Iravu thookathirku mun.';
 }
 // 8. Water
 else if (instLower.contains('mealwater') || instLower.contains('water') || instLower.contains('தண்ணீ')) {
 tamilInst ='முழு டம்ளர் தண்ணீருடன்.';
 phoneticTamilInst ='Mulu tumbler thanneerudan.';
 }
 // 9. Generic After Meal
 else if (instLower.contains('பின்') || instLower.contains('after meal') || instLower.contains('after')) {
 tamilInst ='உணவுக்குப் பின்.';
 phoneticTamilInst ='Unavukku pin.';
 }
 // 10. Generic Before Meal
 else if (instLower.contains('முன்') || instLower.contains('before meal') || instLower.contains('before')) {
 tamilInst ='உணவுக்கு முன்.';
 phoneticTamilInst ='Unavukku mun.';
 }
 // 11. Custom raw fallback
 else if (cleanInst.isNotEmpty) {
 tamilInst = cleanInst.endsWith('.') ? cleanInst :'$cleanInst.';
 phoneticTamilInst = cleanInst.endsWith('.') ? cleanInst :'$cleanInst.';
 }
 }

 String spokenSpeech ='';
 String fallbackSpeech ='';

 if (isTamil) {
 final prefix ='மருந்து அருந்தும் நேரம்.';
 if (tamilInst.isNotEmpty) {
 spokenSpeech ='$prefix $tamilInst $displayTitle $rawPills மாத்திரைகள் எடுக்கவும்.';
 } else {
 spokenSpeech ='$prefix $displayTitle $rawPills மாத்திரைகள் எடுக்கவும்.';
 }

 final fallbackPrefix ='Marunthu arunthum neram.';
 if (phoneticTamilInst.isNotEmpty) {
 fallbackSpeech ='$fallbackPrefix $phoneticTamilInst $displayTitle $rawPills maathiraigal edukavum.';
 } else {
 fallbackSpeech ='$fallbackPrefix $displayTitle $rawPills maathiraigal edukavum.';
 }
 } else {
 final template = i18n?.translate('takeMedSpeech') ??'Please take {name}, {pills} pill(s).';
 final medSpeech = template.replaceAll('{name}', displayTitle).replaceAll('{pills}', rawPills);
 if (cleanInst.isNotEmpty) {
 spokenSpeech ='Medicine Reminder. $cleanInst. $medSpeech';
 } else {
 spokenSpeech ='Medicine Reminder. $medSpeech';
 }
 fallbackSpeech = spokenSpeech;
 }

 return {
'spokenSpeech': spokenSpeech,
'fallbackSpeech': fallbackSpeech,
'displayTitle': displayTitle,
'cleanInst': cleanInst,
 };
 }

 /// Builds dedicated speech strings and notification body for medical appointments
 Map<String, String> buildAppointmentSpeech({
 required String title,
 required String time,
 required String detail,
 required String langCode,
 I18nService? i18n,
 }) {
 String doctorName = title.trim();
 doctorName = doctorName
 .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]', unicode: true),'')
 .trim();

 final isTamil = langCode.toLowerCase() =='ta';

 if (doctorName =='மருத்துவ சந்திப்பு நினைவூட்டல்'|| doctorName =='மருத்துவ சந்திப்பு'|| doctorName.toLowerCase() =='doctor appointment') {
 doctorName = isTamil ?'மருத்துவர்':'Doctor';
 }

 var venue = detail
 .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]', unicode: true),'')
 .trim();
 if (venue =='Consultation Visit'|| venue =='Doctor Appointment') {
 venue ='';
 }

 String spokenSpeech ='';
 String fallbackSpeech ='';
 String notifBody ='';

 final timePartSpoken = time.isNotEmpty ?'$time மணிக்கு':'';
 final timePartFallback = time.isNotEmpty ?'$time manikku':'';
 final timePartEng = time.isNotEmpty ?'at $time':'';

 if (isTamil) {
 spokenSpeech ='மருத்துவ சந்திப்பு நேரம். $timePartSpoken $doctorName மருத்துவரைச் சந்திக்க வேண்டும்.';
 if (venue.isNotEmpty) {
 spokenSpeech ='$spokenSpeech இடம்: $venue.';
 }

 fallbackSpeech ='Maruthuva sandhippu neram. $timePartFallback $doctorName maruthuvarai sandhikka veendum.';
 if (venue.isNotEmpty) {
 fallbackSpeech ='$fallbackSpeech Idam: $venue.';
 }

 notifBody ='மருத்துவர்: $doctorName${time.isNotEmpty ?"• நேரம்: $time":""}${venue.isNotEmpty ?"• இடம்: $venue":""}';
 } else {
 spokenSpeech ='Medical appointment reminder. Time for appointment with $doctorName $timePartEng.';
 if (venue.isNotEmpty) {
 spokenSpeech ='$spokenSpeech Location: $venue.';
 }
 fallbackSpeech = spokenSpeech;
 notifBody ='Doctor: $doctorName${time.isNotEmpty ?"• Time: $time":""}${venue.isNotEmpty ?"• Venue: $venue":""}';
 }

 return {
'spokenSpeech': spokenSpeech,
'fallbackSpeech': fallbackSpeech,
'notifBody': notifBody,
 };
 }

 /// Builds clean, deduplicated speech strings and notification body for daily activities
 Map<String, String> buildRoutineSpeech({
 required String title,
 required String time,
 required String detail,
 required String langCode,
 I18nService? i18n,
 }) {
 String displayTitle = title
 .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]', unicode: true),'')
 .trim();

 final isTamil = langCode.toLowerCase() =='ta';

 var cleanDetail = detail
 .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]', unicode: true),'')
 .trim();
 if (cleanDetail =='Daily Routine Activity'|| cleanDetail =='Scheduled Item') {
 cleanDetail ='';
 }

 String spokenSpeech ='';
 String fallbackSpeech ='';
 String notifBody ='';

 final timePartSpoken = time.isNotEmpty ?'$time மணிக்கு':'';
 final timePartFallback = time.isNotEmpty ?'$time manikku':'';
 final timePartEng = time.isNotEmpty ?'at $time':'';

 if (isTamil) {
 spokenSpeech ='தினசரி நடவடிக்கை நினைவூட்டல். $timePartSpoken $displayTitle செய்ய வேண்டும்.';
 if (cleanDetail.isNotEmpty) {
 spokenSpeech ='$spokenSpeech $cleanDetail.';
 }

 fallbackSpeech ='Dinasari nadavadikkai ninaivootal. $timePartFallback $displayTitle seyya veendum.';
 if (cleanDetail.isNotEmpty) {
 fallbackSpeech ='$fallbackSpeech $cleanDetail.';
 }

 notifBody ='$displayTitle${time.isNotEmpty ?"• $time":""}${cleanDetail.isNotEmpty ?"• $cleanDetail":""}';
 } else {
 spokenSpeech ='Daily activity reminder. Time for $displayTitle $timePartEng.';
 if (cleanDetail.isNotEmpty) {
 spokenSpeech ='$spokenSpeech $cleanDetail.';
 }
 fallbackSpeech = spokenSpeech;
 notifBody ='$displayTitle${time.isNotEmpty ?"• $time":""}${cleanDetail.isNotEmpty ?"• $cleanDetail":""}';
 }

 return {
'spokenSpeech': spokenSpeech,
'fallbackSpeech': fallbackSpeech,
'notifBody': notifBody,
 };
 }

 /// Triggers specialized notification with interactive Taken / Yet to Take drag-down action buttons
 void triggerScheduleNotificationItem(ReminderItem item, {I18nService? i18n, bool force = false, int attemptCount = 1}) {
 if (attemptCount < 4) {
 if (isCaretakerMode) return;
 } else {
 if (!isCaretakerMode) return;
 }
 if (item.isCompleted) return;

 if (!force && item.id.isNotEmpty && !item.id.startsWith('temp_') && attemptCount == 1) {
 final now = DateTime.now();
 final currentMinuteKey ="${now.year}-${now.month}-${now.day}_${now.hour}:${now.minute}";
 if (_lastNotifiedMinutes[item.id] == currentMinuteKey) {
 debugPrint('Skipping duplicate notification trigger for ${item.title} in minute $currentMinuteKey');
 return;
 }
 _lastNotifiedMinutes[item.id] = currentMinuteKey;
 }

 final activeI1n = i18n ?? _i18n;
 final langCode = activeI1n?.currentLang ??'en';
 final isTamil = langCode.toLowerCase() =='ta';

 String notifTitle ='';
 String notifBody ='';
 String spokenSpeech ='';
 String englishFallbackSpeech ='';

 switch (item.type) {
 case ReminderType.medicine:
 notifTitle = activeI1n?.translate('medVoiceTitle') ??'Medicine Reminder';
 final pills = item.pillsCount.isEmpty ?'1': item.pillsCount;
 final res = buildMedicineSpeech(
 title: item.title,
 pillsCount: pills,
 instructions: item.instructions,
 langCode: langCode,
 i18n: activeI1n,
 );
 spokenSpeech = res['spokenSpeech']!;
 englishFallbackSpeech = res['fallbackSpeech']!;
 notifBody ='${item.title} ($pills pill(s)${item.instructions.isNotEmpty ?"• ${item.instructions}":""})';
 break;

 case ReminderType.appointment:
 notifTitle = activeI1n?.translate('apptVoiceTitle') ??'Doctor Appointment';
 final res = buildAppointmentSpeech(
 title: item.title,
 time: item.time,
 detail: item.detail,
 langCode: langCode,
 i18n: activeI1n,
 );
 spokenSpeech = res['spokenSpeech']!;
 englishFallbackSpeech = res['fallbackSpeech']!;
 notifBody = res['notifBody']!;
 break;

 case ReminderType.routine:
 notifTitle = activeI1n?.translate('actVoiceTitle') ??'Daily Activity';
 final res = buildRoutineSpeech(
 title: item.title,
 time: item.time,
 detail: item.detail,
 langCode: langCode,
 i18n: activeI1n,
 );
 spokenSpeech = res['spokenSpeech']!;
 englishFallbackSpeech = res['fallbackSpeech']!;
 notifBody = res['notifBody']!;
 break;

 case ReminderType.hydration:
 notifTitle = activeI1n?.translate('hourlyHydrationTitle') ??'Hydration Reminder';
 spokenSpeech = activeI1n?.translate('hourlyHydrationDesc') ??'Time to drink a glass of fresh water!';
 englishFallbackSpeech = isTamil
 ?'Hydration Reminder. Kudineer ninaivootal. Time to drink a glass of fresh water.'
 :'Hydration Reminder. Time to drink a glass of fresh water.';
 notifBody = spokenSpeech;
 break;
 }

 if (attemptCount == 2) {
 final tag = activeI1n?.translate('retry2Label') ??'(Reminder 2/3)';
 notifTitle ='$notifTitle $tag';
 } else if (attemptCount == 3) {
 final tag = activeI1n?.translate('retry3Label') ??'(Final Alert 3/3)';
 notifTitle ='$notifTitle $tag';
 } else if (attemptCount >= 4) {
 notifTitle ='Caregiver Alert: Elder Missed Reminder!';
 notifBody ='Elder has not taken/started"${item.title}"after 3 reminders. Please check on Elder.';
 spokenSpeech ='Caregiver Alert! Elder has not completed"${item.title}"after 3 reminders. Please check on Elder immediately.';
 englishFallbackSpeech = spokenSpeech;
 }

 _activeNotification = {
'id':'notif_${DateTime.now().millisecondsSinceEpoch}',
'reminderId': item.id,
'isRoutine': item.type == ReminderType.routine,
'title': notifTitle,
'body': notifBody,
'itemTitle': item.title,
'time': item.time,
'isHydration': item.type == ReminderType.hydration,
'isCaregiverAlert': attemptCount >= 4,
'timestamp': DateTime.now(),
 };

 final isRoutine = item.type == ReminderType.routine;
 final rawStarted = activeI1n?.translate('startedBtn');
 final String startedLabel = (rawStarted != null && rawStarted !='startedBtn'&& rawStarted.trim().isNotEmpty)
 ? rawStarted
 : (isTamil ?'தொடங்கப்பட்டது':'Started');

 final rawNotStarted = activeI1n?.translate('notStartedBtn');
 final String notStartedLabel = (rawNotStarted != null && rawNotStarted !='notStartedBtn'&& rawNotStarted.trim().isNotEmpty)
 ? rawNotStarted
 : (isTamil ?'தொடங்கவில்லை':'Not Started');

 final rawTaken = activeI1n?.translate('takenBtn');
 final String takenText = (rawTaken != null && rawTaken !='takenBtn'&& rawTaken.trim().isNotEmpty)
 ? rawTaken
 : (isTamil ?'எடுத்துக்கொண்டேன்':'Taken');

 final rawYetToTake = activeI1n?.translate('yetToTakeBtn');
 final String yetToTakeText = (rawYetToTake != null && rawYetToTake !='yetToTakeBtn'&& rawYetToTake.trim().isNotEmpty)
 ? rawYetToTake
 : (isTamil ?'எடுக்கவில்லை':'Yet to Take');

 final takenLabel = isRoutine ? startedLabel : takenText;
 final yetToTakeLabel = isRoutine ? notStartedLabel : yetToTakeText;

 NotificationService.showSystemNotification(
 title: notifTitle,
 body: notifBody,
 spokenText: spokenSpeech,
 fallbackEnglishText: englishFallbackSpeech,
 customVoicePath: item.customVoicePath,
 voiceMode: item.voiceMode,
 clonedVoiceSamplePath: item.clonedVoiceSamplePath,
 reminderId: item.id,
 takenLabel: takenLabel,
 yetToTakeLabel: yetToTakeLabel,
 langCode: langCode,
 isHydration: item.type == ReminderType.hydration,
 showActions: attemptCount < 4 && (item.type == ReminderType.medicine || item.type == ReminderType.routine),
 speak: attemptCount < 4,
 onAction: item.type == ReminderType.hydration ? () => logWaterGlass() : null,
 onTaken: () => markReminderTaken(item.id),
 onYetToTake: () => markReminderYetToTake(item.id),
 );

 if (attemptCount >= 4) {
 NotificationService.playEmergencyBeepAlarm();
 }

 // Schedule 1-minute follow-up retries (Attempt 2 & 3 for Elder, Attempt 4 for Caregiver)
 if (attemptCount < 4 && (item.type == ReminderType.medicine || item.type == ReminderType.routine)) {
 _followUpTimers[item.id]?.cancel();
 _followUpTimers[item.id] = Timer(const Duration(minutes: 1), () {
 final index = _reminders.indexWhere((r) => r.id == item.id);
 if (index != -1) {
 if (!_reminders[index].isCompleted) {
 debugPrint('Triggering 1-minute follow-up retry notification (Attempt ${attemptCount + 1}) for ${_reminders[index].title}');
 triggerScheduleNotificationItem(
 _reminders[index],
 i18n: activeI1n,
 force: true,
 attemptCount: attemptCount + 1,
 );
 }
 } else {
 if (!item.isCompleted) {
 debugPrint('Triggering 1-minute follow-up retry notification (Attempt ${attemptCount + 1}) for ${item.title}');
 triggerScheduleNotificationItem(
 item,
 i18n: activeI1n,
 force: true,
 attemptCount: attemptCount + 1,
 );
 }
 }
 });
 }

 notifyListeners();
 }

 void triggerScheduleNotification({
 required String title,
 required String time,
 required String typeLabelKey,
 I18nService? i18n,
 }) {
 final item = ReminderItem(
 id:'temp_${DateTime.now().millisecondsSinceEpoch}',
 type: ReminderType.medicine,
 title: title,
 time: time,
 detail:'Scheduled Item',
 );
 triggerScheduleNotificationItem(item, i18n: i18n);
 speakScheduledVoiceSuccess();
 }

 void dismissNotification() {
 _activeNotification = null;
 notifyListeners();
 }

 void setHydrationTargetLiters(double liters, {I18nService? i18n}) {
 if (i18n != null) _i18n = i18n;
 _hydrationTargetLiters = liters < 0 ? 0.0 : liters;
 if (_hydrationCurrentGlasses > hydrationTargetGlasses) {
 _hydrationCurrentGlasses = hydrationTargetGlasses;
 }
 _startHourlyHydrationTimer();
 saveSchedules();
 if (_hydrationTargetLiters > 0) {
 speakHydrationTargetSetVoice(_hydrationTargetLiters);
 }
 }

 void speakHydrationTargetSetVoice(double liters) {
 final activeI1n = _i18n;
 final langCode = activeI1n?.currentLang ??'en';
 final isTamil = langCode.toLowerCase() =='ta';

 final spokenMsg = isTamil
 ?'மணிநேர நீரேற்ற நினைவூட்டல் அமைக்கம் செய்யப்பட்டது. ஒவ்வொரு 1 மணிநேரமும் குடிநீர் நினைவூட்டல் ஒலிக்கும்.'
 :'Hourly hydration target set for ${liters.toStringAsFixed(1)} Liters. Notification voice alert active every hour!';

 final fallbackEn ='Hourly hydration target set for ${liters.toStringAsFixed(1)} Liters. Notification voice alert active every hour!';

 NotificationService.speakText(
 spokenMsg,
 lang: langCode,
 fallbackEnglishText: fallbackEn,
 );
 }

 void logWaterGlass() {
 if (hydrationTargetGlasses > 0 && _hydrationCurrentGlasses < hydrationTargetGlasses) {
 _hydrationCurrentGlasses++;
 if (_activeNotification != null && _activeNotification!['isHydration'] == true) {
 _activeNotification = null;
 }
 saveSchedules();
 speakWaterLoggedVoice();
 } else if (hydrationTargetGlasses > 0) {
 _hydrationCurrentGlasses = 0;
 saveSchedules();
 }
 }

 void speakWaterLoggedVoice() {
 final activeI1n = _i18n;
 final langCode = activeI1n?.currentLang ??'en';
 final isTamil = langCode.toLowerCase() =='ta';

 final spokenMsg = isTamil
 ?'நன்று! ஒரு டம்ளர் தண்ணீர் வெற்றிகரமாக பதிவுசெய்யப்பட்டது.'
 :'Great job! 1 glass of water logged. Stay hydrated and healthy!';

 final fallbackEn ='Great job! 1 glass of water logged. Stay hydrated and healthy!';

 NotificationService.speakText(
 spokenMsg,
 lang: langCode,
 fallbackEnglishText: fallbackEn,
 );
 }

 /// Speaks 1-line motivational voice in selected regional language when elder clicks Yes / Taken / Started
 void speakMotivationalSuccessVoice({
 String? customVoicePath,
 int voiceMode = 0,
 String? clonedVoiceSamplePath,
 bool isRoutine = false,
 }) {
 final langCode = _i18n?.currentLang ??'en';
 final key = isRoutine ?'motivationalRoutineStartedVoice':'motivationalTakenVoice';
 final defaultMsg = isRoutine
 ?'Great job! Completing your daily activity routine keeps you active and healthy!'
 :'Great job! Taking your medicine on time keeps you healthy and strong!';

 final spokenMsg = _i18n?.translate(key) ?? defaultMsg;
 final fallbackEn = defaultMsg;

 NotificationService.speakText(
 spokenMsg,
 lang: langCode,
 fallbackEnglishText: fallbackEn,
 customVoicePath:'',
 voiceMode: 0,
 clonedVoiceSamplePath:'',
 isResponseFeedback: true,
 );
 }

 /// Speaks 1-line gentle advice voice in selected regional language when elder clicks No / Yet to Take / Not Started
 void speakGentleAdviceVoice({
 String? customVoicePath,
 int voiceMode = 0,
 String? clonedVoiceSamplePath,
 bool isRoutine = false,
 }) {
 final langCode = _i18n?.currentLang ??'en';
 final key = isRoutine ?'adviceRoutineNotStartedVoice':'adviceYetToTakeVoice';
 final defaultMsg = isRoutine
 ?'Please complete your daily activity routine soon. Staying active is very important!'
 :'Please take your medicine soon. Your health and well-being are very important!';

 final spokenMsg = _i18n?.translate(key) ?? defaultMsg;
 final fallbackEn = defaultMsg;

 NotificationService.speakText(
 spokenMsg,
 lang: langCode,
 fallbackEnglishText: fallbackEn,
 customVoicePath:'',
 voiceMode: 0,
 clonedVoiceSamplePath:'',
 isResponseFeedback: true,
 );
 }

 /// Speaks voice feedback inside the app when a notification is successfully scheduled
 void speakScheduledVoiceSuccess({
 String? customVoicePath,
 int voiceMode = 0,
 String? clonedVoiceSamplePath,
 }) {
 final langCode = _i18n?.currentLang ??'en';
 final spokenMsg = _i18n?.translate('scheduleSuccessVoice') ??'Notification has been successfully scheduled!';
 final fallbackEn ='Notification has been successfully scheduled!';

 // Force TTS voice mode (0 or 2) so in-app schedule confirmation speaks"Notification has been successfully scheduled!"
 NotificationService.speakText(
 spokenMsg,
 lang: langCode,
 fallbackEnglishText: fallbackEn,
 voiceMode: voiceMode == 2 ? 2 : 0,
 clonedVoiceSamplePath: clonedVoiceSamplePath,
 );
 }

 /// Adds a medicine reminder with pill count and instructions for specialized voice readout
 void addMedicineReminder({
 required String medicineName,
 required String pillsCount,
 required String time,
 String instructions ='Take with water',
 String customVoicePath ='',
 int voiceMode = 0,
 String clonedVoiceSamplePath ='',
 String createdByRole ='caretaker',
 I18nService? i18n,
 }) {
 if (i18n != null) _i18n = i18n;
 final newId ='med_${DateTime.now().millisecondsSinceEpoch}';
 final detailText ='$pillsCount pill(s)${instructions.isNotEmpty ?"• $instructions":""}';
 final item = ReminderItem(
 id: newId,
 type: ReminderType.medicine,
 title: medicineName,
 time: time,
 detail: detailText,
 pillsCount: pillsCount,
 instructions: instructions,
 customVoicePath: customVoicePath,
 voiceMode: voiceMode,
 clonedVoiceSamplePath: clonedVoiceSamplePath,
 isCompleted: false,
 createdByRole: createdByRole,
 );
 _reminders.insert(0, item);
 _scheduleReminderTimer(item, i18n: i18n);
 saveSchedules();
 speakScheduledVoiceSuccess(customVoicePath: customVoicePath, voiceMode: voiceMode, clonedVoiceSamplePath: clonedVoiceSamplePath);
 }

 void addMedicineRoutine({
 required String medicineName,
 required String pillsCount,
 required String time,
 String customVoicePath ='',
 int voiceMode = 0,
 String clonedVoiceSamplePath ='',
 String createdByRole ='caretaker',
 I18nService? i18n,
 }) {
 addMedicineReminder(
 medicineName: medicineName,
 pillsCount: pillsCount,
 time: time,
 customVoicePath: customVoicePath,
 voiceMode: voiceMode,
 clonedVoiceSamplePath: clonedVoiceSamplePath,
 createdByRole: createdByRole,
 i18n: i18n,
 );
 }

 void addMedicalAppointment({
 required String title,
 required String dateTime,
 required String location,
 String customVoicePath ='',
 int voiceMode = 0,
 String clonedVoiceSamplePath ='',
 String createdByRole ='caretaker',
 I18nService? i18n,
 }) {
 if (i18n != null) _i18n = i18n;
 final newId ='apt_${DateTime.now().millisecondsSinceEpoch}';
 final item = ReminderItem(
 id: newId,
 type: ReminderType.appointment,
 title: title,
 time: dateTime,
 detail: location.isNotEmpty ? location :'Consultation Visit',
 customVoicePath:'',
 voiceMode: 0,
 clonedVoiceSamplePath:'',
 isCompleted: false,
 createdByRole: createdByRole,
 );
 _reminders.insert(0, item);
 _scheduleReminderTimer(item, i18n: i18n);
 saveSchedules();
 speakScheduledVoiceSuccess(customVoicePath:'', voiceMode: 0, clonedVoiceSamplePath:'');
 }

 void addDailyActivity({
 required String activityTitle,
 required String time,
 required String details,
 String customVoicePath ='',
 int voiceMode = 0,
 String clonedVoiceSamplePath ='',
 String createdByRole ='caretaker',
 I18nService? i18n,
 }) {
 if (i18n != null) _i18n = i18n;
 final newId ='act_${DateTime.now().millisecondsSinceEpoch}';
 final item = ReminderItem(
 id: newId,
 type: ReminderType.routine,
 title: activityTitle,
 time: time,
 detail: details.isNotEmpty ? details :'Daily Routine Activity',
 customVoicePath: customVoicePath,
 voiceMode: voiceMode,
 clonedVoiceSamplePath: clonedVoiceSamplePath,
 isCompleted: false,
 createdByRole: createdByRole,
 );
 _reminders.insert(0, item);
 _scheduleReminderTimer(item, i18n: i18n);
 saveSchedules();
 speakScheduledVoiceSuccess(customVoicePath: customVoicePath, voiceMode: voiceMode, clonedVoiceSamplePath: clonedVoiceSamplePath);
 }

 void toggleReminderCompletion(String id) {
 final index = _reminders.indexWhere((r) => r.id == id);
 if (index != -1) {
 final isNowCompleted = !_reminders[index].isCompleted;
 _reminders[index].isCompleted = isNowCompleted;
 saveSchedules();
 final isRoutine = _reminders[index].type == ReminderType.routine;
 if (isNowCompleted) {
 speakMotivationalSuccessVoice(
 customVoicePath: _reminders[index].customVoicePath,
 voiceMode: _reminders[index].voiceMode,
 clonedVoiceSamplePath: _reminders[index].clonedVoiceSamplePath,
 isRoutine: isRoutine,
 );
 } else {
 speakGentleAdviceVoice(
 customVoicePath: _reminders[index].customVoicePath,
 voiceMode: _reminders[index].voiceMode,
 clonedVoiceSamplePath: _reminders[index].clonedVoiceSamplePath,
 isRoutine: isRoutine,
 );
 }
 }
 }

 Future<void> deleteReminder(String id) async {
 _scheduledTimers[id]?.cancel();
 _scheduledTimers.remove(id);
 NotificationService.cancelAlarm(id.hashCode.abs() % 100000);
 _reminders.removeWhere((r) => r.id == id);
 await HiveService.deleteReminder(id);
 await saveSchedules();
 }

 void syncAllNativeAlarms() {
 if (isCaretakerMode) {
 cancelAllNativeAlarms();
 return;
 }
 final activeI1n = _i18n;
 final langCode = activeI1n?.currentLang ??'en';
 final isTamil = langCode.toLowerCase() =='ta';
 final takenLabel = activeI1n?.translate('takenBtn') ??'Taken';
 final yetToTakeLabel = activeI1n?.translate('yetToTakeBtn') ??'Yet to Take';

 for (final item in _reminders) {
 final alarmId = item.id.hashCode.abs() % 100000;
 if (item.isCompleted) {
 NotificationService.cancelAlarm(alarmId);
 continue;
 }

 final targetDate = parseScheduledTimeToDateTime(item.time);
 if (targetDate != null) {
 String notifTitle ='';
 String notifBody ='';
 String spokenSpeech ='';

 String fallbackSpeech ='';

 switch (item.type) {
 case ReminderType.medicine:
 notifTitle = activeI1n?.translate('medVoiceTitle') ??'Medicine Reminder';
 final pills = item.pillsCount.isEmpty ?'1': item.pillsCount;
 final res = buildMedicineSpeech(
 title: item.title,
 pillsCount: pills,
 instructions: item.instructions,
 langCode: langCode,
 i18n: activeI1n,
 );
 spokenSpeech = res['spokenSpeech']!;
 fallbackSpeech = res['fallbackSpeech']!;
 notifBody ='${item.title} ($pills pill(s)${item.instructions.isNotEmpty ?"• ${item.instructions}":""})';
 break;

 case ReminderType.appointment:
 notifTitle = activeI1n?.translate('apptVoiceTitle') ??'Doctor Appointment';
 final res = buildAppointmentSpeech(
 title: item.title,
 time: item.time,
 detail: item.detail,
 langCode: langCode,
 i18n: activeI1n,
 );
 spokenSpeech = res['spokenSpeech']!;
 fallbackSpeech = res['fallbackSpeech']!;
 notifBody = res['notifBody']!;
 break;

 case ReminderType.routine:
 notifTitle = activeI1n?.translate('actVoiceTitle') ??'Daily Activity';
 final res = buildRoutineSpeech(
 title: item.title,
 time: item.time,
 detail: item.detail,
 langCode: langCode,
 i18n: activeI1n,
 );
 spokenSpeech = res['spokenSpeech']!;
 fallbackSpeech = res['fallbackSpeech']!;
 notifBody = res['notifBody']!;
 break;

 case ReminderType.hydration:
 notifTitle = activeI1n?.translate('hourlyHydrationTitle') ??'Hydration Reminder';
 spokenSpeech = activeI1n?.translate('hourlyHydrationDesc') ??'Time to drink a glass of fresh water!';
 fallbackSpeech = spokenSpeech;
 notifBody = spokenSpeech;
 break;
 }

 final isRoutine = item.type == ReminderType.routine;
 final rawStarted = activeI1n?.translate('startedBtn');
 final String startedLabel = (rawStarted != null && rawStarted !='startedBtn'&& rawStarted.trim().isNotEmpty)
 ? rawStarted
 : (isTamil ?'தொடங்கப்பட்டது':'Started');

 final rawNotStarted = activeI1n?.translate('notStartedBtn');
 final String notStartedLabel = (rawNotStarted != null && rawNotStarted !='notStartedBtn'&& rawNotStarted.trim().isNotEmpty)
 ? rawNotStarted
 : (isTamil ?'தொடங்கவில்லை':'Not Started');

 final rawTaken = activeI1n?.translate('takenBtn');
 final String takenText = (rawTaken != null && rawTaken !='takenBtn'&& rawTaken.trim().isNotEmpty)
 ? rawTaken
 : (isTamil ?'எடுத்துக்கொண்டேன்':'Taken');

 final rawYetToTake = activeI1n?.translate('yetToTakeBtn');
 final String yetToTakeText = (rawYetToTake != null && rawYetToTake !='yetToTakeBtn'&& rawYetToTake.trim().isNotEmpty)
 ? rawYetToTake
 : (isTamil ?'எடுக்கவில்லை':'Yet to Take');

 final itemTakenLabel = isRoutine ? startedLabel : takenText;
 final itemYetToTakeLabel = isRoutine ? notStartedLabel : yetToTakeText;

 final isAppt = item.type == ReminderType.appointment;
 final effectiveCustomVoicePath = isAppt ?'': item.customVoicePath;
 final effectiveVoiceMode = isAppt ? 0 : item.voiceMode;
 final effectiveClonedVoiceSamplePath = isAppt ?'': item.clonedVoiceSamplePath;

 NotificationService.scheduleAlarm(
 id: alarmId,
 triggerAt: targetDate,
 title: notifTitle,
 body: notifBody,
 reminderId: item.id,
 takenLabel: itemTakenLabel,
 yetToTakeLabel: itemYetToTakeLabel,
 spokenText: spokenSpeech,
 fallbackText: fallbackSpeech,
 customVoicePath: effectiveCustomVoicePath,
 voiceMode: effectiveVoiceMode,
 clonedVoiceSamplePath: effectiveClonedVoiceSamplePath,
 langCode: langCode,
 isHydration: item.type == ReminderType.hydration,
 showActions: item.type == ReminderType.medicine || item.type == ReminderType.routine,
 );
 }
 }

 if (_hydrationTargetLiters > 0) {
 final hydTitle = activeI1n?.translate('hourlyHydrationTitle') ??'Hydration Reminder';
 final hydDesc = activeI1n?.translate('hourlyHydrationDesc') ??'Time to drink a glass of fresh water!';
 final fallbackEn = isTamil
 ?'Hydration Reminder. Kudineer ninaivootal. Thannir kudika vendum. Time to drink a glass of fresh water.'
 :'Hydration Reminder. Time to drink a glass of fresh water.';

 final logWaterBtnText = activeI1n?.translate('logWaterBtn') ??'1 Glass Water';

 NotificationService.scheduleAlarm(
 id: 999999,
 triggerAt: DateTime.now().add(const Duration(hours: 1)),
 title: hydTitle,
 body: hydDesc,
 reminderId:'hyd',
 takenLabel: logWaterBtnText,
 yetToTakeLabel: logWaterBtnText,
 spokenText:'$hydTitle. $hydDesc',
 fallbackText: fallbackEn,
 langCode: langCode,
 isHydration: true,
 showActions: true,
 );
 } else {
 NotificationService.cancelAlarm(999999);
 }
 }
}
