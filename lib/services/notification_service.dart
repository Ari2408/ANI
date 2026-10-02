import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'voice_cloning_service.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('com.purb_chetana/notifications');
  static final FlutterTts _tts = FlutterTts();
  static final AudioPlayer _customVoicePlayer = AudioPlayer();
  static bool _ttsInitialized = false;
  static bool _isSpeaking = false;
  static bool isCaretakerMode = false;

  static void Function(String reminderId, String actionType)? onNotificationActionListener;

  static Future<void> init() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {}

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationAction') {
        final String reminderId = call.arguments['reminderId'] ?? '';
        final String actionType = call.arguments['actionType'] ?? '';
        if (onNotificationActionListener != null) {
          onNotificationActionListener!(reminderId, actionType);
        }
      }
    });

    try {
      if (!_ttsInitialized) {
        _tts.setErrorHandler((msg) {
          debugPrint('FlutterTts Error safely caught: $msg');
        });
        await _tts.setSpeechRate(0.45);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
        _ttsInitialized = true;
      }
    } catch (e) {
      debugPrint('NotificationService init TTS error: $e');
    }
  }

  static Future<void> _configureTtsLanguage(String langCode) async {
    final Map<String, List<String>> languageLocales = {
      'en': ['en-IN', 'en-US'],
    };

    final candidates = languageLocales[langCode.toLowerCase()] ?? ['en-IN', 'en-US'];

    bool success = false;
    for (final loc in candidates) {
      try {
        final isAvail = await _tts.isLanguageAvailable(loc);
        if (isAvail == 1 || isAvail == 0 || isAvail == 2 || isAvail == true || isAvail == 'true') {
          final result = await _tts.setLanguage(loc);
          if (result == 1 || result == true || result == 'true') {
            success = true;
            break;
          }
        }
      } catch (_) {}
    }

    if (!success) {
      try {
        await _tts.setLanguage('en-IN');
      } catch (_) {}
    }
  }

  static Future<void> _selectMaleVoice(String langCode) async {
    try {
      final List<dynamic>? voices = await _tts.getVoices;
      if (voices != null && voices.isNotEmpty) {
        final targetLang = langCode.toLowerCase();
        Map<String, String>? bestMaleVoice;

        for (var v in voices) {
          if (v is Map) {
            final name = (v['name'] ?? '').toString().toLowerCase();
            final locale = (v['locale'] ?? '').toString().toLowerCase();

            if (locale.contains(targetLang) || (targetLang == 'ta' && (locale.contains('ta') || name.contains('ta-in')))) {
              if (name.contains('-tac-') || name.contains('male') || name.contains('-tam-') || name.contains('-enm-') || name.contains('boy')) {
                bestMaleVoice = {"name": v['name'].toString(), "locale": v['locale'].toString()};
                break;
              } else if (!name.contains('female') && !name.contains('-taf-') && !name.contains('-enf-')) {
                bestMaleVoice ??= {"name": v['name'].toString(), "locale": v['locale'].toString()};
              }
            }
          }
        }

        if (bestMaleVoice != null) {
          await _tts.setVoice(bestMaleVoice);
          debugPrint('Selected Male AI Voice in Flutter: ${bestMaleVoice['name']}');
        }
      }
    } catch (e) {
      debugPrint('Error selecting Male AI Voice: $e');
    }
  }

  static Future<bool> isLanguageVoiceSupported(String langCode) async {
    try {
      final loc = langCode == 'ne' ? 'ne-NP' : (langCode == 'ta' ? 'ta-IN' : (langCode == 'as' ? 'as-IN' : 'en-IN'));
      final res = await _tts.isLanguageAvailable(loc);
      if (res == 1 || res == 0 || res == 2 || res == true || res == 'true') {
        final setRes = await _tts.setLanguage(loc);
        return setRes == 1 || setRes == true || setRes == 'true';
      }
    } catch (_) {}
    return false;
  }

  static Future<void> speakText(
    String text, {
    String lang = 'en',
    String? fallbackEnglishText,
    String? customVoicePath,
    int voiceMode = 0,
    String? clonedVoiceSamplePath,
    String reminderId = '',
    bool isResponseFeedback = false,
  }) async {
    final bool isAppointment = (reminderId.isNotEmpty && (reminderId.startsWith('apt_') || reminderId.contains('apt') || reminderId.contains('appointment'))) ||
        text.toLowerCase().contains('appointment') ||
        text.contains('சந்திப்பு');

    final bool isRoutine = !isResponseFeedback && !isAppointment &&
        ((reminderId.isNotEmpty && (reminderId.startsWith('act_') || reminderId.contains('act') || reminderId.contains('routine'))) ||
            text.toLowerCase().contains('daily activity') ||
            text.contains('தினசரி') ||
            text.toLowerCase().contains('dinasari'));

    var finalCustomPath = (isResponseFeedback || isAppointment) ? '' : (customVoicePath ?? '');
    final effectiveClonedVoiceSamplePath = (isResponseFeedback || isAppointment) ? '' : (clonedVoiceSamplePath ?? '');
    int effectiveVoiceMode = (isResponseFeedback || isAppointment) ? 0 : voiceMode;

    if (!isResponseFeedback && !isAppointment && finalCustomPath.isNotEmpty && File(finalCustomPath).existsSync() && File(finalCustomPath).lengthSync() > 0) {
      if (effectiveVoiceMode != 3) {
        effectiveVoiceMode = 1;
      }
    } else if (!isResponseFeedback && !isAppointment && (isRoutine || ((effectiveVoiceMode == 1 || effectiveVoiceMode == 3) && finalCustomPath.isEmpty))) {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final searchDirs = [docDir, Directory('/data/user/0/com.example.smriti_jyoti/app_flutter')];
        File? latest;
        for (var d in searchDirs) {
          if (d.existsSync()) {
            final files = d.listSync().whereType<File>().where((f) => (f.path.contains('custom_reminder_voice_') || f.path.contains('meal_voice_')) && f.path.endsWith('.m4a') && f.lengthSync() > 0);
            for (var f in files) {
              if (latest == null || f.lastModifiedSync().isAfter(latest.lastModifiedSync())) {
                latest = f;
              }
            }
          }
        }
        if (latest != null) {
          finalCustomPath = latest.path;
          effectiveVoiceMode = 1;
          debugPrint('Auto-resolved latest custom voice file for routine: $finalCustomPath');
        }
      } catch (_) {}
    }

    // Option 1 & Option 4: Direct Custom Recorded / Saved Voice Note
    if (!isResponseFeedback && (effectiveVoiceMode == 1 || effectiveVoiceMode == 3 || isRoutine) && finalCustomPath.isNotEmpty) {
      try {
        final file = File(finalCustomPath);
        if (file.existsSync() && file.lengthSync() > 0) {
          if (_isSpeaking) {
            try { await _tts.stop(); } catch (_) {}
            _isSpeaking = false;
          }
          try { await _customVoicePlayer.stop(); } catch (_) {}
          await _customVoicePlayer.play(DeviceFileSource(finalCustomPath));
          debugPrint('Playing Option 1 / 4 custom saved voice note recording directly: $finalCustomPath');
          return;
        } else {
          debugPrint('Option 1 / 4 custom voice file does not exist or is empty: $finalCustomPath');
        }
      } catch (e) {
        debugPrint('Error playing Option 1 / 4 custom voice note in Flutter: $e');
      }
    }

    // Option 2: Cloned Family Voice (Grandson Voice)
    if (effectiveVoiceMode == 2 && effectiveClonedVoiceSamplePath != null && effectiveClonedVoiceSamplePath.isNotEmpty && File(effectiveClonedVoiceSamplePath).existsSync()) {
      try {
        final clonedAudioPath = await VoiceCloningService.generateClonedVoiceAudio(
          text: text,
          sampleAudioPath: effectiveClonedVoiceSamplePath,
          langCode: lang,
        );
        if (clonedAudioPath != null && File(clonedAudioPath).existsSync() && File(clonedAudioPath).lengthSync() > 0) {
          final player = AudioPlayer();
          await player.play(DeviceFileSource(clonedAudioPath));
          debugPrint('Successfully playing Option 2 AI Voice Cloned generated audio file: $clonedAudioPath');
          return;
        }
      } catch (e) {
        debugPrint('Voice cloning synthesis fallback to TTS: $e');
      }
    }

    final cleanText = text
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]', unicode: true), '')
        .trim();
    if (cleanText.isEmpty) return;

    if (_isSpeaking) {
      try {
        await _tts.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (_) {}
    }

    _isSpeaking = true;

    try {
      await _tts.setVolume(1.0);
      
      // Select Male AI Voice Engine (override default female voice)
      await _selectMaleVoice(lang);

      // Option 2: AI Voice Cloned from Family Member (Grandson / Boy)
      if (voiceMode == 2) {
        debugPrint('Synthesizing Option 2 AI Voice cloned from grandson/boy voice sample: $clonedVoiceSamplePath');
        try {
          await _tts.setPitch(1.05); // Young male/boy voice pitch characteristic
          await _tts.setSpeechRate(0.48); // Crisp natural speech rate
        } catch (_) {}
      } else {
        try {
          await _tts.setPitch(0.98); // Standard male voice pitch
          await _tts.setSpeechRate(0.48);
        } catch (_) {}
      }

      final isTamil = lang.toLowerCase() == 'ta';
      final isEnglish = lang.toLowerCase() == 'en';
      bool spokeSuccessfully = false;

      if (isEnglish) {
        // 1. Pure English Mode: speak cleanText directly via en-IN / en-US
        try {
          await _tts.setLanguage('en-IN');
          final res = await _tts.speak(cleanText);
          if (res != -1 && res != false && res != 'false') {
            spokeSuccessfully = true;
          }
        } catch (_) {
          try {
            await _tts.setLanguage('en-US');
            final res = await _tts.speak(cleanText);
            if (res != -1 && res != false && res != 'false') {
              spokeSuccessfully = true;
            }
          } catch (_) {}
        }
      } else if (isTamil) {
        // 2. Tamil Mode: Try ta-IN native locale first
        try {
          final isAvail = await _tts.isLanguageAvailable('ta-IN');
          if (isAvail == 1 || isAvail == 0 || isAvail == 2 || isAvail == true || isAvail == 'true') {
            final setRes = await _tts.setLanguage('ta-IN');
            if (setRes == 1 || setRes == true || setRes == 'true' || setRes == 0) {
              final res = await _tts.speak(cleanText);
              if (res != -1 && res != false && res != 'false') {
                spokeSuccessfully = true;
              }
            }
          }
        } catch (_) {}
      } else {
        // 3. Other regional languages
        try {
          await _configureTtsLanguage(lang);
          final res = await _tts.speak(cleanText);
          if (res != -1 && res != false && res != 'false') {
            spokeSuccessfully = true;
          }
        } catch (_) {}
      }

      // If primary TTS voice did not output (e.g. offline Tamil voice pack missing), speak safe English / Phonetic Tamil fallback in en-IN!
      if (!spokeSuccessfully) {
        final rawFallback = (fallbackEnglishText != null && fallbackEnglishText.isNotEmpty)
            ? fallbackEnglishText
            : cleanText;
        final safeEnglishText = rawFallback.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();
        final finalSpeech = safeEnglishText.isNotEmpty ? safeEnglishText : cleanText;

        try {
          await _tts.setLanguage('en-IN');
          await _tts.speak(finalSpeech);
        } catch (_) {
          try {
            await _tts.setLanguage('en-US');
            await _tts.speak(finalSpeech);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('TTS speak error safely caught: $e');
    } finally {
      Future.delayed(const Duration(seconds: 4), () {
        _isSpeaking = false;
      });
    }
  }

  static Future<void> stopTts() async {
    _isSpeaking = false;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static Future<void> showSystemNotification({
    required String title,
    required String body,
    String reminderId = '',
    String takenLabel = 'Taken',
    String yetToTakeLabel = 'Yet to Take',
    String? spokenText,
    String? fallbackEnglishText,
    String? customVoicePath,
    int voiceMode = 0,
    String? clonedVoiceSamplePath,
    String langCode = 'en',
    bool isHydration = false,
    bool showActions = true,
    bool speak = true,
    VoidCallback? onAction,
    VoidCallback? onTaken,
    VoidCallback? onYetToTake,
  }) async {
    final int notifId = DateTime.now().millisecondsSinceEpoch % 100000;
    final bool isRoutine = reminderId.startsWith('act_') ||
        reminderId.contains('act') ||
        reminderId.contains('routine') ||
        title.toLowerCase().contains('daily activity') ||
        title.contains('தினசரி') ||
        title.toLowerCase().contains('dinasari');
    final effectiveVoiceMode = voiceMode;
    final effectiveCustomVoicePath = customVoicePath ?? '';
    final effectiveClonedVoiceSamplePath = clonedVoiceSamplePath ?? '';

    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
        'id': notifId,
        'reminderId': reminderId,
        'takenLabel': takenLabel,
        'yetToTakeLabel': yetToTakeLabel,
        'isHydration': isHydration,
        'showActions': showActions,
        'customVoicePath': effectiveCustomVoicePath,
        'voiceMode': effectiveVoiceMode,
        'clonedVoiceSamplePath': effectiveClonedVoiceSamplePath,
      });
    } catch (_) {}

    if (speak) {
      final textToSpeak = (spokenText != null && spokenText.isNotEmpty) ? spokenText : '$title. $body';
      // Wait 1200ms for system notification chime to finish so Android OS restores full audio volume to Flutter TTS!
      await Future.delayed(const Duration(milliseconds: 1200));
      await speakText(
        textToSpeak,
        lang: langCode,
        fallbackEnglishText: fallbackEnglishText,
        customVoicePath: effectiveCustomVoicePath,
        voiceMode: effectiveVoiceMode,
        clonedVoiceSamplePath: effectiveClonedVoiceSamplePath,
        reminderId: reminderId,
      );
    }
  }

  static Future<void> playEmergencyBeepAlarm() async {
    try {
      await _channel.invokeMethod('playEmergencyBeepAlarm');
    } catch (_) {}
  }

  static Future<void> scheduleAlarm({
    required int id,
    required DateTime triggerAt,
    required String title,
    required String body,
    String reminderId = '',
    String takenLabel = 'Taken',
    String yetToTakeLabel = 'Yet to Take',
    String spokenText = '',
    String fallbackText = '',
    String? customVoicePath,
    int voiceMode = 0,
    String? clonedVoiceSamplePath,
    String langCode = 'en',
    bool isHydration = false,
    bool showActions = true,
  }) async {
    final bool isRoutine = reminderId.startsWith('act_') ||
        reminderId.contains('act') ||
        reminderId.contains('routine') ||
        title.toLowerCase().contains('daily activity') ||
        title.contains('தினசரி') ||
        title.toLowerCase().contains('dinasari');
    final effectiveVoiceMode = voiceMode;
    final effectiveCustomVoicePath = customVoicePath ?? '';
    final effectiveClonedVoiceSamplePath = clonedVoiceSamplePath ?? '';

    try {
      await _channel.invokeMethod('scheduleAlarm', {
        'id': id,
        'triggerAtMs': triggerAt.millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'reminderId': reminderId,
        'takenLabel': takenLabel,
        'yetToTakeLabel': yetToTakeLabel,
        'spokenText': spokenText,
        'fallbackText': fallbackText,
        'customVoicePath': effectiveCustomVoicePath,
        'voiceMode': effectiveVoiceMode,
        'clonedVoiceSamplePath': effectiveClonedVoiceSamplePath,
        'langCode': langCode,
        'isHydration': isHydration,
        'showActions': showActions,
      });
    } catch (_) {}
  }

  static Future<void> cancelAlarm(int id) async {
    try {
      await _channel.invokeMethod('cancelAlarm', {'id': id});
    } catch (_) {}
  }
}
