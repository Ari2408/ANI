import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../models/memory_item.dart';
import 'notification_service.dart';
import 'cloud_sync_service.dart';

class MemoryLaneService extends ChangeNotifier {
  static const String _storageKey = 'aninai_custom_memories';

  List<MemoryItem> _memories = [];
  bool _isLoaded = false;

  // Real Hardware Microphone Audio Recorder & Speech-to-Text Engine
  final AudioRecorder _audioRecorder = AudioRecorder();
  final SpeechToText _speechToText = SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Dedicated Music Player Engine for Favorite Music
  final AudioPlayer _musicPlayer = AudioPlayer();
  String? _currentlyPlayingMusicId;
  PlayerState _musicPlayerState = PlayerState.stopped;
  Duration _musicPosition = Duration.zero;
  Duration _musicDuration = Duration.zero;

  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String _recordedSpokenText = '';
  String? _lastRecordedVoiceNotePath;

  // Active Voice Note Audio Playback State
  String? _currentlyPlayingId;
  bool _isPlayingVoiceNote = false;
  String? _currentElderId;

  String? get currentElderId => _currentElderId;

  void setCurrentElderId(String id) {
    final clean = CloudSyncService().cleanId(id);
    if (clean.isNotEmpty && clean != _currentElderId) {
      _currentElderId = clean;
      loadMemories(elderId: clean);
    }
  }

  MemoryLaneService() {
    _initMemories();
    _initAudioPlayerListeners();
    _initMusicPlayerListeners();
  }

    String _getMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.m4a') || lower.endsWith('.aac') || lower.endsWith('.mp4')) {
      return 'audio/mp4';
    } else if (lower.endsWith('.wav')) {
      return 'audio/wav';
    } else if (lower.endsWith('.ogg')) {
      return 'audio/ogg';
    } else if (lower.endsWith('.flac')) {
      return 'audio/flac';
    } else if (lower.endsWith('.amr')) {
      return 'audio/amr';
    }
    return 'audio/mpeg';
  }

  String _cleanFilePath(String rawPath) {
    String clean = rawPath.trim();
    if (clean.startsWith('file://')) {
      clean = clean.replaceFirst(RegExp(r'^file://+'), '');
      if (!clean.startsWith('/')) {
        clean = '/$clean';
      }
    }
    try {
      clean = Uri.decodeFull(clean);
    } catch (_) {}
    return clean.trim();
  }

  void _initAudioPlayerListeners() {
    try {
      _audioPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}

    _audioPlayer.onPlayerComplete.listen((_) {
      debugPrint('AudioPlayer: Playback complete.');
      _currentlyPlayingId = null;
      _isPlayingVoiceNote = false;
      notifyListeners();
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      debugPrint('AudioPlayer state changed: $state');
      if (state == PlayerState.completed) {
        _currentlyPlayingId = null;
        _isPlayingVoiceNote = false;
        notifyListeners();
      }
    });

    _audioPlayer.onLog.listen((msg) {
      debugPrint('AudioPlayer log: $msg');
    });
  }

  void _initMusicPlayerListeners() {
    try {
      _musicPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}

    _musicPlayer.onPlayerComplete.listen((_) {
      debugPrint('MusicPlayer: Playback complete.');
      _currentlyPlayingMusicId = null;
      _musicPlayerState = PlayerState.completed;
      _musicPosition = Duration.zero;
      notifyListeners();
    });

    _musicPlayer.onPlayerStateChanged.listen((state) {
      debugPrint('MusicPlayer state changed: $state');
      _musicPlayerState = state;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _currentlyPlayingMusicId = null;
        _musicPosition = Duration.zero;
      }
      notifyListeners();
    });

    _musicPlayer.onPositionChanged.listen((pos) {
      _musicPosition = pos;
      notifyListeners();
    });

    _musicPlayer.onDurationChanged.listen((dur) {
      _musicDuration = dur;
      notifyListeners();
    });
  }

  List<MemoryItem> get memories => List.unmodifiable(_memories);
  List<MemoryItem> get musicMemories => List.unmodifiable(_memories.where((m) => m.category == 'music' || m.mediaType == 'audio').toList());
  List<MemoryItem> get placesMemories => List.unmodifiable(_memories.where((m) => m.category == 'places' || m.isPublicLandmark).toList());
  List<MemoryItem> get personalMemories => List.unmodifiable(_memories.where((m) => m.category == 'personal' && !m.isPublicLandmark && m.mediaType != 'audio').toList());

  bool get isRecording => _isRecording;
  int get recordSeconds => _recordSeconds;
  String get recordedSpokenText => _recordedSpokenText;
  String? get lastRecordedVoiceNotePath => _lastRecordedVoiceNotePath;

  String? get currentlyPlayingId => _currentlyPlayingId;
  bool get isPlayingVoiceNote => _isPlayingVoiceNote;

  String? get currentlyPlayingMusicId => _currentlyPlayingMusicId;
  bool get isMusicPlaying => _musicPlayerState == PlayerState.playing;
  PlayerState get musicPlayerState => _musicPlayerState;
  Duration get musicPosition => _musicPosition;
  Duration get musicDuration => _musicDuration;

  Timer? _autoSyncTimer;
  bool _isAutoSyncRunning = false;

  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    if (_currentElderId != null && _currentElderId!.isNotEmpty) {
      CloudSyncService().startRealtimeMemoriesListener(_currentElderId!, (data) => _applyCloudMemoriesData(data));
    }

    _autoSyncTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isAutoSyncRunning) return;
      _isAutoSyncRunning = true;

      try {
        if (_currentElderId == null || _currentElderId!.isEmpty) return;

        final cloudResp = await CloudSyncService().pullMemoriesCloudDetailed(_currentElderId!);
        if (cloudResp.status == CloudSyncStatus.found && cloudResp.data != null) {
          await _applyCloudMemoriesData(cloudResp.data!);
        } else if (cloudResp.status == CloudSyncStatus.notFound && _memories.isNotEmpty) {
          await CloudSyncService().pushMemoriesCloud(
            _currentElderId!,
            _memories.where((m) => m.isCustom).toList(),
          );
        }
      } catch (e) {
        debugPrint('Memory auto sync error: $e');
      } finally {
        _isAutoSyncRunning = false;
      }
    });
  }

  Future<void> _applyCloudMemoriesData(Map<String, dynamic> cloudData) async {
    final memoriesList = cloudData['memories'] as List?;
    if (memoriesList == null) return;

    try {
      final key = (_currentElderId != null && _currentElderId!.isNotEmpty)
          ? '${_storageKey}_$_currentElderId'
          : _storageKey;

      final appDir = await getApplicationDocumentsDirectory();
      final List<MemoryItem> cloudItems = [];

      for (var e in memoriesList) {
        final Map<String, dynamic> itemMap = Map<String, dynamic>.from(e);
        final itemId = itemMap['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

        // 1. Decode voice note audio file from Base64
        if (itemMap['voiceNoteBase64'] != null && itemMap['voiceNoteBase64'].toString().isNotEmpty) {
          try {
            final voiceBytes = base64Decode(itemMap['voiceNoteBase64'].toString());
            final voiceFile = File('${appDir.path}/cloud_voice_$itemId.m4a');
            await voiceFile.writeAsBytes(voiceBytes);
            itemMap['voiceNotePath'] = voiceFile.path;
          } catch (err) {
            debugPrint('Error decoding voice note audio file: $err');
          }
        }

        // 2. Decode photo file from Base64
        if (itemMap['photosBase64'] is List && (itemMap['photosBase64'] as List).isNotEmpty) {
          try {
            final List<String> localPhotos = [];
            final pList = itemMap['photosBase64'] as List;
            for (int pIdx = 0; pIdx < pList.length; pIdx++) {
              final imgBytes = base64Decode(pList[pIdx].toString());
              final imgFile = File('${appDir.path}/cloud_img_${itemId}_$pIdx.jpg');
              await imgFile.writeAsBytes(imgBytes);
              localPhotos.add(imgFile.path);
            }
            if (localPhotos.isNotEmpty) {
              itemMap['photos'] = localPhotos;
              itemMap['imagePath'] = localPhotos.first;
            }
          } catch (err) {
            debugPrint('Error decoding photos array: $err');
          }
        } else if (itemMap['imageBase64'] != null && itemMap['imageBase64'].toString().isNotEmpty) {
          try {
            final imgBytes = base64Decode(itemMap['imageBase64'].toString());
            final imgFile = File('${appDir.path}/cloud_img_$itemId.jpg');
            await imgFile.writeAsBytes(imgBytes);
            itemMap['imagePath'] = imgFile.path;
            itemMap['photos'] = [imgFile.path];
          } catch (err) {
            debugPrint('Error decoding photo file: $err');
          }
        }

        // 3. Decode video file from Base64
        if (itemMap['videoBase64'] != null && itemMap['videoBase64'].toString().isNotEmpty) {
          try {
            final vidBytes = base64Decode(itemMap['videoBase64'].toString());
            final vidFile = File('${appDir.path}/cloud_vid_$itemId.mp4');
            await vidFile.writeAsBytes(vidBytes);
            itemMap['videoPath'] = vidFile.path;
          } catch (err) {
            debugPrint('Error decoding video file: $err');
          }
        }

        // 4. Decode audio / music file from Base64
        if (itemMap['audioBase64'] != null && itemMap['audioBase64'].toString().isNotEmpty) {
          try {
            final audBytes = base64Decode(itemMap['audioBase64'].toString());
            final audFile = File('${appDir.path}/cloud_audio_$itemId.mp3');
            await audFile.writeAsBytes(audBytes);
            itemMap['audioPath'] = audFile.path;
          } catch (err) {
            debugPrint('Error decoding audio file: $err');
          }
        }

        cloudItems.add(MemoryItem.fromJson(itemMap));
      }

      bool updated = false;
      if (cloudItems.length != _memories.length) {
        updated = true;
      } else {
        for (int i = 0; i < cloudItems.length; i++) {
          if (_memories[i].id != cloudItems[i].id ||
              _memories[i].title != cloudItems[i].title ||
              _memories[i].imagePath != cloudItems[i].imagePath ||
              _memories[i].videoPath != cloudItems[i].videoPath) {
            updated = true;
            break;
          }
        }
      }

      if (updated) {
        _memories = cloudItems;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, jsonEncode(_memories.map((m) => m.toJson()).toList()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error applying cloud memories data: $e');
    }
  }

  Future<void> loadMemories({String? elderId}) async {
    if (elderId != null && elderId.trim().isNotEmpty) {
      _currentElderId = CloudSyncService().cleanId(elderId);
    }
    _isLoaded = false;
    await _initMemories();
  }

  Future<void> _initMemories() async {
    _memories = [];
    final key = (_currentElderId != null && _currentElderId!.isNotEmpty)
        ? '${_storageKey}_$_currentElderId'
        : _storageKey;

    bool hadLocalCache = false;
    // 1. Load from local cache first for instant display
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final customItems = decoded.map((e) => MemoryItem.fromJson(e)).toList();
        _memories = customItems;
        hadLocalCache = true;
      }
    } catch (e) {
      debugPrint('Error loading custom memories: $e');
    }

    if (_memories.isEmpty) {
      _memories = [];
    }

    _isLoaded = true;
    notifyListeners();

    // 2. Fetch latest from Cloud Realtime Database if elderId is set & start auto-sync stream
    if (_currentElderId != null && _currentElderId!.isNotEmpty) {
      try {
        final cloudResp = await CloudSyncService().pullMemoriesCloudDetailed(_currentElderId!);
        if (cloudResp.status == CloudSyncStatus.found && cloudResp.data != null) {
          await _applyCloudMemoriesData(cloudResp.data!);
        } else if (cloudResp.status == CloudSyncStatus.notFound && hadLocalCache && _memories.isNotEmpty) {
          await CloudSyncService().pushMemoriesCloud(
            _currentElderId!,
            _memories.where((m) => m.isCustom).toList(),
          );
        }
      } catch (e) {
        debugPrint('Error fetching cloud memories: $e');
      }
      _startAutoSyncTimer();
    }
  }

  Future<void> addMemory({
    required String title,
    required String date,
    required String storyNote,
    String? imagePath,
    String? videoPath,
    String? audioPath,
    String mediaType = 'photo',
    String category = 'personal',
    String? voiceNotePath,
    String createdByRole = 'caretaker',
  }) async {
    final finalStory = storyNote.isNotEmpty
        ? storyNote
        : (category == 'music' ? 'Favourite music track for Elder.' : 'Personal memory uploaded for Elder.');

    final appDir = await getApplicationDocumentsDirectory();
    final itemId = 'custom_${DateTime.now().millisecondsSinceEpoch}';

    String? permanentAudioPath = (audioPath != null && audioPath.isNotEmpty)
        ? audioPath
        : ((voiceNotePath != null && voiceNotePath.isNotEmpty) ? voiceNotePath : _lastRecordedVoiceNotePath);

    if (permanentAudioPath != null && permanentAudioPath.isNotEmpty) {
      final clean = _cleanFilePath(permanentAudioPath);
      if (!clean.startsWith('assets/') && !clean.startsWith('http')) {
        final srcFile = File(clean);
        if (srcFile.existsSync() && srcFile.lengthSync() > 0) {
          try {
            final ext = clean.contains('.') ? clean.split('.').last : 'mp3';
            final permFile = File('${appDir.path}/memory_audio_${itemId}.$ext');
            await srcFile.copy(permFile.path);
            if (permFile.existsSync() && permFile.lengthSync() > 0) {
              permanentAudioPath = permFile.path;
              debugPrint('Copied uploaded/recorded audio to permanent path: ${permFile.path} (${permFile.lengthSync()} bytes)');
            } else {
              debugPrint('Failed to copy audio file or file size 0: ${permFile.path}');
              permanentAudioPath = clean;
            }
          } catch (e) {
            debugPrint('Error copying audio file to permanent storage: $e');
            permanentAudioPath = clean;
          }
        } else {
          permanentAudioPath = clean;
        }
      }
    }

    final newItem = MemoryItem(
      id: itemId,
      title: title,
      date: date,
      imagePath: imagePath ?? '',
      videoPath: videoPath,
      audioPath: permanentAudioPath,
      mediaType: mediaType,
      category: category,
      storyNote: finalStory,
      voiceNotePath: permanentAudioPath,
      isCustom: true,
      isPublicLandmark: category == 'places',
      createdByRole: createdByRole,
    );

    _memories.insert(0, newItem);
    _lastRecordedVoiceNotePath = null;
    _recordedSpokenText = '';
    notifyListeners();

    await _saveCustomMemories();
  }

  Future<void> updateMemory({
    required String id,
    required String title,
    required String date,
    required String storyNote,
    String? imagePath,
    String? videoPath,
    String? audioPath,
    String mediaType = 'photo',
    String category = 'personal',
    String? voiceNotePath,
  }) async {
    final index = _memories.indexWhere((m) => m.id == id);
    if (index != -1) {
      final old = _memories[index];
      _memories[index] = MemoryItem(
        id: old.id,
        title: title,
        date: date,
        imagePath: imagePath ?? old.imagePath,
        videoPath: videoPath ?? old.videoPath,
        audioPath: audioPath ?? old.audioPath,
        mediaType: mediaType,
        category: category,
        storyNote: storyNote,
        voiceNotePath: voiceNotePath ?? old.voiceNotePath,
        isCustom: old.isCustom,
        isPublicLandmark: old.isPublicLandmark,
        createdByRole: old.createdByRole,
      );
      _recordedSpokenText = '';
      _lastRecordedVoiceNotePath = null;
      notifyListeners();
      await _saveCustomMemories();
    }
  }

  Future<void> deleteMemory(String id) async {
    if (_currentlyPlayingId == id) {
      await stopVoiceNote();
    }
    if (_currentlyPlayingMusicId == id) {
      await stopMusic();
    }
    _memories.removeWhere((m) => m.id == id);
    notifyListeners();
    await _saveCustomMemories();
  }

  Future<void> addFavoriteMusic({
    required String title,
    String? artist,
    String? description,
    required String audioPath,
    String? fileName,
    String? duration,
    String createdByRole = 'caretaker',
    void Function(String status)? onStatusChanged,
  }) async {
    onStatusChanged?.call('uploading');
    final appDir = await getApplicationDocumentsDirectory();
    final itemId = 'music_${DateTime.now().millisecondsSinceEpoch}';

    String permanentPath = audioPath;
    final clean = _cleanFilePath(audioPath);
    if (!clean.startsWith('assets/') && !clean.startsWith('http')) {
      final srcFile = File(clean);
      if (srcFile.existsSync() && srcFile.lengthSync() > 0) {
        try {
          final ext = clean.contains('.') ? clean.split('.').last : 'mp3';
          final permFile = File('${appDir.path}/favorite_music_${itemId}.$ext');
          await srcFile.copy(permFile.path);
          if (permFile.existsSync() && permFile.lengthSync() > 0) {
            permanentPath = permFile.path;
          }
        } catch (e) {
          debugPrint('Error saving favorite music permanently: $e');
        }
      }
    }

    // MP3 file upload and local storage complete, now saving metadata/database
    onStatusChanged?.call('saving');

    final newItem = MemoryItem(
      id: itemId,
      title: title,
      artist: artist,
      date: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
      imagePath: '',
      audioPath: permanentPath,
      voiceNotePath: permanentPath,
      mediaType: 'audio',
      category: 'music',
      storyNote: description ?? '',
      isCustom: true,
      isPublicLandmark: false,
      createdByRole: createdByRole,
      fileName: fileName,
      duration: duration,
    );

    _memories.insert(0, newItem);
    notifyListeners();
    await _saveCustomMemories();
    onStatusChanged?.call('saved');
  }

  Future<void> addFavoritePlace({
    required String placeName,
    required String description,
    required List<String> photos,
    String? videoPath,
    String? audioPath,
    String createdByRole = 'caretaker',
    void Function(String status)? onStatusChanged,
  }) async {
    onStatusChanged?.call('saving');
    final appDir = await getApplicationDocumentsDirectory();
    final itemId = 'place_${DateTime.now().millisecondsSinceEpoch}';

    // Copy photos permanently
    final List<String> permanentPhotos = [];
    for (int i = 0; i < photos.length; i++) {
      final p = photos[i];
      final clean = _cleanFilePath(p);
      if (!clean.startsWith('assets/') && !clean.startsWith('http')) {
        final src = File(clean);
        if (src.existsSync() && src.lengthSync() > 0) {
          try {
            final ext = clean.contains('.') ? clean.split('.').last : 'jpg';
            final dest = File('${appDir.path}/place_photo_${itemId}_$i.$ext');
            await src.copy(dest.path);
            permanentPhotos.add(dest.path);
          } catch (_) {
            permanentPhotos.add(clean);
          }
        } else {
          permanentPhotos.add(clean);
        }
      } else {
        permanentPhotos.add(clean);
      }
    }

    // Copy video permanently if local
    String? permanentVideo = videoPath;
    if (videoPath != null && videoPath.isNotEmpty) {
      final clean = _cleanFilePath(videoPath);
      if (!clean.startsWith('assets/') && !clean.startsWith('http')) {
        final src = File(clean);
        if (src.existsSync() && src.lengthSync() > 0) {
          try {
            final ext = clean.contains('.') ? clean.split('.').last : 'mp4';
            final dest = File('${appDir.path}/place_video_${itemId}.$ext');
            await src.copy(dest.path);
            permanentVideo = dest.path;
          } catch (_) {}
        }
      }
    }

    // Copy recorded narration permanently
    String? permanentAudio = audioPath;
    if (audioPath != null && audioPath.isNotEmpty) {
      final clean = _cleanFilePath(audioPath);
      if (!clean.startsWith('assets/') && !clean.startsWith('http')) {
        final src = File(clean);
        if (src.existsSync() && src.lengthSync() > 0) {
          try {
            final ext = clean.contains('.') ? clean.split('.').last : 'm4a';
            final dest = File('${appDir.path}/place_story_${itemId}.$ext');
            await src.copy(dest.path);
            permanentAudio = dest.path;
          } catch (_) {}
        }
      }
    }

    final newItem = MemoryItem(
      id: itemId,
      title: placeName,
      date: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
      imagePath: permanentPhotos.isNotEmpty ? permanentPhotos.first : '',
      videoPath: permanentVideo,
      audioPath: permanentAudio,
      voiceNotePath: permanentAudio,
      mediaType: (permanentVideo != null && permanentVideo.isNotEmpty) ? 'video' : 'photo',
      category: 'places',
      storyNote: description,
      photos: permanentPhotos,
      isCustom: true,
      isPublicLandmark: false,
      createdByRole: createdByRole,
    );

    _memories.insert(0, newItem);
    _lastRecordedVoiceNotePath = null;
    notifyListeners();
    await _saveCustomMemories();
    onStatusChanged?.call('saved');
  }

  Future<void> _saveCustomMemories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = (_currentElderId != null && _currentElderId!.isNotEmpty)
          ? '${_storageKey}_$_currentElderId'
          : _storageKey;
      final customItems = _memories.where((m) => m.isCustom).map((m) => m.toJson()).toList();
      await prefs.setString(key, jsonEncode(customItems));

      if (_currentElderId != null && _currentElderId!.isNotEmpty) {
        await CloudSyncService().pushMemoriesCloud(
          _currentElderId!,
          _memories.where((m) => m.isCustom).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error saving custom memories: $e');
    }
  }

  // Real Hardware Microphone Audio Recording Engine
  Future<bool> startRecording({String langCode = 'en'}) async {
    _recordTimer?.cancel();
    _recordSeconds = 0;
    _recordedSpokenText = '';
    _lastRecordedVoiceNotePath = null;

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission denied for audio recording.');
        _isRecording = false;
        notifyListeners();
        return false;
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

      try {
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );
      } catch (e1) {
        debugPrint('AacLc config error: $e1, trying default RecordConfig');
        await _audioRecorder.start(
          const RecordConfig(),
          path: filePath,
        );
      }

      _lastRecordedVoiceNotePath = filePath;
      _isRecording = true;
      notifyListeners();

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordSeconds++;
        notifyListeners();
      });
      return true;
    } catch (e) {
      debugPrint('Microphone audio recording start error: $e');
      _isRecording = false;
      _lastRecordedVoiceNotePath = null;
      notifyListeners();
      return false;
    }
  }

  Future<String?> stopRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    String? savedPath;

    try {
      final path = await _audioRecorder.stop();
      final targetPath = (path != null && path.isNotEmpty) ? path : _lastRecordedVoiceNotePath;
      if (targetPath != null && targetPath.isNotEmpty) {
        final cleanPath = _cleanFilePath(targetPath);
        final file = File(cleanPath);
        if (file.existsSync()) {
          int previousSize = -1;
          int attempts = 0;
          while (attempts < 15) {
            final currentSize = file.lengthSync();
            if (currentSize == previousSize && currentSize > 0) {
              break;
            }
            previousSize = currentSize;
            await Future.delayed(const Duration(milliseconds: 200));
            attempts++;
          }
          savedPath = cleanPath;
          _lastRecordedVoiceNotePath = cleanPath;
          debugPrint('Audio recorded successfully & size stabilized: $cleanPath (${file.lengthSync()} bytes)');
        } else {
          savedPath = cleanPath;
          _lastRecordedVoiceNotePath = cleanPath;
        }
      }
    } catch (e) {
      debugPrint('Error stopping audio recorder: $e');
    }

    _isRecording = false;
    notifyListeners();
    return savedPath;
  }

  Future<void> cancelRecording() async {
    _recordTimer?.cancel();
    _recordTimer = null;

    try {
      await _audioRecorder.stop();
    } catch (_) {}

    _isRecording = false;
    _recordSeconds = 0;
    _recordedSpokenText = '';
    _lastRecordedVoiceNotePath = null;
    notifyListeners();
  }

  // Active Voice Audio Playback Engine (Hardware Speaker / Audio Player)
  Future<void> playVoiceNote(MemoryItem item, String langCode, {String? customText}) async {
    if (_currentlyPlayingId == item.id && _isPlayingVoiceNote) {
      await stopVoiceNote();
      return;
    }

    try {
      await _audioPlayer.stop();
    } catch (_) {}
    await NotificationService.stopTts();

    _currentlyPlayingId = item.id;
    _isPlayingVoiceNote = true;
    notifyListeners();

    final String voicePath;
    if (item.audioPath != null && item.audioPath!.trim().isNotEmpty) {
      voicePath = item.audioPath!.trim();
    } else if (item.voiceNotePath != null && item.voiceNotePath!.trim().isNotEmpty) {
      voicePath = item.voiceNotePath!.trim();
    } else {
      voicePath = '';
    }

    final storyText = customText ?? (item.storyNote.isNotEmpty ? item.storyNote : item.title);
    bool playedAudioFile = false;

    if (voicePath.isNotEmpty) {
      final cleanPath = _cleanFilePath(voicePath);
      final file = File(cleanPath);
      final exists = file.existsSync();
      final size = exists ? file.lengthSync() : 0;

      debugPrint("Voice path: $voicePath");
      debugPrint("Clean path: $cleanPath");
      debugPrint("Exists: $exists");
      debugPrint("Size: $size");

      if (cleanPath.startsWith('assets/')) {
        try {
          final assetRelative = cleanPath.replaceFirst('assets/', '');
          await _audioPlayer.play(AssetSource(assetRelative));
          playedAudioFile = true;
        } catch (e) {
          debugPrint('Error playing asset audio with AudioPlayer: $e');
        }
      } else if (cleanPath.startsWith('http')) {
        try {
          await _audioPlayer.play(UrlSource(cleanPath));
          playedAudioFile = true;
        } catch (e) {
          debugPrint('Error playing URL audio with AudioPlayer: $e');
        }
      } else {
        if (exists && size > 0) {
          try {
            final testBytes = await file.readAsBytes();
            debugPrint('File readability verified (${testBytes.length} bytes)');

            // Attempt 1: DeviceFileSource
            try {
              await _audioPlayer.play(DeviceFileSource(cleanPath));
              playedAudioFile = true;
              debugPrint('Played local audio file via DeviceFileSource successfully: $cleanPath');
            } catch (e1) {
              debugPrint('DeviceFileSource play error: $e1, trying UrlSource file:// fallback...');
              // Attempt 2: UrlSource file:// scheme
              try {
                await _audioPlayer.play(UrlSource('file://$cleanPath'));
                playedAudioFile = true;
                debugPrint('Played local audio file via UrlSource file:// successfully: $cleanPath');
              } catch (e2) {
                debugPrint('UrlSource file:// error: $e2');
                playedAudioFile = false;
              }
            }
          } catch (readErr) {
            debugPrint('File existence check passed but reading bytes failed: $readErr');
            playedAudioFile = false;
          }
        } else {
          debugPrint('Voice note audio file not found or empty at cleanPath: $cleanPath');
        }
      }
    }

    if (!playedAudioFile) {
      if (voicePath.isEmpty) {
        await NotificationService.speakText(
          storyText.isNotEmpty ? storyText : 'Playing caretaker memory note.',
          lang: langCode,
        );
        final durationSecs = (storyText.length / 10).clamp(4.0, 16.0).toInt();
        Future.delayed(Duration(seconds: durationSecs), () {
          if (_currentlyPlayingId == item.id && _isPlayingVoiceNote) {
            _currentlyPlayingId = null;
            _isPlayingVoiceNote = false;
            notifyListeners();
          }
        });
      } else {
        debugPrint('Audio file failed to play: $voicePath');
        _currentlyPlayingId = null;
        _isPlayingVoiceNote = false;
        notifyListeners();
      }
    }
  }

  Future<void> stopVoiceNote() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    await NotificationService.stopTts();
    _currentlyPlayingId = null;
    _isPlayingVoiceNote = false;
    notifyListeners();
  }

  // --- Favorite Music Playback Engine ---
  Future<void> playMusic(MemoryItem item) async {
    if (_currentlyPlayingMusicId == item.id) {
      if (_musicPlayerState == PlayerState.playing) {
        await pauseMusic();
        return;
      } else if (_musicPlayerState == PlayerState.paused) {
        await resumeMusic();
        return;
      }
    }

    try {
      await stopVoiceNote();
      await _musicPlayer.stop();
    } catch (_) {}

    final audioPath = item.audioPath ?? '';
    if (audioPath.isEmpty) return;

    _currentlyPlayingMusicId = item.id;
    _musicPlayerState = PlayerState.playing;
    notifyListeners();

    final clean = _cleanFilePath(audioPath);
    try {
      if (clean.startsWith('assets/')) {
        await _musicPlayer.play(AssetSource(clean.replaceFirst('assets/', '')));
      } else if (clean.startsWith('http')) {
        await _musicPlayer.play(UrlSource(clean));
      } else {
        final file = File(clean);
        if (file.existsSync()) {
          try {
            await _musicPlayer.play(DeviceFileSource(clean));
          } catch (_) {
            await _musicPlayer.play(UrlSource('file://$clean'));
          }
        }
      }
    } catch (e) {
      debugPrint('Error playing music track: $e');
      _currentlyPlayingMusicId = null;
      _musicPlayerState = PlayerState.stopped;
      notifyListeners();
    }
  }

  Future<void> pauseMusic() async {
    try {
      await _musicPlayer.pause();
      _musicPlayerState = PlayerState.paused;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing music: $e');
    }
  }

  Future<void> resumeMusic() async {
    try {
      await _musicPlayer.resume();
      _musicPlayerState = PlayerState.playing;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming music: $e');
    }
  }

  Future<void> seekMusic(Duration position) async {
    try {
      await _musicPlayer.seek(position);
      _musicPosition = position;
      notifyListeners();
    } catch (e) {
      debugPrint('Error seeking music: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
    _currentlyPlayingMusicId = null;
    _musicPlayerState = PlayerState.stopped;
    _musicPosition = Duration.zero;
    notifyListeners();
  }

  bool isItemOfflineAvailable(MemoryItem item) {
    if (item.category == 'music' || item.mediaType == 'audio') {
      final p = item.audioPath ?? '';
      if (p.isEmpty) return false;
      if (p.startsWith('assets/')) return true;
      final clean = _cleanFilePath(p);
      final file = File(clean);
      return file.existsSync() && file.lengthSync() > 0;
    } else if (item.category == 'places') {
      bool hasAnyLocal = false;
      if (item.photos.isNotEmpty) {
        for (final photo in item.photos) {
          if (photo.startsWith('assets/')) {
            hasAnyLocal = true;
            break;
          }
          final f = File(_cleanFilePath(photo));
          if (f.existsSync() && f.lengthSync() > 0) {
            hasAnyLocal = true;
            break;
          }
        }
      }
      if (item.imagePath.isNotEmpty) {
        if (item.imagePath.startsWith('assets/')) hasAnyLocal = true;
        final f = File(_cleanFilePath(item.imagePath));
        if (f.existsSync() && f.lengthSync() > 0) hasAnyLocal = true;
      }
      if (item.videoPath != null && item.videoPath!.isNotEmpty) {
        final f = File(_cleanFilePath(item.videoPath!));
        if (f.existsSync() && f.lengthSync() > 0) hasAnyLocal = true;
      }
      if (item.audioPath != null && item.audioPath!.isNotEmpty) {
        final f = File(_cleanFilePath(item.audioPath!));
        if (f.existsSync() && f.lengthSync() > 0) hasAnyLocal = true;
      }
      return hasAnyLocal;
    } else {
      // personal memory
      final f = File(_cleanFilePath(item.imagePath));
      return item.imagePath.startsWith('assets/') || (f.existsSync() && f.lengthSync() > 0);
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }
}

