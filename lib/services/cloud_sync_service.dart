import'dart:async';
import'dart:convert';
import'dart:io';
import'package:flutter/foundation.dart';
import'package:shared_preferences/shared_preferences.dart';
import'../models/reminder.dart';
import'../models/memory_item.dart';

class CloudSyncService extends ChangeNotifier {
 static final CloudSyncService _instance = CloudSyncService._internal();
 factory CloudSyncService() => _instance;
 CloudSyncService._internal();

 // Firebase Realtime Database REST Endpoints with exact verified path structure
 static const List<String> _firebaseEndpoints = [
'https://purb-chetana-default-rtdb.firebaseio.com',
 ];

 static const List<String> _kvEndpoints = [
'https://kvdb.io/AninaiApp2026KeyValStore',
 ];

 final HttpClient _client = HttpClient()
 ..connectionTimeout = const Duration(seconds: 4);

 final HttpClient _mediaClient = HttpClient()
 ..connectionTimeout = const Duration(seconds: 60);

 final Map<String, Map<String, dynamic>> _inMemoryCache = {};

 bool _isSyncing = false;
 String _syncStatus ='Idle';
 DateTime? _lastSyncTime;

 bool get isSyncing => _isSyncing;
 String get syncStatus => _syncStatus;
 DateTime? get lastSyncTime => _lastSyncTime;

 /// Clean & format Elder ID (e.g.,'NER-4821')
 String cleanId(String rawId) {
 return rawId.trim().toUpperCase();
 }

 /// Register Elder Profile to Cloud Relay & Local Storage
 Future<bool> registerElderProfileCloud(String elderId, Map<String, dynamic> profile) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return false;

 try {
 _isSyncing = true;
 _syncStatus ='Registering Elder ID $targetId...';
 notifyListeners();

 final payloadMap = {
'elderId': targetId,
'profile': profile,
'registeredAt': DateTime.now().toIso8601String(),
'updatedAt': DateTime.now().toIso8601String(),
'timestamp': DateTime.now().millisecondsSinceEpoch,
 };

 _inMemoryCache['profile_$targetId'] = payloadMap;
 final prefs = await SharedPreferences.getInstance();
 final payload = jsonEncode(payloadMap);
 await prefs.setString('cloud_profile_$targetId', payload);

 // 1. Push to Firebase REST API (/profiles/NER-XXXX.json)
 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/profiles/$targetId.json');
 final request = await _client.putUrl(url);
 request.headers.contentType = ContentType.json;
 request.write(payload);
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();
 debugPrint('CLOUD PROFILE PUSH Firebase: URL=$url Status=${response.statusCode} Body=$body');
 } catch (e) {
 debugPrint('CLOUD PROFILE PUSH Error ($fb): $e');
 }
 }

 // 2. Push to KV Relay
 for (final kv in _kvEndpoints) {
 try {
 final url = Uri.parse('$kv/profile_$targetId');
 final request = await _client.putUrl(url);
 request.headers.contentType = ContentType.json;
 request.write(payload);
 final response = await request.close();
 await response.drain();
 } catch (_) {}
 }

 _syncStatus ='Elder ID $targetId Registered';
 _lastSyncTime = DateTime.now();
 return true;
 } catch (e) {
 debugPrint('CloudSync register profile error: $e');
 _syncStatus ='Registered locally';
 return true;
 } finally {
 _isSyncing = false;
 notifyListeners();
 }
 }

 /// Verify Elder ID existence & retrieve profile details from Cloud Relay
 Future<Map<String, dynamic>?> verifyElderIdCloud(String elderId) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return null;

 try {
 _isSyncing = true;
 _syncStatus ='Verifying Elder ID $targetId...';
 notifyListeners();

 final prefs = await SharedPreferences.getInstance();

 // 1. Query Firebase RTDB REST GET (/profiles/NER-XXXX.json)
 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/profiles/$targetId.json');
 final request = await _client.getUrl(url);
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();
 debugPrint('CLOUD VERIFY Firebase: URL=$url Status=${response.statusCode} Body=$body');

 if (response.statusCode == 200 && body.isNotEmpty && body !='null') {
 final decoded = jsonDecode(body) as Map<String, dynamic>;
 await prefs.setString('cloud_profile_$targetId', body);
 _syncStatus ='Elder ID $targetId Verified';
 _lastSyncTime = DateTime.now();
 return decoded['profile'] as Map<String, dynamic>? ?? decoded;
 }
 } catch (e) {
 debugPrint('CLOUD VERIFY Firebase Error ($fb): $e');
 }
 }

 // 2. Local fallback
 final localRaw = prefs.getString('cloud_profile_$targetId');
 if (localRaw != null && localRaw.isNotEmpty) {
 final decoded = jsonDecode(localRaw) as Map<String, dynamic>;
 _syncStatus ='Elder ID $targetId Verified';
 _lastSyncTime = DateTime.now();
 return decoded['profile'] as Map<String, dynamic>? ?? decoded;
 }
 } catch (e) {
 debugPrint('CloudSync verify error: $e');
 } finally {
 _isSyncing = false;
 notifyListeners();
 }
 return null;
 }

 /// Push updated schedule list & hydration targets to Cloud Relay for an Elder ID
 Future<bool> pushScheduleCloud(
 String elderId,
 List<ReminderItem> reminders,
 double hydrationTargetLiters,
 int hydrationCurrentGlasses,
 ) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return false;

 try {
 _isSyncing = true;
 _syncStatus ='Syncing schedules to Cloud ($targetId)...';
 notifyListeners();

 final List<Map<String, dynamic>> remindersJson = [];
 for (final r in reminders) {
 final rMap = r.toJson();

 // 1. Encode custom voice note audio file if local file
 if (r.customVoicePath.isNotEmpty) {
 final cleanPath = r.customVoicePath.replaceAll('file://','');
 final file = File(cleanPath);
 if (file.existsSync() && file.lengthSync() > 0) {
 try {
 final bytes = await file.readAsBytes();
 rMap['customVoiceBase64'] = base64Encode(bytes);
 } catch (e) {
 debugPrint('Error reading reminder custom voice bytes: $e');
 }
 }
 }

 // 2. Encode cloned voice sample audio file if local file
 if (r.clonedVoiceSamplePath.isNotEmpty) {
 final cleanPath = r.clonedVoiceSamplePath.replaceAll('file://','');
 final file = File(cleanPath);
 if (file.existsSync() && file.lengthSync() > 0) {
 try {
 final bytes = await file.readAsBytes();
 rMap['clonedVoiceBase64'] = base64Encode(bytes);
 } catch (e) {
 debugPrint('Error reading cloned voice sample bytes: $e');
 }
 }
 }

 remindersJson.add(rMap);
 }

 final payloadMap = {
'elderId': targetId,
'hydrationTargetLiters': hydrationTargetLiters,
'hydrationCurrentGlasses': hydrationCurrentGlasses,
'reminders': remindersJson,
'updatedAt': DateTime.now().toIso8601String(),
'updatedTimestamp': DateTime.now().millisecondsSinceEpoch,
 };

 _inMemoryCache['schedules_$targetId'] = payloadMap;
 final prefs = await SharedPreferences.getInstance();
 final payload = jsonEncode(payloadMap);
 await prefs.setString('cloud_schedules_$targetId', payload);

 debugPrint('CLOUD PUSH: Elder ID = $targetId, Count = ${reminders.length}');

 bool anySuccess = false;

 // 1. Firebase RTDB REST PUT (/schedules/NER-XXXX.json)
 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/schedules/$targetId.json');
 final request = await _client.putUrl(url);
 request.headers.contentType = ContentType.json;
 request.write(payload);
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();
 debugPrint('CLOUD PUSH Firebase: URL=$url Status=${response.statusCode} Body=$body');
 if (response.statusCode == 200) {
 anySuccess = true;
 }
 } catch (e) {
 debugPrint('CLOUD PUSH Firebase Error ($fb): $e');
 }
 }

 // 2. KV Endpoints PUT
 for (final kv in _kvEndpoints) {
 try {
 final url = Uri.parse('$kv/schedules_$targetId');
 final request = await _client.putUrl(url);
 request.headers.contentType = ContentType.json;
 request.write(payload);
 final response = await request.close();
 await response.drain();
 debugPrint('CLOUD PUSH KV: URL=$url Status=${response.statusCode}');
 if (response.statusCode == 200) {
 anySuccess = true;
 }
 } catch (e) {
 debugPrint('CLOUD PUSH KV Error ($kv): $e');
 }
 }

 _syncStatus = anySuccess ?'Schedules Synced to Cloud (${reminders.length} items)':'Synced Locally';
 _lastSyncTime = DateTime.now();
 return true;
 } catch (e) {
 debugPrint('CloudSync push schedule error: $e');
 _syncStatus ='Synced (Local Relay Active)';
 return true;
 } finally {
 _isSyncing = false;
 notifyListeners();
 }
 }

 /// Test whether device DNS can resolve Firebase hostname
 Future<bool> testFirebaseConnection() async {
 bool anyResolved = false;
 for (final endpoint in _firebaseEndpoints) {
 try {
 final host = Uri.parse(endpoint).host;
 final result = await InternetAddress.lookup(host);
 debugPrint('DNS RESULT ($host): $result');
 if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
 anyResolved = true;
 }
 } catch (e) {
 debugPrint('DNS FAILED ($endpoint): $e');
 }
 }
 return anyResolved;
 }

 /// Detailed Pull Response for 3-state cloud synchronization
 Future<CloudPullResponse> pullScheduleCloudDetailed(String elderId) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return CloudPullResponse(CloudSyncStatus.notFound);

 debugPrint('CLOUD PULL: Elder ID = $targetId');

 final prefs = await SharedPreferences.getInstance();
 bool encounteredNetworkError = false;

 // 1. Fetch from Firebase RTDB REST GET (/schedules/NER-XXXX.json) FIRST
 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/schedules/$targetId.json');
 final request = await _client.getUrl(url);
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();

 if (response.statusCode == 200 && body.trim().isNotEmpty && body !='null') {
 final decoded = jsonDecode(body);

 if (decoded is Map<String, dynamic> && decoded['reminders'] is List) {
 await prefs.setString(
'cloud_schedules_$targetId',
 body,
 );

 debugPrint('CLOUD PULL: status=200 (Cloud data found for $targetId)');
 _syncStatus ='Cloud Schedules Fetched';
 _lastSyncTime = DateTime.now();
 return CloudPullResponse(CloudSyncStatus.found, decoded);
 }
 } else if (response.statusCode == 401 || body.contains('Permission denied')) {
 debugPrint('CLOUD PULL: status=401 (Firebase Rules: Permission denied. Please set .read: true, .write: true in Firebase Console)');
 encounteredNetworkError = true;
 } else if (response.statusCode == 404 || body.trim() =='null'|| body.contains('404 Not Found')) {
 debugPrint('CLOUD PULL: status=404 (No cloud schedule created yet for Elder ID $targetId)');
 } else {
 debugPrint('CLOUD PULL: status=${response.statusCode}, body=$body');
 }
 } catch (e) {
 debugPrint('CLOUD PULL Firebase Error ($fb): $e');
 if (e is SocketException || e.toString().contains('SocketException')) {
 encounteredNetworkError = true;
 }
 }
 }

 // 2. Fetch from KV Endpoints GET
 for (final kv in _kvEndpoints) {
 try {
 final url = Uri.parse('$kv/schedules_$targetId');
 final request = await _client.getUrl(url);
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();

 debugPrint(
'CLOUD PULL KV: status=${response.statusCode}, body=$body',
 );

 if (response.statusCode == 200 && body.trim().isNotEmpty && body !='null') {
 final decoded = jsonDecode(body);

 if (decoded is Map<String, dynamic> && decoded['reminders'] is List) {
 await prefs.setString(
'cloud_schedules_$targetId',
 body,
 );

 _syncStatus ='Cloud Schedules Fetched';
 _lastSyncTime = DateTime.now();
 return CloudPullResponse(CloudSyncStatus.found, decoded);
 }
 }
 } catch (e) {
 debugPrint('CLOUD PULL KV Error ($kv): $e');
 if (e is SocketException || e.toString().contains('SocketException')) {
 encounteredNetworkError = true;
 }
 }
 }

 // 3. If a network socket exception occurred on all endpoints, report network error state
 if (encounteredNetworkError) {
 final localRaw = prefs.getString('cloud_schedules_$targetId');
 if (localRaw != null && localRaw.isNotEmpty) {
 try {
 final decoded = jsonDecode(localRaw);
 if (decoded is Map<String, dynamic> && decoded['reminders'] is List) {
 debugPrint('CLOUD PULL: Using local offline cache due to network error');
 return CloudPullResponse(CloudSyncStatus.found, decoded);
 }
 } catch (_) {}
 }
 return CloudPullResponse(CloudSyncStatus.networkError);
 }

 return CloudPullResponse(CloudSyncStatus.notFound);
 }

 StreamSubscription? _sseSubscription;
 String _activeSseElderId ='';

 /// Subscribes to real-time Server-Sent Events (SSE) from Firebase RTDB for sub-second sync across devices
 void startRealtimeScheduleListener(String elderId, Function(Map<String, dynamic>) onDataReceived) {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty || targetId == _activeSseElderId) return;

 _activeSseElderId = targetId;
 try {
 _sseSubscription?.cancel();
 } catch (_) {}

 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/schedules/$targetId.json');
 HttpClient().getUrl(url).then((req) {
 req.headers.add('Accept','text/event-stream');
 return req.close();
 }).then((response) {
 if (response.statusCode == 200) {
 debugPrint('REALTIME SSE STREAM ESTABLISHED for $targetId');
 _sseSubscription = response
 .transform(utf8.decoder)
 .transform(const LineSplitter())
 .listen((line) {
 if (line.startsWith('data:')) {
 final jsonStr = line.substring(6).trim();
 if (jsonStr.isNotEmpty && jsonStr !='null') {
 try {
 final decoded = jsonDecode(jsonStr);
 if (decoded is Map<String, dynamic>) {
 final payload = (decoded['data'] is Map<String, dynamic>)
 ? Map<String, dynamic>.from(decoded['data'])
 : decoded;
 if (payload['reminders'] is List) {
 onDataReceived(payload);
 }
 }
 } catch (e) {
 debugPrint('SSE JSON Parse Error: $e');
 }
 }
 }
 }, onError: (e) {
 debugPrint('SSE Stream Error: $e');
 _activeSseElderId ='';
 }, onDone: () {
 _activeSseElderId ='';
 });
 }
 }).catchError((e) {
 debugPrint('SSE Connection Error: $e');
 _activeSseElderId ='';
 });
 } catch (_) {}
 }
 }

 void stopRealtimeScheduleListener() {
 try {
 _sseSubscription?.cancel();
 } catch (_) {}
 _sseSubscription = null;
 _activeSseElderId ='';
 }

 StreamSubscription? _sseMemoriesSubscription;
 String _activeSseMemoriesElderId ='';

 /// Subscribes to real-time Server-Sent Events (SSE) for memories from Firebase RTDB
 void startRealtimeMemoriesListener(String elderId, Function(Map<String, dynamic>) onDataReceived) {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty || targetId == _activeSseMemoriesElderId) return;

 _activeSseMemoriesElderId = targetId;
 try {
 _sseMemoriesSubscription?.cancel();
 } catch (_) {}

 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/memories/$targetId.json');
 HttpClient().getUrl(url).then((req) {
 req.headers.add('Accept','text/event-stream');
 return req.close();
 }).then((response) {
 if (response.statusCode == 200) {
 debugPrint('REALTIME MEMORIES SSE STREAM ESTABLISHED for $targetId');
 _sseMemoriesSubscription = response
 .transform(utf8.decoder)
 .transform(const LineSplitter())
 .listen((line) {
 if (line.startsWith('data:')) {
 final jsonStr = line.substring(6).trim();
 if (jsonStr.isNotEmpty && jsonStr !='null') {
 try {
 final decoded = jsonDecode(jsonStr);
 if (decoded is Map<String, dynamic>) {
 final payload = (decoded['data'] is Map<String, dynamic>)
 ? Map<String, dynamic>.from(decoded['data'])
 : decoded;
 if (payload['memories'] is List) {
 onDataReceived(payload);
 }
 }
 } catch (e) {
 debugPrint('SSE Memories JSON Parse Error: $e');
 }
 }
 }
 }, onError: (e) {
 debugPrint('SSE Memories Stream Error: $e');
 _activeSseMemoriesElderId ='';
 }, onDone: () {
 _activeSseMemoriesElderId ='';
 });
 }
 }).catchError((e) {
 debugPrint('SSE Memories Connection Error: $e');
 _activeSseMemoriesElderId ='';
 });
 } catch (_) {}
 }
 }

 void stopRealtimeMemoriesListener() {
 try {
 _sseMemoriesSubscription?.cancel();
 } catch (_) {}
 _sseMemoriesSubscription = null;
 _activeSseMemoriesElderId ='';
 }

 /// Push memories list to Cloud Relay (/memories/NER-XXXX.json)
 Future<bool> pushMemoriesCloud(String elderId, List<MemoryItem> memories) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return false;

 try {
 final List<Map<String, dynamic>> memoriesJson = [];
 for (final m in memories) {
 final map = m.toJson();

 // 1. Voice Note Audio File Base64
 if (m.voiceNotePath != null && m.voiceNotePath!.isNotEmpty) {
 final cleanPath = Uri.decodeFull(m.voiceNotePath!.replaceAll('file://',''));
 final file = File(cleanPath);
 if (file.existsSync() && file.lengthSync() > 0) {
 try {
 final bytes = await file.readAsBytes();
 map['voiceNoteBase64'] = base64Encode(bytes);
 } catch (e) {
 debugPrint('Error reading voice note file bytes: $e');
 }
 }
 }

 // 2. Custom Photo File Base64
 if (m.imagePath.isNotEmpty && (m.imagePath.startsWith('/') || m.imagePath.contains('file://') || m.imagePath.contains('data/'))) {
 final cleanPath = m.imagePath.replaceAll('file://','');
 final file = File(cleanPath);
 if (file.existsSync() && file.lengthSync() > 0) {
 try {
 final bytes = await file.readAsBytes();
 map['imageBase64'] = base64Encode(bytes);
 } catch (e) {
 debugPrint('Error reading image file bytes: $e');
 }
 }
 }

 // 3. Custom Video File Base64 (Supports videos up to 100 MB)
 if (m.videoPath != null && m.videoPath!.isNotEmpty && (m.videoPath!.startsWith('/') || m.videoPath!.contains('file://') || m.videoPath!.contains('data/'))) {
 final cleanPath = m.videoPath!.replaceAll('file://','');
 final file = File(cleanPath);
 if (file.existsSync() && file.lengthSync() > 0 && file.lengthSync() < 100 * 1024 * 1024) {
 try {
 final bytes = await file.readAsBytes();
 map['videoBase64'] = base64Encode(bytes);
 } catch (e) {
 debugPrint('Error reading video file bytes: $e');
 }
 }
 }

 // 4. Custom Audio / Music File Base64
        final audioP = (m.audioPath != null && m.audioPath!.isNotEmpty) ? m.audioPath : m.voiceNotePath;
        if (audioP != null && audioP.isNotEmpty && (audioP.startsWith('/') || audioP.contains('file://') || audioP.contains('data/'))) {
          final cleanPath = Uri.decodeFull(audioP.replaceAll('file://',''));
          final file = File(cleanPath);
          if (file.existsSync() && file.lengthSync() > 0) {
            try {
              final bytes = await file.readAsBytes();
              map['audioBase64'] = base64Encode(bytes);
              map['voiceNoteBase64'] = base64Encode(bytes);
            } catch (e) {
              debugPrint('Error reading audio file bytes: ');
            }
          }
        }

        memoriesJson.add(map);
 }

 final payloadMap = {
'elderId': targetId,
'memories': memoriesJson,
'updatedAt': DateTime.now().toIso8601String(),
'updatedTimestamp': DateTime.now().millisecondsSinceEpoch,
 };

 final prefs = await SharedPreferences.getInstance();
 final payload = jsonEncode(payloadMap);
 await prefs.setString('cloud_memories_$targetId', payload);

 debugPrint('CLOUD MEMORIES PUSH: Elder ID = $targetId, Count = ${memories.length}');

 bool anySuccess = false;
 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/memories/$targetId.json');
 final request = await _mediaClient.putUrl(url);
 request.headers.contentType = ContentType.json;
 request.write(payload);
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();
 debugPrint('CLOUD MEMORIES PUSH Firebase: status=${response.statusCode}');
 if (response.statusCode == 200) {
 anySuccess = true;
 }
 } catch (e) {
 debugPrint('CLOUD MEMORIES PUSH Error ($fb): $e');
 }
 }
 return anySuccess;
 } catch (e) {
 debugPrint('CloudSync push memories error: $e');
 return false;
 }
 }

 /// Pull memories list from Cloud Relay (/memories/NER-XXXX.json)
 Future<CloudPullResponse> pullMemoriesCloudDetailed(String elderId) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return CloudPullResponse(CloudSyncStatus.notFound);

 final prefs = await SharedPreferences.getInstance();
 bool encounteredNetworkError = false;

 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/memories/$targetId.json');
 final request = await _client.getUrl(url);
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();

 if (response.statusCode == 200 && body.trim().isNotEmpty && body !='null') {
 final decoded = jsonDecode(body);
 if (decoded is Map<String, dynamic> && decoded['memories'] is List) {
 await prefs.setString('cloud_memories_$targetId', body);
 debugPrint('CLOUD MEMORIES PULL: status=200 (${(decoded['memories'] as List).length} memories found)');
 return CloudPullResponse(CloudSyncStatus.found, decoded);
 }
 } else if (response.statusCode == 404 || body.trim() =='null') {
 debugPrint('CLOUD MEMORIES PULL: status=404 (No cloud memories created yet)');
 }
 } catch (e) {
 debugPrint('CLOUD MEMORIES PULL Error ($fb): $e');
 if (e is SocketException || e.toString().contains('SocketException')) {
 encounteredNetworkError = true;
 }
 }
 }

 if (encounteredNetworkError) {
 final localRaw = prefs.getString('cloud_memories_$targetId');
 if (localRaw != null && localRaw.isNotEmpty) {
 try {
 final decoded = jsonDecode(localRaw);
 if (decoded is Map<String, dynamic> && decoded['memories'] is List) {
 return CloudPullResponse(CloudSyncStatus.found, decoded);
 }
 } catch (_) {}
 }
 return CloudPullResponse(CloudSyncStatus.networkError);
 }

 return CloudPullResponse(CloudSyncStatus.notFound);
 }

 /// Backward-compatible pullScheduleCloud
 Future<Map<String, dynamic>?> pullScheduleCloud(String elderId) async {
 final response = await pullScheduleCloudDetailed(elderId);
 return response.data;
 }

 StreamSubscription? _sseLocationSubscription;
 String _activeSseLocationElderId = '';

 /// Push real GPS elder location to Cloud Relay (/locations/NER-XXXX.json)
 Future<bool> pushLocationCloud({
 required String elderId,
 required double latitude,
 required double longitude,
 required double accuracy,
 required bool isSharing,
 double? altitude,
 double? speed,
 }) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return false;

 try {
 final payloadMap = {
 'elderId': targetId,
 'latitude': latitude,
 'longitude': longitude,
 'accuracy': accuracy,
 'isSharing': isSharing,
 'altitude': altitude ?? 0.0,
 'speed': speed ?? 0.0,
 'timestamp': DateTime.now().toUtc().toIso8601String(),
 'updatedAt': DateTime.now().toUtc().toIso8601String(),
 'updatedTimestamp': DateTime.now().millisecondsSinceEpoch,
 };

 _inMemoryCache['location_$targetId'] = payloadMap;
 final prefs = await SharedPreferences.getInstance();
 final payload = jsonEncode(payloadMap);
 await prefs.setString('cloud_location_$targetId', payload);

 debugPrint('CLOUD LOCATION PUSH: Elder=$targetId, Lat=$latitude, Lng=$longitude, Acc=$accuracy, Sharing=$isSharing');

 bool anySuccess = false;
 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/locations/$targetId.json');
 final request = await _client.putUrl(url);
 request.headers.contentType = ContentType.json;
 request.write(payload);
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();
 debugPrint('CLOUD LOCATION PUSH Firebase: status=${response.statusCode}, body=$body');
 if (response.statusCode == 200) {
 anySuccess = true;
 }
 } catch (e) {
 debugPrint('CLOUD LOCATION PUSH Error ($fb): $e');
 }
 }

 for (final kv in _kvEndpoints) {
 try {
 final url = Uri.parse('$kv/location_$targetId');
 final request = await _client.putUrl(url);
 request.headers.contentType = ContentType.json;
 request.write(payload);
 final response = await request.close();
 await response.drain();
 if (response.statusCode == 200) {
 anySuccess = true;
 }
 } catch (_) {}
 }

 return anySuccess;
 } catch (e) {
 debugPrint('CloudSync push location error: $e');
 return false;
 }
 }

 /// Pull latest elder location from Cloud Relay (/locations/NER-XXXX.json)
 Future<Map<String, dynamic>?> pullLocationCloud(String elderId) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return null;

 final prefs = await SharedPreferences.getInstance();

 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/locations/$targetId.json');
 final request = await _client.getUrl(url);
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();

 if (response.statusCode == 200 && body.trim().isNotEmpty && body != 'null') {
 final decoded = jsonDecode(body);
 if (decoded is Map<String, dynamic>) {
 await prefs.setString('cloud_location_$targetId', body);
 debugPrint('CLOUD LOCATION PULL: status=200 for $targetId');
 return decoded;
 }
 }
 } catch (e) {
 debugPrint('CLOUD LOCATION PULL Firebase Error ($fb): $e');
 }
 }

 for (final kv in _kvEndpoints) {
 try {
 final url = Uri.parse('$kv/location_$targetId');
 final request = await _client.getUrl(url);
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();

 if (response.statusCode == 200 && body.trim().isNotEmpty && body != 'null') {
 final decoded = jsonDecode(body);
 if (decoded is Map<String, dynamic>) {
 await prefs.setString('cloud_location_$targetId', body);
 return decoded;
 }
 }
 } catch (_) {}
 }

 final localRaw = prefs.getString('cloud_location_$targetId');
 if (localRaw != null && localRaw.isNotEmpty) {
 try {
 final decoded = jsonDecode(localRaw);
 if (decoded is Map<String, dynamic>) {
 return decoded;
 }
 } catch (_) {}
 }

 return null;
 }

 /// Subscribes to real-time Server-Sent Events (SSE) for Elder Location
 void startRealtimeLocationListener(String elderId, Function(Map<String, dynamic>) onLocationReceived) {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty || targetId == _activeSseLocationElderId) return;

 _activeSseLocationElderId = targetId;
 try {
 _sseLocationSubscription?.cancel();
 } catch (_) {}

 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/locations/$targetId.json');
 HttpClient().getUrl(url).then((req) {
 req.headers.add('Accept', 'text/event-stream');
 return req.close();
 }).then((response) {
 if (response.statusCode == 200) {
 debugPrint('REALTIME LOCATION SSE STREAM ESTABLISHED for $targetId');
 _sseLocationSubscription = response
 .transform(utf8.decoder)
 .transform(const LineSplitter())
 .listen((line) {
 if (line.startsWith('data:')) {
 final jsonStr = line.substring(6).trim();
 if (jsonStr.isNotEmpty && jsonStr != 'null') {
 try {
 final decoded = jsonDecode(jsonStr);
 if (decoded is Map<String, dynamic>) {
 final payload = (decoded['data'] is Map<String, dynamic>)
 ? Map<String, dynamic>.from(decoded['data'])
 : decoded;
 if (payload.containsKey('latitude') && payload.containsKey('longitude')) {
 onLocationReceived(payload);
 }
 }
 } catch (e) {
 debugPrint('SSE Location JSON Parse Error: $e');
 }
 }
 }
 }, onError: (e) {
 debugPrint('SSE Location Stream Error: $e');
 _activeSseLocationElderId = '';
 }, onDone: () {
 _activeSseLocationElderId = '';
 });
 }
 }).catchError((e) {
 debugPrint('SSE Location Connection Error: $e');
 _activeSseLocationElderId = '';
 });
 } catch (_) {}
 }
 }

 void stopRealtimeLocationListener() {
 try {
 _sseLocationSubscription?.cancel();
 } catch (_) {}
 _sseLocationSubscription = null;
 _activeSseLocationElderId = '';
 }

 StreamSubscription? _sseActivitySubscription;
 String _activeSseActivityElderId = '';
 Function(Map<String, dynamic>)? _activeActivityCallback;
 Timer? _sseActivityReconnectTimer;

 /// Push elder daily activity and step count to Cloud Relay (/activity/NER-XXXX.json)
 Future<bool> pushElderActivityCloud(String elderId, Map<String, dynamic> activityData) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return false;

 try {
 final now = DateTime.now().toUtc();
 final nowMs = now.millisecondsSinceEpoch;
 final payloadMap = {
 'elderId': targetId,
 'activity': activityData,
 'today': activityData['today'] ?? activityData,
 'steps': (activityData['today'] is Map) ? activityData['today']['steps'] : activityData['steps'],
 'updatedAt': now.toIso8601String(),
 'updatedTimestamp': nowMs,
 };

 _inMemoryCache['activity_$targetId'] = payloadMap;
 final prefs = await SharedPreferences.getInstance();
 final payload = jsonEncode(payloadMap);
 await prefs.setString('cloud_activity_$targetId', payload);

 debugPrint('CLOUD ACTIVITY PUSH: Elder=$targetId, steps=${payloadMap["steps"]}');

 bool anySuccess = false;
 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/activity/$targetId.json');
 final request = await _client.putUrl(url);
 request.headers.contentType = ContentType.json;
 request.write(payload);
 final response = await request.close();
 await response.drain();
 debugPrint('CLOUD ACTIVITY PUSH Firebase: status=${response.statusCode}');
 if (response.statusCode == 200) {
 anySuccess = true;
 }
 } catch (e) {
 debugPrint('CLOUD ACTIVITY PUSH Error ($fb): $e');
 }
 }

 for (final kv in _kvEndpoints) {
 try {
 final url = Uri.parse('$kv/activity_$targetId');
 final request = await _client.putUrl(url);
 request.headers.contentType = ContentType.json;
 request.write(payload);
 final response = await request.close();
 await response.drain();
 if (response.statusCode == 200) {
 anySuccess = true;
 }
 } catch (_) {}
 }

 return anySuccess;
 } catch (e) {
 debugPrint('CloudSync push activity error: $e');
 return false;
 }
 }

 /// Pull elder activity data from Cloud Relay (/activity/NER-XXXX.json)
 Future<Map<String, dynamic>?> pullElderActivityCloud(String elderId, {bool forceFresh = false}) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return null;

 final prefs = await SharedPreferences.getInstance();

 for (final fb in _firebaseEndpoints) {
 try {
 final cacheBuster = DateTime.now().millisecondsSinceEpoch;
 final url = Uri.parse('$fb/activity/$targetId.json?ts=$cacheBuster');
 final request = await _client.getUrl(url);
 request.headers.add('Cache-Control', 'no-cache, no-store, must-revalidate');
 request.headers.add('Pragma', 'no-cache');
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();

 if (response.statusCode == 200 && body.trim().isNotEmpty && body != 'null') {
 final decoded = jsonDecode(body);
 if (decoded is Map<String, dynamic>) {
 await prefs.setString('cloud_activity_$targetId', body);
 debugPrint('CLOUD ACTIVITY PULL: status=200 for $targetId (fresh from network)');
 final result = Map<String, dynamic>.from(decoded);
 result['_isFromNetwork'] = true;
 return result;
 }
 }
 } catch (e) {
 debugPrint('CLOUD ACTIVITY PULL Firebase Error ($fb): $e');
 }
 }

 for (final kv in _kvEndpoints) {
 try {
 final cacheBuster = DateTime.now().millisecondsSinceEpoch;
 final url = Uri.parse('$kv/activity_$targetId?ts=$cacheBuster');
 final request = await _client.getUrl(url);
 request.headers.add('Cache-Control', 'no-cache, no-store, must-revalidate');
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();

 if (response.statusCode == 200 && body.trim().isNotEmpty && body != 'null') {
 final decoded = jsonDecode(body);
 if (decoded is Map<String, dynamic>) {
 await prefs.setString('cloud_activity_$targetId', body);
 final result = Map<String, dynamic>.from(decoded);
 result['_isFromNetwork'] = true;
 return result;
 }
 }
 } catch (_) {}
 }

 if (!forceFresh) {
 final localRaw = prefs.getString('cloud_activity_$targetId');
 if (localRaw != null && localRaw.isNotEmpty) {
 try {
 final decoded = jsonDecode(localRaw);
 if (decoded is Map<String, dynamic>) {
 final result = Map<String, dynamic>.from(decoded);
 result['_isFromNetwork'] = false;
 return result;
 }
 } catch (_) {}
 }
 }

 return null;
 }

 /// Subscribes to real-time Server-Sent Events (SSE) for Elder Activity
 void startRealtimeActivityListener(String elderId, Function(Map<String, dynamic>) onActivityReceived) {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return;

 _activeActivityCallback = onActivityReceived;

 if (targetId == _activeSseActivityElderId && _sseActivitySubscription != null) {
 return;
 }

 _activeSseActivityElderId = targetId;
 _connectActivitySse(targetId);
 }

 void _connectActivitySse(String targetId) {
 try {
 _sseActivitySubscription?.cancel();
 } catch (_) {}
 _sseActivitySubscription = null;
 _sseActivityReconnectTimer?.cancel();

 final fb = _firebaseEndpoints.first;
 try {
 final url = Uri.parse('$fb/activity/$targetId.json');
 HttpClient().getUrl(url).then((req) {
 req.headers.add('Accept', 'text/event-stream');
 req.headers.add('Cache-Control', 'no-cache');
 return req.close();
 }).then((response) {
 if (response.statusCode == 200) {
 debugPrint('REALTIME ACTIVITY SSE STREAM ESTABLISHED for $targetId');
 _sseActivitySubscription = response
 .transform(utf8.decoder)
 .transform(const LineSplitter())
 .listen((line) {
 if (line.startsWith('data:')) {
 final jsonStr = line.replaceFirst(RegExp(r'^data:\s*'), '').trim();
 if (jsonStr.isNotEmpty && jsonStr != 'null') {
 try {
 final decoded = jsonDecode(jsonStr);
 if (decoded is Map<String, dynamic>) {
 Map<String, dynamic>? payload;
 if (decoded['data'] is Map<String, dynamic>) {
 payload = Map<String, dynamic>.from(decoded['data']);
 } else if (decoded.containsKey('data') && decoded['data'] is Map) {
 payload = Map<String, dynamic>.from(decoded['data'] as Map);
 } else if (decoded['data'] != null && decoded['path'] is String) {
 final path = decoded['path'] as String;
 if (path.contains('steps')) {
 payload = {'steps': decoded['data']};
 } else {
 payload = {'data': decoded['data']};
 }
 } else {
 payload = decoded;
 }

 if (payload != null && _activeActivityCallback != null) {
 payload['_isFromNetwork'] = true;
 _activeActivityCallback!(payload);
 }
 }
 } catch (e) {
 debugPrint('SSE Activity JSON Parse Error: $e');
 }
 }
 }
 }, onError: (e) {
 debugPrint('SSE Activity Stream Error: $e');
 _scheduleActivityReconnect(targetId);
 }, onDone: () {
 debugPrint('SSE Activity Stream closed');
 _scheduleActivityReconnect(targetId);
 });
 } else {
 _scheduleActivityReconnect(targetId);
 }
 }).catchError((e) {
 debugPrint('SSE Activity Connection Error: $e');
 _scheduleActivityReconnect(targetId);
 });
 } catch (_) {
 _scheduleActivityReconnect(targetId);
 }
 }

 void _scheduleActivityReconnect(String targetId) {
 _sseActivityReconnectTimer?.cancel();
 _sseActivityReconnectTimer = Timer(const Duration(seconds: 4), () {
 if (_activeSseActivityElderId == targetId && _activeActivityCallback != null) {
 debugPrint('Auto-reconnecting SSE Activity Stream for $targetId...');
 _connectActivitySse(targetId);
 }
 });
 }

 void reconnectRealtimeActivity(String elderId) {
 final targetId = cleanId(elderId);
 if (targetId.isNotEmpty) {
 _activeSseActivityElderId = targetId;
 _connectActivitySse(targetId);
 }
 }

 void stopRealtimeActivityListener() {
 _sseActivityReconnectTimer?.cancel();
 _sseActivityReconnectTimer = null;
 try {
 _sseActivitySubscription?.cancel();
 } catch (_) {}
 _sseActivitySubscription = null;
 _activeSseActivityElderId = '';
 _activeActivityCallback = null;
 }

 /// Push SOS Alert when Elder misses 3 reminders (Attempt 4)
 Future<bool> pushSosAlertCloud(String elderId, {required String title, required String message, String reminderId = ''}) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return false;

 try {
 final now = DateTime.now().toUtc();
 final nowMs = now.millisecondsSinceEpoch;
 final payloadMap = {
 'elderId': targetId,
 'title': title,
 'message': message,
 'reminderId': reminderId,
 'active': true,
 'timestamp': nowMs,
 'updatedAt': now.toIso8601String(),
 };

 _inMemoryCache['sos_$targetId'] = payloadMap;
 final prefs = await SharedPreferences.getInstance();
 final payload = jsonEncode(payloadMap);
 await prefs.setString('cloud_sos_$targetId', payload);

 debugPrint('CLOUD SOS PUSH: Elder=$targetId, title=$title');

 bool anySuccess = false;
 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/sos/$targetId.json');
 final request = await _client.putUrl(url);
 request.headers.contentType = ContentType.json;
 request.write(payload);
 final response = await request.close();
 await response.drain();
 if (response.statusCode == 200) anySuccess = true;
 } catch (e) {
 debugPrint('CLOUD SOS PUSH Error ($fb): $e');
 }
 }

 for (final kv in _kvEndpoints) {
 try {
 final url = Uri.parse('$kv/sos_$targetId');
 final request = await _client.putUrl(url);
 request.headers.contentType = ContentType.json;
 request.write(payload);
 final response = await request.close();
 await response.drain();
 if (response.statusCode == 200) anySuccess = true;
 } catch (_) {}
 }

 return anySuccess;
 } catch (e) {
 debugPrint('CloudSync push sos error: $e');
 return false;
 }
 }

 /// Pull SOS Alert from Cloud Relay for Caregiver (/sos/NER-XXXX.json)
 Future<Map<String, dynamic>?> pullSosAlertCloud(String elderId) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return null;

 final prefs = await SharedPreferences.getInstance();

 for (final fb in _firebaseEndpoints) {
 try {
 final cacheBuster = DateTime.now().millisecondsSinceEpoch;
 final url = Uri.parse('$fb/sos/$targetId.json?ts=$cacheBuster');
 final request = await _client.getUrl(url);
 request.headers.add('Cache-Control', 'no-cache, no-store, must-revalidate');
 request.headers.add('Pragma', 'no-cache');
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();

 if (response.statusCode == 200 && body.isNotEmpty && body != 'null') {
 final decoded = jsonDecode(body) as Map<String, dynamic>;
 _inMemoryCache['sos_$targetId'] = decoded;
 await prefs.setString('cloud_sos_$targetId', body);
 return decoded;
 }
 } catch (e) {
 debugPrint('CLOUD SOS PULL Error ($fb): $e');
 }
 }

 for (final kv in _kvEndpoints) {
 try {
 final cacheBuster = DateTime.now().millisecondsSinceEpoch;
 final url = Uri.parse('$kv/sos_$targetId?ts=$cacheBuster');
 final request = await _client.getUrl(url);
 request.headers.add('Cache-Control', 'no-cache, no-store, must-revalidate');
 final response = await request.close();
 final body = await response.transform(utf8.decoder).join();

 if (response.statusCode == 200 && body.isNotEmpty && body != 'null') {
 final decoded = jsonDecode(body) as Map<String, dynamic>;
 _inMemoryCache['sos_$targetId'] = decoded;
 await prefs.setString('cloud_sos_$targetId', body);
 return decoded;
 }
 } catch (_) {}
 }

 final localRaw = prefs.getString('cloud_sos_$targetId');
 if (localRaw != null && localRaw.isNotEmpty) {
 return jsonDecode(localRaw) as Map<String, dynamic>;
 }
 return _inMemoryCache['sos_$targetId'];
 }

 /// Clear active SOS Alert from Cloud Relay
 Future<void> clearSosAlertCloud(String elderId) async {
 final targetId = cleanId(elderId);
 if (targetId.isEmpty) return;

 try {
 _inMemoryCache.remove('sos_$targetId');
 final prefs = await SharedPreferences.getInstance();
 await prefs.remove('cloud_sos_$targetId');

 for (final fb in _firebaseEndpoints) {
 try {
 final url = Uri.parse('$fb/sos/$targetId.json');
 final request = await _client.deleteUrl(url);
 final response = await request.close();
 await response.drain();
 } catch (_) {}
 }

 for (final kv in _kvEndpoints) {
 try {
 final url = Uri.parse('$kv/sos_$targetId');
 final request = await _client.deleteUrl(url);
 final response = await request.close();
 await response.drain();
 } catch (_) {}
 }
 } catch (e) {
 debugPrint('CloudSync clear sos error: $e');
 }
 }
}


enum CloudSyncStatus {
 found,
 notFound,
 networkError,
}

class CloudPullResponse {
 final CloudSyncStatus status;
 final Map<String, dynamic>? data;

 CloudPullResponse(this.status, [this.data]);
}
