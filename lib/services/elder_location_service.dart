import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cloud_sync_service.dart';

enum LocationConnectionState {
  available,
  updating,
  offline,
  disabled,
}

class ElderLocationService extends ChangeNotifier {
  static const MethodChannel _nativeChannel = MethodChannel('com.aninai/notifications');

  // Elder device state
  bool _isSharingActive = true;
  bool _isTracking = false;
  Position? _currentPosition;
  LocationPermission _permission = LocationPermission.denied;
  bool _isServiceEnabled = false;
  String _errorMessage = '';
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  String _activeElderId = '';

  StreamSubscription<Position>? _positionStreamSub;
  Timer? _heartbeatTimer;

  // Caregiver view state
  Map<String, dynamic>? _remoteElderLocation;
  bool _isCaregiverSyncing = false;
  DateTime? _lastCaregiverFetchTime;

  // Getters
  bool get isSharingActive => _isSharingActive;
  bool get isTracking => _isTracking;
  Position? get currentPosition => _currentPosition;
  LocationPermission get permission => _permission;
  bool get isServiceEnabled => _isServiceEnabled;
  String get errorMessage => _errorMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;
  bool get hasLocationPermission =>
      _permission == LocationPermission.always || _permission == LocationPermission.whileInUse;

  Map<String, dynamic>? get remoteElderLocation => _remoteElderLocation;
  bool get isCaregiverSyncing => _isCaregiverSyncing;
  DateTime? get lastCaregiverFetchTime => _lastCaregiverFetchTime;

  ElderLocationService() {
    _loadLocalSettings();
  }

  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSharingActive = prefs.getBool('aninai_location_sharing_active') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  /// Initialize and start tracking on Elder side
  Future<void> initElderTracking(String elderId) async {
    final cleanId = elderId.trim().toUpperCase();
    if (cleanId.isEmpty) return;
    _activeElderId = cleanId;

    await _checkPermissionAndService();
    if (_isSharingActive && hasLocationPermission && _isServiceEnabled) {
      await startElderTracking(cleanId);
    }
  }

  Future<void> _checkPermissionAndService() async {
    try {
      _isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      _permission = await Geolocator.checkPermission();
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking location permission: $e');
    }
  }

  /// User-friendly permission request workflow
  Future<bool> requestLocationPermission() async {
    _errorMessage = '';
    try {
      _isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isServiceEnabled) {
        _errorMessage = 'gpsDisabledMsg';
        notifyListeners();
        await Geolocator.openLocationSettings();
        return false;
      }

      _permission = await Geolocator.checkPermission();
      if (_permission == LocationPermission.denied) {
        _permission = await Geolocator.requestPermission();
      }

      if (_permission == LocationPermission.deniedForever) {
        _errorMessage = 'locationPermRequired';
        notifyListeners();
        await Geolocator.openAppSettings();
        return false;
      }

      if (_permission == LocationPermission.denied) {
        _errorMessage = 'locationPermRequired';
        notifyListeners();
        return false;
      }

      notifyListeners();

      if (_activeElderId.isNotEmpty && _isSharingActive) {
        await startElderTracking(_activeElderId);
      }
      return true;
    } catch (e) {
      debugPrint('requestLocationPermission error: $e');
      _errorMessage = 'locationUnavailableMsg';
      notifyListeners();
      return false;
    }
  }

  /// Start periodic & balanced GPS tracking for the Elder
  Future<void> startElderTracking(String elderId) async {
    final cleanId = elderId.trim().toUpperCase();
    if (cleanId.isEmpty) return;
    _activeElderId = cleanId;

    await _checkPermissionAndService();
    if (!_isServiceEnabled) {
      _errorMessage = 'gpsDisabledMsg';
      notifyListeners();
      return;
    }

    if (!hasLocationPermission) {
      _errorMessage = 'locationPermRequired';
      notifyListeners();
      return;
    }

    _isTracking = true;
    _errorMessage = '';
    notifyListeners();

    // 1. Show persistent Android Notification: "Location sharing is active"
    try {
      await _nativeChannel.invokeMethod('startLocationSharingNotification', {
        'title': 'Location sharing is active',
        'body': 'Your location is being shared with your caregiver.',
      });
    } catch (_) {}

    // 2. Fetch current pinpoint location immediately
    try {
      _isSyncing = true;
      notifyListeners();

      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _currentPosition = current;
      _lastSyncTime = DateTime.now();

      await CloudSyncService().pushLocationCloud(
        elderId: cleanId,
        latitude: current.latitude,
        longitude: current.longitude,
        accuracy: current.accuracy,
        altitude: current.altitude,
        speed: current.speed,
        isSharing: true,
      );
    } catch (e) {
      debugPrint('Error getting initial GPS position: $e');
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _currentPosition = last;
        _lastSyncTime = DateTime.now();
        await CloudSyncService().pushLocationCloud(
          elderId: cleanId,
          latitude: last.latitude,
          longitude: last.longitude,
          accuracy: last.accuracy,
          isSharing: true,
        );
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    // 3. Setup continuous position stream with balanced accuracy and 15m filter
    _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen(
      (pos) async {
        if (!_isSharingActive) return;
        _currentPosition = pos;
        _lastSyncTime = DateTime.now();
        notifyListeners();

        await CloudSyncService().pushLocationCloud(
          elderId: cleanId,
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          altitude: pos.altitude,
          speed: pos.speed,
          isSharing: true,
        );
      },
      onError: (err) {
        debugPrint('Geolocator stream error: $err');
      },
    );

    // 4. Periodic heartbeat (every 45 seconds) to ensure cloud stays fresh
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (timer) async {
      if (!_isSharingActive || !_isTracking) return;
      if (_currentPosition != null) {
        _lastSyncTime = DateTime.now();
        await CloudSyncService().pushLocationCloud(
          elderId: cleanId,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          accuracy: _currentPosition!.accuracy,
          isSharing: true,
        );
        notifyListeners();
      }
    });
  }

  /// Stop Elder tracking and notify backend
  Future<void> stopElderTracking({bool updateBackend = true}) async {
    _isTracking = false;
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    try {
      await _nativeChannel.invokeMethod('stopLocationSharingNotification');
    } catch (_) {}

    if (updateBackend && _activeElderId.isNotEmpty && _currentPosition != null) {
      await CloudSyncService().pushLocationCloud(
        elderId: _activeElderId,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        accuracy: _currentPosition!.accuracy,
        isSharing: false,
      );
    }
    notifyListeners();
  }

  /// Toggle Location Sharing from Elder UI
  Future<void> toggleLocationSharing(String elderId) async {
    _isSharingActive = !_isSharingActive;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aninai_location_sharing_active', _isSharingActive);

    if (_isSharingActive) {
      await startElderTracking(elderId);
    } else {
      await stopElderTracking(updateBackend: true);
    }
    notifyListeners();
  }

  /// Manual refresh on elder side
  Future<void> refreshElderCurrentLocation() async {
    if (_activeElderId.isEmpty) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _currentPosition = pos;
      _lastSyncTime = DateTime.now();
      await CloudSyncService().pushLocationCloud(
        elderId: _activeElderId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        isSharing: _isSharingActive,
      );
    } catch (e) {
      debugPrint('Manual refresh elder location error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ==========================================
  // CAREGIVER SECTION LOGIC
  // ==========================================

  /// Fetch elder's latest location from Cloud Relay
  Future<Map<String, dynamic>?> fetchCaregiverElderLocation(String elderId) async {
    final cleanId = elderId.trim().toUpperCase();
    if (cleanId.isEmpty) return null;

    _isCaregiverSyncing = true;
    notifyListeners();

    try {
      final data = await CloudSyncService().pullLocationCloud(cleanId);
      if (data != null) {
        _remoteElderLocation = data;
        _lastCaregiverFetchTime = DateTime.now();
      }
      return _remoteElderLocation;
    } catch (e) {
      debugPrint('fetchCaregiverElderLocation error: $e');
      return null;
    } finally {
      _isCaregiverSyncing = false;
      notifyListeners();
    }
  }

  /// Subscribe to real-time SSE updates for the connected elder
  void startCaregiverRealtimeStream(String elderId) {
    final cleanId = elderId.trim().toUpperCase();
    if (cleanId.isEmpty) return;

    fetchCaregiverElderLocation(cleanId);

    CloudSyncService().startRealtimeLocationListener(cleanId, (payload) {
      _remoteElderLocation = payload;
      _lastCaregiverFetchTime = DateTime.now();
      notifyListeners();
    });
  }

  void stopCaregiverRealtimeStream() {
    CloudSyncService().stopRealtimeLocationListener();
  }

  /// Convenience alias for caregiver dashboard to subscribe to live updates
  void listenToElderLocation(String elderId) => startCaregiverRealtimeStream(elderId);

  /// Convenience alias for caregiver dashboard to refresh elder location
  Future<Map<String, dynamic>?> refreshLocation(String elderId) => fetchCaregiverElderLocation(elderId);

  /// Determine high-level connection state for caregiver UI
  LocationConnectionState getConnectionState(Map<String, dynamic>? data) {
    if (data == null) return LocationConnectionState.offline;

    final isSharing = data['isSharing'];
    if (isSharing == false || isSharing == 'false') {
      return LocationConnectionState.disabled;
    }

    final ts = data['updatedTimestamp'];
    if (ts is int) {
      final diff = DateTime.now().millisecondsSinceEpoch - ts;
      if (diff < 5 * 60 * 1000) {
        return LocationConnectionState.available;
      }
      if (diff < 15 * 60 * 1000) {
        return LocationConnectionState.updating;
      }
      return LocationConnectionState.offline;
    }

    final isoStr = data['timestamp'] ?? data['updatedAt'];
    if (isoStr is String) {
      try {
        final dt = DateTime.parse(isoStr);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 5) return LocationConnectionState.available;
        if (diff.inMinutes < 15) return LocationConnectionState.updating;
        return LocationConnectionState.offline;
      } catch (_) {}
    }

    return LocationConnectionState.available;
  }

  /// Format last updated string for caregiver UI
  String formatLastUpdatedString(Map<String, dynamic>? data) {
    if (data == null) return 'Not available';

    DateTime? dt;
    final ts = data['updatedTimestamp'];
    if (ts is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      final isoStr = data['timestamp'] ?? data['updatedAt'];
      if (isoStr is String) {
        try {
          dt = DateTime.parse(isoStr).toLocal();
        } catch (_) {}
      }
    }

    if (dt == null) return 'Recently';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? "minute" : "minutes"} ago';
    } else if (diff.inHours < 24) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  /// Deep link into Google Maps to view coordinates
  Future<bool> openInGoogleMaps(double latitude, double longitude) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (e) {
      debugPrint('Error launching Google Maps URL: $e');
      try {
        final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude(Elder Location)');
        return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  /// Deep link into Google Maps Navigation / Directions from Caregiver to Elder
  Future<bool> openDirectionsToElder(double latitude, double longitude) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (e) {
      debugPrint('Error launching Google Maps directions: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
