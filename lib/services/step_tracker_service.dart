import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_activity_record.dart';
import 'cloud_sync_service.dart';

enum StepTrackerSyncStatus {
  live,
  syncing,
  offline,
}

class StepTrackerService extends ChangeNotifier with WidgetsBindingObserver {
  static const MethodChannel _nativeChannel = MethodChannel('com.aninai/step_tracker');

  bool _isSensorAvailable = true;
  bool _hasPermission = false;
  bool _isTrackingActive = false;
  bool _isInitialized = false;

  DailyActivityRecord _todayRecord = DailyActivityRecord.empty(
    DateTime.now().toIso8601String().substring(0, 10),
  );
  List<DailyActivityRecord> _dailyHistory = [];

  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  String _activeElderId = '';
  bool _isCaregiverMode = false;
  StepTrackerSyncStatus _syncStatus = StepTrackerSyncStatus.live;

  int _lastPushedSteps = 0;
  Timer? _cloudDebounceTimer;
  int _lastAppliedTimestampMs = 0;

  Timer? _periodicSyncTimer;
  Timer? _pollingTimer;

  // Getters
  bool get isSensorAvailable => _isSensorAvailable;
  bool get hasPermission => _hasPermission;
  bool get isTrackingActive => _isTrackingActive;
  bool get isInitialized => _isInitialized;
  DailyActivityRecord get todayRecord => _todayRecord;
  List<DailyActivityRecord> get dailyHistory => List.unmodifiable(_dailyHistory);
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;
  String get activeElderId => _activeElderId;
  bool get isCaregiverMode => _isCaregiverMode;
  StepTrackerSyncStatus get syncStatus => _syncStatus;

  int get todaySteps => _todayRecord.steps;
  int get dailyGoal => _todayRecord.goal;
  double get distanceKm => _todayRecord.distanceKm;
  int get activeMinutes => _todayRecord.activeMinutes;
  int get calories => _todayRecord.calories;
  int get morningSteps => _todayRecord.morningSteps;
  int get afternoonSteps => _todayRecord.afternoonSteps;
  int get eveningSteps => _todayRecord.eveningSteps;
  double get progressRatio => _todayRecord.progressRatio;
  int get progressPercent => _todayRecord.progressPercent;
  bool get isGoalCompleted => _todayRecord.isGoalCompleted;

  StepTrackerService() {
    _loadLocalCache();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _setupNativeStepListener();
  }

  void _setupNativeStepListener() {
    _nativeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onStepCountChanged') {
        if (call.arguments is Map) {
          final map = Map<String, dynamic>.from(call.arguments as Map);
          _handleNativeStepCountChanged(map);
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isCaregiverMode && _activeElderId.isNotEmpty) {
        CloudSyncService().reconnectRealtimeActivity(_activeElderId);
        fetchCaregiverElderActivity(_activeElderId);
      } else if (!_isCaregiverMode && _activeElderId.isNotEmpty) {
        refreshElderToday();
      }
    }
  }

  Future<void> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final cachedTodayRaw = prefs.getString('cached_step_today_$todayStr');
      if (cachedTodayRaw != null) {
        final decoded = jsonDecode(cachedTodayRaw);
        if (decoded is Map<String, dynamic>) {
          _todayRecord = DailyActivityRecord.fromJson(decoded);
        }
      }

      final cachedHistoryRaw = prefs.getString('cached_step_history');
      if (cachedHistoryRaw != null) {
        final decoded = jsonDecode(cachedHistoryRaw);
        if (decoded is List) {
          _dailyHistory = decoded.map((e) => DailyActivityRecord.fromJson(Map<String, dynamic>.from(e))).toList();
          _dailyHistory.sort((a, b) => b.date.compareTo(a.date));
        }
      }

      final lastSyncMs = prefs.getInt('cached_step_last_sync');
      if (lastSyncMs != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cached steps: $e');
    }
  }

  /// Initialize on Elder Device
  Future<void> initForElder(String elderId) async {
    final cleanId = elderId.trim().toUpperCase();
    if (cleanId.isEmpty) return;

    _activeElderId = cleanId;
    _isCaregiverMode = false;

    await checkNativeStatus();

    if (_isSensorAvailable && _hasPermission) {
      await startTracking();
      await refreshElderToday();
    }

    // Periodic backup sync every 1 minute while app is running
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_activeElderId.isNotEmpty && !_isCaregiverMode) {
        if (_todayRecord.steps != _lastPushedSteps) {
          _pushToCloud();
        }
      }
    });

    // Native polling every 4 seconds as a reliable background fallback
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_isTrackingActive && !_isCaregiverMode) {
        _pollNativeTodaySteps();
      }
    });

    _isInitialized = true;
    notifyListeners();
  }

  void _handleNativeStepCountChanged(Map<String, dynamic> map) {
    final newSteps = (map['steps'] as num?)?.toInt() ?? 0;
    final oldSteps = _todayRecord.steps;

    _todayRecord = DailyActivityRecord.fromJson(map);
    notifyListeners();

    if (!_isCaregiverMode && _activeElderId.isNotEmpty) {
      final delta = (newSteps - _lastPushedSteps).abs();
      if (delta >= 10) {
        _scheduleDebouncedCloudSync(immediate: true);
      } else if (newSteps != oldSteps) {
        _scheduleDebouncedCloudSync(immediate: false);
      }
    }
  }

  void _scheduleDebouncedCloudSync({bool immediate = false}) {
    if (_isCaregiverMode || _activeElderId.isEmpty) return;

    if (immediate) {
      _cloudDebounceTimer?.cancel();
      _pushToCloud();
      return;
    }

    _cloudDebounceTimer?.cancel();
    _cloudDebounceTimer = Timer(const Duration(seconds: 3), () {
      if (_todayRecord.steps != _lastPushedSteps) {
        _pushToCloud();
      }
    });
  }

  /// Check hardware sensor availability and activity permission
  Future<void> checkNativeStatus() async {
    try {
      final bool? sensorAvail = await _nativeChannel.invokeMethod<bool>('isSensorAvailable');
      _isSensorAvailable = sensorAvail ?? false;

      final bool? perm = await _nativeChannel.invokeMethod<bool>('hasPermission');
      _hasPermission = perm ?? false;

      final bool? active = await _nativeChannel.invokeMethod<bool>('isTrackingActive');
      _isTrackingActive = active ?? false;

      notifyListeners();
    } catch (e) {
      debugPrint('Error checking native step status: $e');
      _isSensorAvailable = false;
    }
  }

  /// User-friendly permission request workflow
  Future<bool> requestActivityPermission() async {
    try {
      final bool? granted = await _nativeChannel.invokeMethod<bool>('requestPermission');
      _hasPermission = granted ?? false;
      notifyListeners();

      if (_hasPermission && _isSensorAvailable) {
        await startTracking();
        await refreshElderToday();
      }
      return _hasPermission;
    } catch (e) {
      debugPrint('Error requesting activity permission: $e');
      return false;
    }
  }

  /// Start background step tracking service
  Future<void> startTracking() async {
    try {
      await _nativeChannel.invokeMethod('startTracking');
      _isTrackingActive = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting step tracking: $e');
    }
  }

  /// Stop background step tracking service
  Future<void> stopTracking() async {
    try {
      await _nativeChannel.invokeMethod('stopTracking');
      _isTrackingActive = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping step tracking: $e');
    }
  }

  /// Quick poll from native SharedPreferences without heavy calculations
  Future<void> _pollNativeTodaySteps() async {
    try {
      final dynamic raw = await _nativeChannel.invokeMethod('getTodaySteps');
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final newSteps = (map['steps'] as num?)?.toInt() ?? 0;
        if (newSteps != _todayRecord.steps) {
          _handleNativeStepCountChanged(map);
        }
      }
    } catch (_) {}
  }

  /// Refresh Elder Today step data from native manager and push to Cloud
  Future<void> refreshElderToday() async {
    if (_activeElderId.isEmpty) return;

    try {
      _isSyncing = true;
      notifyListeners();

      final dynamic rawToday = await _nativeChannel.invokeMethod('refreshToday');
      if (rawToday is Map) {
        _todayRecord = DailyActivityRecord.fromJson(Map<String, dynamic>.from(rawToday));
      }

      final dynamic rawHistory = await _nativeChannel.invokeMethod('getStepHistory');
      if (rawHistory is Map) {
        final list = <DailyActivityRecord>[];
        rawHistory.forEach((k, v) {
          if (v is Map) {
            list.add(DailyActivityRecord.fromJson(Map<String, dynamic>.from(v)));
          }
        });
        list.sort((a, b) => b.date.compareTo(a.date));
        _dailyHistory = list;
      }

      await _cacheLocally();
      await _pushToCloud();
    } catch (e) {
      debugPrint('Error refreshing elder step data: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Change daily step target goal
  Future<void> setDailyGoal(int newGoal) async {
    if (newGoal <= 0) return;
    try {
      await _nativeChannel.invokeMethod('setDailyGoal', {'goal': newGoal});
      _todayRecord = _todayRecord.copyWith(goal: newGoal);
      notifyListeners();
      await _pushToCloud();
      await _cacheLocally();
    } catch (e) {
      debugPrint('Error setting daily goal: $e');
    }
  }

  Future<void> _cacheLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_step_today_${_todayRecord.date}', jsonEncode(_todayRecord.toJson()));
      await prefs.setString('cached_step_history', jsonEncode(_dailyHistory.map((e) => e.toJson()).toList()));
      if (_lastSyncTime != null) {
        await prefs.setInt('cached_step_last_sync', _lastSyncTime!.millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('Error caching step data: $e');
    }
  }

  Future<void> _pushToCloud() async {
    if (_activeElderId.isEmpty) return;

    try {
      final historyMap = <String, dynamic>{};
      for (final r in _dailyHistory) {
        historyMap[r.date] = r.toJson();
      }

      final payload = {
        'today': _todayRecord.toJson(),
        'history': historyMap,
        'averages': {
          'sevenDay': calculateSevenDayAverage(),
          'thirtyDay': calculateThirtyDayAverage(),
          'overall': calculateOverallAverage(),
        },
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'updatedTimestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final success = await CloudSyncService().pushElderActivityCloud(_activeElderId, payload);
      if (success) {
        _lastPushedSteps = _todayRecord.steps;
        _lastSyncTime = DateTime.now();
        _syncStatus = StepTrackerSyncStatus.live;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('cached_step_last_sync', _lastSyncTime!.millisecondsSinceEpoch);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error pushing activity to cloud: $e');
    }
  }

  // ==========================================
  // CAREGIVER SECTION LOGIC
  // ==========================================

  /// Initialize for Caregiver to monitor connected elder's activity
  Future<void> initForCaregiver(String elderId) async {
    final cleanId = elderId.trim().toUpperCase();
    if (cleanId.isEmpty) return;

    _activeElderId = cleanId;
    _isCaregiverMode = true;

    // Load cached data first for instant UI display
    await _loadLocalCacheForCaregiver(cleanId);

    // Initial fresh fetch from backend
    await fetchCaregiverElderActivity(cleanId);

    // Subscribe to real-time auto-reconnecting SSE stream from Cloud Relay
    CloudSyncService().startRealtimeActivityListener(cleanId, (payload) {
      _applyCloudPayload(payload);
    });

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadLocalCacheForCaregiver(String elderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localRaw = prefs.getString('cloud_activity_$elderId');
      if (localRaw != null && localRaw.isNotEmpty) {
        final decoded = jsonDecode(localRaw);
        if (decoded is Map<String, dynamic>) {
          _applyCloudPayload(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {}
  }

  /// Fetch elder's activity from Cloud Relay (Manual Refresh or Initial Load)
  Future<void> fetchCaregiverElderActivity(String elderId) async {
    final cleanId = elderId.trim().toUpperCase();
    if (cleanId.isEmpty) return;

    // Concurrency guard: ignore duplicate taps while sync is running
    if (_isSyncing) {
      debugPrint('Caregiver sync already in progress, skipping duplicate request');
      return;
    }

    try {
      _isSyncing = true;
      _syncStatus = StepTrackerSyncStatus.syncing;
      notifyListeners();

      final data = await CloudSyncService().pullElderActivityCloud(cleanId, forceFresh: true);
      if (data != null) {
        _applyCloudPayload(data);
        if (data['_isFromNetwork'] == true) {
          _lastSyncTime = DateTime.now();
          _syncStatus = StepTrackerSyncStatus.live;
        }
      } else {
        // Network error or unreachable
        _syncStatus = StepTrackerSyncStatus.offline;
      }
    } catch (e) {
      debugPrint('fetchCaregiverElderActivity error: $e');
      _syncStatus = StepTrackerSyncStatus.offline;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _applyCloudPayload(Map<String, dynamic> data) {
    try {
      final act = (data['activity'] is Map<String, dynamic>)
          ? data['activity'] as Map<String, dynamic>
          : data;

      // Extract incoming timestamp for stale-data comparison
      int? incomingEpochMs;
      final rawTs = data['updatedTimestamp'] ?? act['updatedTimestamp'] ?? (act['today'] is Map ? act['today']['updatedTimestamp'] : null);
      if (rawTs is num) {
        incomingEpochMs = rawTs.toInt();
      } else {
        final rawUpdatedAt = data['updatedAt'] ?? act['updatedAt'] ?? (act['today'] is Map ? act['today']['updatedAt'] : null);
        if (rawUpdatedAt is String) {
          incomingEpochMs = DateTime.tryParse(rawUpdatedAt)?.millisecondsSinceEpoch;
        }
      }

      int incomingSteps = 0;
      String incomingDate = '';
      if (act['today'] is Map) {
        incomingSteps = (act['today']['steps'] as num?)?.toInt() ?? 0;
        incomingDate = act['today']['date']?.toString() ?? '';
      } else if (act.containsKey('steps')) {
        incomingSteps = (act['steps'] as num?)?.toInt() ?? 0;
        incomingDate = act['date']?.toString() ?? '';
      }

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      if (incomingDate.isEmpty) incomingDate = todayStr;

      // STALE DATA PROTECTION (Section 5 of Requirements):
      // If we already applied newer data (higher epoch timestamp), reject older data!
      if (incomingEpochMs != null && incomingEpochMs > 0 && _lastAppliedTimestampMs > 0) {
        if (incomingEpochMs < _lastAppliedTimestampMs) {
          debugPrint('STALE DATA GUARD: Discarding older payload (incoming: $incomingEpochMs < current: $_lastAppliedTimestampMs)');
          return;
        }
      }

      // If on the same calendar day, steps cannot go backwards due to an old cache response
      if (incomingDate == _todayRecord.date && incomingSteps < _todayRecord.steps && incomingEpochMs != null && incomingEpochMs <= _lastAppliedTimestampMs) {
        debugPrint('STALE DATA GUARD: Discarding backwards step count ($incomingSteps < ${_todayRecord.steps})');
        return;
      }

      // Apply the new data
      if (act['today'] is Map) {
        _todayRecord = DailyActivityRecord.fromJson(Map<String, dynamic>.from(act['today']));
      } else if (act.containsKey('steps')) {
        _todayRecord = DailyActivityRecord.fromJson(act);
      }

      if (act['history'] is Map) {
        final histMap = act['history'] as Map;
        final list = <DailyActivityRecord>[];
        histMap.forEach((k, v) {
          if (v is Map) {
            list.add(DailyActivityRecord.fromJson(Map<String, dynamic>.from(v)));
          }
        });
        list.sort((a, b) => b.date.compareTo(a.date));
        _dailyHistory = list;
      }

      if (incomingEpochMs != null && incomingEpochMs > 0) {
        _lastAppliedTimestampMs = incomingEpochMs;
      } else {
        _lastAppliedTimestampMs = DateTime.now().millisecondsSinceEpoch;
      }

      if (data['_isFromNetwork'] == true) {
        _lastSyncTime = DateTime.now();
        _syncStatus = StepTrackerSyncStatus.live;
      }

      _cacheLocally();
      notifyListeners();
    } catch (e) {
      debugPrint('Error applying cloud activity payload: $e');
    }
  }

  // ==========================================
  // ANALYTICS & STATS CALCULATIONS
  // ==========================================

  /// Calculate 7-day average of past recorded days
  int calculateSevenDayAverage() {
    final validHistory = _dailyHistory.where((d) => d.date != _todayRecord.date).take(7).toList();
    if (validHistory.isEmpty) {
      return _todayRecord.steps;
    }
    final total = validHistory.fold<int>(0, (sum, item) => sum + item.steps);
    return (total / validHistory.length).round();
  }

  /// Calculate 30-day average of past recorded days
  int calculateThirtyDayAverage() {
    final validHistory = _dailyHistory.where((d) => d.date != _todayRecord.date).take(30).toList();
    if (validHistory.isEmpty) {
      return _todayRecord.steps;
    }
    final total = validHistory.fold<int>(0, (sum, item) => sum + item.steps);
    return (total / validHistory.length).round();
  }

  /// Calculate overall daily average across all history
  int calculateOverallAverage() {
    final allDays = <DailyActivityRecord>[
      _todayRecord,
      ..._dailyHistory.where((d) => d.date != _todayRecord.date),
    ].where((d) => d.steps > 0).toList();

    if (allDays.isEmpty) return 0;
    final total = allDays.fold<int>(0, (sum, item) => sum + item.steps);
    return (total / allDays.length).round();
  }

  /// Weekly summary for Monday - Sunday bar chart
  Map<String, dynamic> getWeeklySummary() {
    final now = DateTime.now();
    // Monday is weekday 1, Sunday is 7
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final Map<int, DailyActivityRecord?> daysMap = {};
    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dateStr = dayDate.toIso8601String().substring(0, 10);

      DailyActivityRecord? match;
      if (dateStr == _todayRecord.date) {
        match = _todayRecord;
      } else {
        match = _dailyHistory.cast<DailyActivityRecord?>().firstWhere(
              (r) => r?.date == dateStr,
              orElse: () => null,
            );
      }
      daysMap[i] = match;
    }

    int totalWeekly = 0;
    int highestSteps = 0;
    String highestDay = '';
    int lowestSteps = 9999999;
    String lowestDay = '';
    int daysWithData = 0;

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      final rec = daysMap[i];
      final st = rec?.steps ?? 0;
      totalWeekly += st;

      if (rec != null) {
        daysWithData++;
        if (st >= highestSteps) {
          highestSteps = st;
          highestDay = dayLabels[i];
        }
        if (st <= lowestSteps) {
          lowestSteps = st;
          lowestDay = dayLabels[i];
        }
      }
    }

    if (lowestSteps == 9999999) lowestSteps = 0;
    final dailyAvg = daysWithData > 0 ? (totalWeekly / daysWithData).round() : 0;

    return {
      'daysMap': daysMap,
      'totalWeekly': totalWeekly,
      'dailyAvg': dailyAvg,
      'highestDay': highestDay.isNotEmpty ? highestDay : 'N/A',
      'highestSteps': highestSteps,
      'lowestDay': lowestDay.isNotEmpty ? lowestDay : 'N/A',
      'lowestSteps': lowestSteps,
    };
  }

  /// Monthly statistics
  Map<String, dynamic> getMonthlySummary() {
    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final monthRecords = <DailyActivityRecord>[
      if (_todayRecord.date.startsWith(monthPrefix)) _todayRecord,
      ..._dailyHistory.where((d) => d.date.startsWith(monthPrefix) && d.date != _todayRecord.date),
    ];

    int totalSteps = 0;
    int bestDaySteps = 0;
    String bestDayDate = '';
    int activeDays = 0;

    for (final r in monthRecords) {
      totalSteps += r.steps;
      if (r.steps > 0) activeDays++;
      if (r.steps > bestDaySteps) {
        bestDaySteps = r.steps;
        bestDayDate = r.date;
      }
    }

    final dailyAvg = activeDays > 0 ? (totalSteps / activeDays).round() : 0;

    return {
      'totalSteps': totalSteps,
      'dailyAvg': dailyAvg,
      'activeDays': activeDays,
      'bestDayDate': bestDayDate,
      'bestDaySteps': bestDaySteps,
    };
  }

  String formatLastUpdatedString() {
    if (_syncStatus == StepTrackerSyncStatus.syncing) {
      return 'Syncing...';
    }
    if (_lastSyncTime == null) return 'Not synchronized yet';
    final now = DateTime.now();
    final diff = now.difference(_lastSyncTime!);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? "min" : "mins"} ago';
    } else if (diff.inHours < 24) {
      final hour = _lastSyncTime!.hour > 12
          ? _lastSyncTime!.hour - 12
          : (_lastSyncTime!.hour == 0 ? 12 : _lastSyncTime!.hour);
      final minute = _lastSyncTime!.minute.toString().padLeft(2, '0');
      final period = _lastSyncTime!.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:$minute $period';
    } else {
      return '${_lastSyncTime!.day}/${_lastSyncTime!.month}/${_lastSyncTime!.year}';
    }
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _cloudDebounceTimer?.cancel();
    _periodicSyncTimer?.cancel();
    _pollingTimer?.cancel();
    CloudSyncService().stopRealtimeActivityListener();
    super.dispose();
  }
}
