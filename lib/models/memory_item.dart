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

    return MemoryItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      titleKey: json['titleKey'] ?? '',
      date: json['date'] ?? json['year'] ?? '',
      imagePath: json['imagePath'] ?? '',
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
    );
  }

  static List<MemoryItem> getInitialMemories() {
    return [];
  }
}
