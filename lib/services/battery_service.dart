import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'notification_service.dart';
import 'i18n_service.dart';

class BatteryService extends ChangeNotifier {
  final Battery _battery = Battery();

  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  int? _lastWarnedLevel;
  bool _isMonitoring = false;

  StreamSubscription<BatteryState>? _stateSubscription;
  Timer? _periodicTimer;
  I18nService? _i18n;

  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;
  bool get isCharging =>
      _batteryState == BatteryState.charging || _batteryState == BatteryState.full;
  bool get isLowBattery => _batteryLevel < 20 && !isCharging;

  void initBatteryMonitoring({I18nService? i18n}) {
    if (i18n != null) _i18n = i18n;
    if (_isMonitoring) return;
    _isMonitoring = true;

    _updateBatteryStatus();

    _stateSubscription = _battery.onBatteryStateChanged.listen((state) {
      _batteryState = state;
      _updateBatteryStatus();
    });

    // Periodically poll battery level every 10 seconds
    _periodicTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateBatteryStatus();
    });
  }

  void updateI18n(I18nService i18n) {
    _i18n = i18n;
  }

  Future<void> _updateBatteryStatus() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      bool levelChanged = (_batteryLevel != level);
      bool stateChanged = (_batteryState != state);

      _batteryLevel = level;
      _batteryState = state;

      // Reset warning tracker if device starts charging or level goes >= 20
      if (isCharging || _batteryLevel >= 20) {
        _lastWarnedLevel = null;
      } else if (_batteryLevel < 20) {
        // Low battery condition: less than 20% and NOT charging
        // Alert for EVERY 1% decrease (e.g. 19%, 18%, 17%, 16%, etc.)
        if (_lastWarnedLevel == null || _batteryLevel < _lastWarnedLevel!) {
          _lastWarnedLevel = _batteryLevel;
          _triggerLowBatteryVoiceAlert(_batteryLevel);
        }
      }

      if (levelChanged || stateChanged) {
        notifyListeners();
      }
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        debugPrint('Battery Plugin: Requires cold app launch to bind platform channel (handled gracefully).');
      } else {
        debugPrint('Error reading battery status: $e');
      }
    }
  }

  Future<void> _triggerLowBatteryVoiceAlert(int level) async {
    final lang = _i18n?.currentLang ?? 'en';
    final voiceText = _getBatteryVoiceText(level, lang);

    debugPrint('Low Battery Voice Alert triggered ($level%): $voiceText');

    try {
      await NotificationService.speakText(voiceText, lang: lang);
    } catch (e) {
      debugPrint('Error speaking low battery alert: $e');
    }
  }

  String _getBatteryVoiceText(int level, String lang) {
    switch (lang) {
      case 'ta':
        return 'பேட்டரி அளவு $level சதவீதம் மட்டுமே உள்ளது. தயவுசெய்து சார்ஜரை இணைக்கவும்.';
      case 'as':
        return 'বেটাৰীৰ মাত্ৰা $level শতাংশলৈ হ্ৰাস পাইছে। অনুগ্ৰহ কৰি এতিয়াই চাজাৰ সংযোগ কৰক।';
      case 'bn':
        return 'ব্যাটারির মাত্রা $level শতাংশে নেমে গেছে। অনুগ্রহ করে এখনই চার্জার যুক্ত করুন।';
      case 'ne':
        return 'ब्याट्री स्तर $level प्रतिशत मात्र छ। कृपया आफ्नो चार्जर जोड्नुहोस्।';
      case 'mni':
        return 'বেত্তরীগী থাক $level শতাংশদা লৈরে। চাবগীদমক চার্জার সমজিনবীয়ু।';
      case 'lus':
        return 'Battery dinhmun $level percent chauh a awm ta. Khawngaihin i charger thlun zawm rawh.';
      case 'kha':
        return 'Ka borog battery ka la duna sha $level percent. Sngewbha pyniasoh ia ka charger jong phi.';
      case 'hi':
        return 'बैटरी का स्तर केवल $level प्रतिशत है। कृपया तुरंत अपना चार्जर कनेक्ट करें।';
      case 'en':
      default:
        return 'Battery level is low at $level percent. Please connect your charger now.';
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }
}
