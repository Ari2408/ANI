import 'dart:io';
import 'package:flutter/foundation.dart';

enum ReminderType { medicine, hydration, appointment, routine }

class ReminderItem {
  final String id;
  final ReminderType type;
  final String title;
  final String time;
  final String detail;
  final String pillsCount;
  final String instructions;
  final String customVoicePath;
  final int voiceMode; // 0: Standard AI TTS, 1: Custom Voice Note, 2: Cloned Family AI Voice
  final String clonedVoiceSamplePath;
  bool isCompleted;
  int reminderAttempt; // 1 = 1st reminder, 2 = 2nd reminder, 3 = 3rd reminder
  final String createdByRole; // 'elder' or 'caretaker'

  ReminderItem({
    required this.id,
    required this.type,
    required this.title,
    required this.time,
    required this.detail,
    this.pillsCount = '1',
    this.instructions = '',
    this.customVoicePath = '',
    this.voiceMode = 0,
    this.clonedVoiceSamplePath = '',
    this.isCompleted = false,
    this.reminderAttempt = 1,
    this.createdByRole = 'caretaker',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'title': title,
        'time': time,
        'detail': detail,
        'pillsCount': pillsCount,
        'instructions': instructions,
        'customVoicePath': customVoicePath,
        'voiceMode': voiceMode,
        'clonedVoiceSamplePath': clonedVoiceSamplePath,
        'isCompleted': isCompleted,
        'reminderAttempt': reminderAttempt,
        'createdByRole': createdByRole,
      };

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    final idStr = (json['id'] ?? '').toString();
    final rawType = json['type'];

    ReminderType resolvedType = ReminderType.medicine;
    if (rawType is int && rawType >= 0 && rawType < ReminderType.values.length) {
      resolvedType = ReminderType.values[rawType];
    } else if (rawType is String) {
      final tLower = rawType.toLowerCase();
      if (tLower.contains('apt') || tLower.contains('appointment')) {
        resolvedType = ReminderType.appointment;
      } else if (tLower.contains('act') || tLower.contains('routine')) {
        resolvedType = ReminderType.routine;
      } else if (tLower.contains('hyd') || tLower.contains('hydration')) {
        resolvedType = ReminderType.hydration;
      }
    }

    final titleLower = (json['title'] ?? '').toString().toLowerCase();
    final detailLower = (json['detail'] ?? '').toString().toLowerCase();
    final isApptText = idStr.startsWith('apt_') ||
        idStr.startsWith('temp_test_apt_') ||
        idStr.contains('apt') ||
        titleLower.contains('doctor') ||
        titleLower.contains('appointment') ||
        titleLower.contains('மருத்துவர்') ||
        titleLower.contains('சந்திப்பு') ||
        titleLower.contains('maruthuva') ||
        titleLower.contains('sandhippu') ||
        detailLower.contains('doctor') ||
        detailLower.contains('appointment') ||
        detailLower.contains('மருத்துவர்') ||
        detailLower.contains('சந்திப்பு');

    if (isApptText) {
      resolvedType = ReminderType.appointment;
    } else if (idStr.startsWith('act_') || idStr.startsWith('temp_test_act_')) {
      resolvedType = ReminderType.routine;
    } else if (idStr.startsWith('hyd_')) {
      resolvedType = ReminderType.hydration;
    }

    final isRoutine = resolvedType == ReminderType.routine ||
        idStr.startsWith('act_') ||
        idStr.contains('act') ||
        idStr.contains('routine') ||
        (json['title'] ?? '').toString().toLowerCase().contains('daily activity') ||
        (json['title'] ?? '').toString().toLowerCase().contains('தினசரி');
    final finalType = isRoutine ? ReminderType.routine : resolvedType;

    final customPath = (json['customVoicePath'] ?? '').toString();
    final rawVm = json['voiceMode'] is int ? json['voiceMode'] as int : 0;
    bool hasValidCustomVoice = false;
    if (!kIsWeb && customPath.isNotEmpty) {
      try {
        hasValidCustomVoice = File(customPath).existsSync();
      } catch (_) {}
    }
    final effectiveVm = hasValidCustomVoice ? 1 : (rawVm == 1 && customPath.isNotEmpty ? 1 : rawVm);

    return ReminderItem(
      id: idStr,
      type: finalType,
      title: json['title'] ?? '',
      time: json['time'] ?? '',
      detail: json['detail'] ?? '',
      pillsCount: json['pillsCount'] ?? '1',
      instructions: json['instructions'] ?? '',
      customVoicePath: customPath,
      voiceMode: effectiveVm,
      clonedVoiceSamplePath: json['clonedVoiceSamplePath'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      reminderAttempt: json['reminderAttempt'] is int ? json['reminderAttempt'] as int : 1,
      createdByRole: json['createdByRole'] ?? 'caretaker',
    );
  }

  /// Starts completely empty for new accounts.
  /// Schedules only appear when configured by the Caretaker.
  static List<ReminderItem> getInitialReminders() {
    return [];
  }
}
