class MemoryItem {
  final String id;
  final String title;
  final String titleKey;
  final String date;
  final String imagePath;
  final String? videoPath;
  final String? audioPath; // For Favourite Music audio files
  final String mediaType; // 'photo', 'video', 'audio'
  final String category; // 'music', 'places', 'personal'
  final String storyNote;
  final String storyKey;
  final String? voiceNotePath;
  final bool isCustom;
  final bool isPublicLandmark;
  final String createdByRole; // 'elder' or 'caretaker'
  final String? artist; // For Favourite Music artist
  final List<String> photos; // For Favourite Places multiple photos
  final String? fileName; // Optional original file name
  final String? duration; // Optional track duration (e.g. 03:45)

  MemoryItem({
    required this.id,
    required this.title,
    this.titleKey = '',
    required this.date,
    required this.imagePath,
    this.videoPath,
    this.audioPath,
    this.mediaType = 'photo',
    this.category = 'personal',
    required this.storyNote,
    this.storyKey = '',
    this.voiceNotePath,
    this.isCustom = false,
    this.isPublicLandmark = true,
    this.createdByRole = 'caretaker',
    this.artist,
    this.photos = const [],
    this.fileName,
    this.duration,
  });

  String get year {
    if (date.contains('-')) {
      return date.split('-').first;
    } else if (date.contains('/')) {
      return date.split('/').last;
    }
    return date;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titleKey': titleKey,
        'date': date,
        'imagePath': imagePath,
        'videoPath': videoPath,
        'audioPath': audioPath,
        'mediaType': mediaType,
        'category': category,
        'storyNote': storyNote,
        'storyKey': storyKey,
        'voiceNotePath': voiceNotePath,
        'isCustom': isCustom,
        'isPublicLandmark': isPublicLandmark,
        'createdByRole': createdByRole,
        'artist': artist,
        'photos': photos,
        'fileName': fileName,
        'duration': duration,
      };

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    final media = json['mediaType'] ?? 'photo';
    final isLandmark = json['isPublicLandmark'] ?? false;
    String cat = json['category'] ?? '';
    if (cat.isEmpty) {
      if (media == 'audio') {
        cat = 'music';
      } else if (isLandmark) {
        cat = 'places';
      } else {
        cat = 'personal';
      }
    }

    final rawPhotos = json['photos'];
    List<String> parsedPhotos = [];
    if (rawPhotos is List) {
      parsedPhotos = rawPhotos.map((e) => e.toString()).toList();
    } else if (json['imagePath'] != null && json['imagePath'].toString().isNotEmpty) {
      parsedPhotos = [json['imagePath'].toString()];
    }

    return MemoryItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      titleKey: json['titleKey'] ?? '',
      date: json['date'] ?? json['year'] ?? '',
      imagePath: json['imagePath'] ?? (parsedPhotos.isNotEmpty ? parsedPhotos.first : ''),
      videoPath: json['videoPath'],
      audioPath: json['audioPath'],
      mediaType: media,
      category: cat,
      storyNote: json['storyNote'] ?? '',
      storyKey: json['storyKey'] ?? '',
      voiceNotePath: json['voiceNotePath'],
      isCustom: json['isCustom'] ?? false,
      isPublicLandmark: isLandmark,
      createdByRole: json['createdByRole'] ?? 'caretaker',
      artist: json['artist'],
      photos: parsedPhotos,
      fileName: json['fileName'],
      duration: json['duration'],
    );
  }

  static List<MemoryItem> getInitialMemories() {
    return [];
  }
}
