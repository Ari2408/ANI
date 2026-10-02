import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/reminder.dart';

class HiveService {
  static const String remindersBoxName = 'reminders_box';
  static const String settingsBoxName = 'settings_box';
  static const String memoryBoxName = 'memory_lane_box';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Hive.initFlutter();
      await Hive.openBox<Map>(remindersBoxName);
      await Hive.openBox<Map>(settingsBoxName);
      await Hive.openBox<Map>(memoryBoxName);
      _initialized = true;
      debugPrint('HiveService initialized successfully');
    } catch (e) {
      debugPrint('HiveService initialization error: $e');
    }
  }

  static Box<Map> get _remindersBox => Hive.box<Map>(remindersBoxName);
  static Box<Map> get _settingsBox => Hive.box<Map>(settingsBoxName);
  static Box<Map> get _memoryBox => Hive.box<Map>(memoryBoxName);

  /// Clean Elder ID string
  static String _cleanId(String elderId) {
    return elderId.trim().toUpperCase();
  }

  /// Save list of reminders for a specific Elder ID to Hive local box
  static Future<void> saveAllRemindersForElder(String elderId, List<ReminderItem> items) async {
    try {
      await init();
      final key = 'reminders_${_cleanId(elderId)}';
      final jsonList = items.map((i) => i.toJson()).toList();
      await _settingsBox.put(key, {
        'elderId': _cleanId(elderId),
        'reminders': jsonList,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('HiveService saveAllRemindersForElder error: $e');
    }
  }

  /// Load all reminders for a specific Elder ID from Hive local box
  static List<ReminderItem> getRemindersForElder(String elderId) {
    try {
      if (!_initialized || !Hive.isBoxOpen(settingsBoxName)) return [];
      final clean = _cleanId(elderId);
      if (clean.isEmpty) return [];

      final raw = _settingsBox.get('reminders_$clean');
      if (raw != null && raw['reminders'] != null) {
        final list = raw['reminders'] as List;
        return list.map((map) => ReminderItem.fromJson(Map<String, dynamic>.from(map))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('HiveService getRemindersForElder error: $e');
      return [];
    }
  }

  /// Delete/Clear reminders for a specific Elder ID
  static Future<void> clearRemindersForElder(String elderId) async {
    try {
      await init();
      final clean = _cleanId(elderId);
      if (clean.isNotEmpty) {
        await _settingsBox.delete('reminders_$clean');
        await _settingsBox.delete('hydration_$clean');
      }
    } catch (e) {
      debugPrint('HiveService clearRemindersForElder error: $e');
    }
  }

  /// Hydration Target persistence for a specific Elder ID
  static Future<void> saveHydrationStateForElder(String elderId, double targetLiters, int currentGlasses) async {
    try {
      await init();
      final clean = _cleanId(elderId);
      final key = clean.isNotEmpty ? 'hydration_$clean' : 'hydration';
      await _settingsBox.put(key, {
        'targetLiters': targetLiters,
        'currentGlasses': currentGlasses,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('HiveService saveHydrationStateForElder error: $e');
    }
  }

  static Map<String, dynamic>? getHydrationStateForElder(String elderId) {
    try {
      if (!_initialized || !Hive.isBoxOpen(settingsBoxName)) return null;
      final clean = _cleanId(elderId);
      final key = clean.isNotEmpty ? 'hydration_$clean' : 'hydration';
      final raw = _settingsBox.get(key);
      if (raw != null) return Map<String, dynamic>.from(raw);
    } catch (e) {
      debugPrint('HiveService getHydrationStateForElder error: $e');
    }
    return null;
  }

  // --- Legacy Compatibility Methods for WebRTC & Unscoped Calls ---

  /// Save single reminder to Hive local box
  static Future<void> saveReminder(ReminderItem item) async {
    try {
      await init();
      await _remindersBox.put(item.id, item.toJson());
    } catch (e) {
      debugPrint('HiveService saveReminder error: $e');
    }
  }

  /// Save list of reminders to Hive local box
  static Future<void> saveAllReminders(List<ReminderItem> items) async {
    try {
      await init();
      await _remindersBox.clear();
      final Map<String, Map<String, dynamic>> dataMap = {};
      for (var item in items) {
        dataMap[item.id] = item.toJson();
      }
      await _remindersBox.putAll(dataMap);
    } catch (e) {
      debugPrint('HiveService saveAllReminders error: $e');
    }
  }

  /// Load all reminders from Hive local box
  static List<ReminderItem> getReminders() {
    try {
      if (!_initialized || !Hive.isBoxOpen(remindersBoxName)) return [];
      final rawList = _remindersBox.values.toList();
      return rawList.map((map) => ReminderItem.fromJson(Map<String, dynamic>.from(map))).toList();
    } catch (e) {
      debugPrint('HiveService getReminders error: $e');
      return [];
    }
  }

  /// Delete reminder by ID from Hive box
  static Future<void> deleteReminder(String id) async {
    try {
      await init();
      await _remindersBox.delete(id);
    } catch (e) {
      debugPrint('HiveService deleteReminder error: $e');
    }
  }

  /// Mark reminder completion in Hive box
  static Future<void> setReminderCompleted(String id, bool isCompleted) async {
    try {
      await init();
      final raw = _remindersBox.get(id);
      if (raw != null) {
        final Map<String, dynamic> itemMap = Map<String, dynamic>.from(raw);
        itemMap['isCompleted'] = isCompleted;
        await _remindersBox.put(id, itemMap);
      }
    } catch (e) {
      debugPrint('HiveService setReminderCompleted error: $e');
    }
  }

  /// Hydration Target legacy persistence
  static Future<void> saveHydrationState(double targetLiters, int currentGlasses) async {
    try {
      await init();
      await _settingsBox.put('hydration', {
        'targetLiters': targetLiters,
        'currentGlasses': currentGlasses,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('HiveService saveHydrationState error: $e');
    }
  }

  static Map<String, dynamic>? getHydrationState() {
    try {
      if (!_initialized || !Hive.isBoxOpen(settingsBoxName)) return null;
      final raw = _settingsBox.get('hydration');
      if (raw != null) return Map<String, dynamic>.from(raw);
    } catch (e) {
      debugPrint('HiveService getHydrationState error: $e');
    }
    return null;
  }

  /// General clear all for debugging/logout
  static Future<void> clearAllReminders() async {
    try {
      await init();
      await _remindersBox.clear();
    } catch (e) {
      debugPrint('HiveService clearAllReminders error: $e');
    }
  }
}
