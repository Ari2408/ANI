import'package:flutter/material.dart';

class AiCognitiveEngine extends ChangeNotifier {
 int _currentLevel = 1;
 double _memoryScore = 0.0;
 double _attentionScore = 0.0;
 double _routineScore = 0.0;
 double _adherenceRate = 0.0;

 final List<Map<String, dynamic>> _chiHistory = [
 {'date':'dayLabel','score': 0},
 ];

 final List<Map<String, dynamic>> _dailyExercises = [
 {
'id':'ex_visual_game',
'titleKey':'visualMemoryMatchTitle',
'subtitleKey':'visualMemoryMatchDesc',
'type':'game', //'game'or'memory'
'icon':'',
'isCompleted': false,
 },
 {
'id':'ex_family_memory',
'titleKey':'familyMemoryRecallTitle',
'subtitleKey':'familyMemoryRecallDesc',
'type':'memory', //'game'or'memory'
'icon':'',
'isCompleted': false,
 },
 {
'id':'ex_pattern_game',
'titleKey':'patternSortTitle',
'subtitleKey':'patternSortDesc',
'type':'game',
'icon':'',
'isCompleted': false,
 },
 {
'id':'ex_voice_memory',
'titleKey':'voiceStoryReflectionTitle',
'subtitleKey':'voiceStoryReflectionDesc',
'type':'memory',
'icon':'',
'isCompleted': false,
 },
 ];

 int _lastCalculatedCHI = 0;

 int get currentLevel => _currentLevel;
 double get memoryScore => _memoryScore;
 double get attentionScore => _attentionScore;
 double get routineScore => _routineScore;
 double get adherenceRate => _adherenceRate;
 List<Map<String, dynamic>> get chiHistory => _chiHistory;
 List<Map<String, dynamic>> get dailyExercises => List.unmodifiable(_dailyExercises);
 int get completedExerciseCount => _dailyExercises.where((e) => e['isCompleted'] == true).length;

 void toggleExerciseCompletion(String id) {
 final index = _dailyExercises.indexWhere((e) => e['id'] == id);
 if (index != -1) {
 _dailyExercises[index]['isCompleted'] = !(_dailyExercises[index]['isCompleted'] as bool);
 notifyListeners();
 }
 }

 void markExerciseCompleted(String id) {
 final index = _dailyExercises.indexWhere((e) => e['id'] == id);
 if (index != -1 && _dailyExercises[index]['isCompleted'] != true) {
 _dailyExercises[index]['isCompleted'] = true;
 notifyListeners();
 }
 }

 void resetForNewUser() {
 _lastCalculatedCHI = 0;
 _memoryScore = 0.0;
 _attentionScore = 0.0;
 _routineScore = 0.0;
 _adherenceRate = 0.0;
 for (var ex in _dailyExercises) {
 ex['isCompleted'] = false;
 }
 notifyListeners();
 }

 /// Returns overall Cognitive Health Index (CHI: 0-100)
 int get cognitiveHealthIndex => _lastCalculatedCHI;

 /// Dynamically calculates Cognitive Health Index (CHI: 0-100) based on:
 /// 1. Daily Hydration Target Completion (Max 25 Points).
 /// 2. Medicine Reminders Taken (Max 30 Points).
 /// 3. Daily Routine Items Completed (Max 20 Points).
 /// 4. Daily Cognitive Exercises Completed (Games & Personal Memories Mix) (Max 25 Points).
 int updateDynamicCHI({
 required int hydrationCurrentGlasses,
 required int hydrationTargetGlasses,
 required List<dynamic> reminders,
 }) {
 // 1. Hydration Target Completion (Max 25 Points)
 double hydrationPoints = 0.0;
 if (hydrationTargetGlasses > 0 && hydrationCurrentGlasses > 0) {
 final ratio = (hydrationCurrentGlasses / hydrationTargetGlasses).clamp(0.0, 1.0);
 hydrationPoints = ratio * 25.0;
 }

 // Filter Reminders
 final medicineList = reminders.where((r) => r.type.toString().contains('medicine')).toList();
 final routineList = reminders.where((r) => r.type.toString().contains('routine')).toList();

 // 2. Medicine Adherence Score (Max 30 Points)
 double medicinePoints = 0.0;
 if (medicineList.isNotEmpty) {
 double totalEarned = 0.0;
 for (final med in medicineList) {
 if (med.isCompleted == true) {
 final attempt = (med.reminderAttempt as int? ?? 1).clamp(1, 3);
 if (attempt == 1) {
 totalEarned += 1.0;
 } else if (attempt == 2) {
 totalEarned += 0.65;
 } else {
 totalEarned += 0.35;
 }
 }
 }
 medicinePoints = (totalEarned / medicineList.length) * 30.0;
 }

 // 3. Daily Routine Completion Score (Max 20 Points)
 double routinePoints = 0.0;
 if (routineList.isNotEmpty) {
 double totalEarned = 0.0;
 for (final routine in routineList) {
 if (routine.isCompleted == true) {
 final attempt = (routine.reminderAttempt as int? ?? 1).clamp(1, 3);
 if (attempt == 1) {
 totalEarned += 1.0;
 } else if (attempt == 2) {
 totalEarned += 0.65;
 } else {
 totalEarned += 0.35;
 }
 }
 }
 routinePoints = (totalEarned / routineList.length) * 20.0;
 }

 // 4. Daily Cognitive Exercises Completion (Games & Personal Memories Mix) (Max 25 Points)
 double exercisePoints = 0.0;
 if (_dailyExercises.isNotEmpty) {
 final completed = _dailyExercises.where((e) => e['isCompleted'] == true).length;
 exercisePoints = (completed / _dailyExercises.length) * 25.0;
 }

 final gameBonus = ((0.5 * _memoryScore) + (0.5 * _attentionScore)) * 0.05;

 // Calculate total score (0 to 100)
 final totalScore = (hydrationPoints + medicinePoints + routinePoints + exercisePoints + gameBonus).round().clamp(0, 100);

 _lastCalculatedCHI = totalScore;
 return totalScore;
 }

 /// Get status label, emoji, and theme color for score range
 Map<String, dynamic> getScoreStatus(int score) {
 if (score >= 90) {
 return {
'range':'90–100',
'key':'doingGreat',
'label':'Doing Great',
'emoji':'',
'color': const Color(0xFF10B981),
 };
 } else if (score >= 75) {
 return {
'range':'75–89',
'key':'doingWell',
'label':'Doing Well',
'emoji':'',
'color': const Color(0xFF22C55E),
 };
 } else if (score >= 60) {
 return {
'range':'60–74',
'key':'needsSupport',
'label':'Needs a Little Support',
'emoji':'',
'color': const Color(0xFFEAB308),
 };
 } else if (score >= 40) {
 return {
'range':'40–59',
'key':'needsPractice',
'label':'Needs More Practice',
'emoji':'',
'color': const Color(0xFFF97316),
 };
 } else if (score >= 20) {
 return {
'range':'20–39',
'key':'practiceTogether',
'label':"Let's Practice Together",
'emoji':'',
'color': const Color(0xFF3B82F6),
 };
 } else {
 return {
'range':'0–19',
'key':'extraSupport',
'label':'Needs Extra Support',
'emoji':'',
'color': const Color(0xFF6B7280),
 };
 }
 }

 /// Process game session result and update Cognitive Index
 void recordSessionResult({
 required String gameType,
 required int timeSeconds,
 required int mistakes,
 required double accuracyPct,
 }) {
 if (gameType =='memory') {
 markExerciseCompleted('ex_visual_game');
 _memoryScore = _memoryScore == 0.0
 ? accuracyPct.clamp(10.0, 100.0)
 : (_memoryScore + (accuracyPct > 80 ? 5 : -2)).clamp(10.0, 100.0);
 } else if (gameType =='routine') {
 _routineScore = _routineScore == 0.0
 ? (100.0 - (mistakes * 15)).clamp(10.0, 100.0)
 : (_routineScore + (mistakes == 0 ? 5 : -2)).clamp(10.0, 100.0);
 } else if (gameType =='pattern') {
 markExerciseCompleted('ex_pattern_game');
 _attentionScore = _attentionScore == 0.0
 ? accuracyPct.clamp(10.0, 100.0)
 : (_attentionScore + (accuracyPct > 75 ? 5 : -2)).clamp(10.0, 100.0);
 }

 _adherenceRate = (_adherenceRate + 10.0).clamp(0.0, 100.0);

 // Level adjustment
 if (accuracyPct >= 85 && mistakes <= 1) {
 if (_currentLevel < 5) _currentLevel++;
 } else if (accuracyPct < 50 || mistakes >= 3) {
 if (_currentLevel > 1) _currentLevel--;
 }

 // Append to trend
 _chiHistory.add({
'date':'todayLabel',
'score': cognitiveHealthIndex,
 });
 if (_chiHistory.length > 14) _chiHistory.removeAt(0);

 notifyListeners();
 }

 String getRiskLevel() {
 final chi = cognitiveHealthIndex;
 if (chi >= 75) return'low';
 if (chi >= 55) return'moderate';
 return'high';
 }
}
