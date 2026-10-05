import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/i18n_service.dart';
import '../services/ai_cognitive_engine.dart';
import '../services/schedule_service.dart';
import '../services/auth_service.dart';
import '../models/reminder.dart';
import '../models/memory_item.dart';
import '../services/memory_lane_service.dart';
import '../widgets/elder_card.dart';
import '../widgets/elder_button.dart';
import '../widgets/elder_location_sharing_card.dart';
import '../widgets/elder_step_tracker_card.dart';
import '../services/elder_location_service.dart';
import '../services/step_tracker_service.dart';

import 'games/routine_recall_game_screen.dart';
import 'games/familiar_faces_game_screen.dart';
import 'games/spot_diff_game_screen.dart';
import 'games/remember_now_game_screen.dart';

class PatientHomeScreen extends StatelessWidget {
 final Function(int) onNavigateTab;

 PatientHomeScreen({Key? key, required this.onNavigateTab}) : super(key: key);

 @override
 Widget build(BuildContext context) {
 final i18n = Provider.of<I18nService>(context);
 final aiEngine = Provider.of<AiCognitiveEngine>(context);
 final schedule = Provider.of<ScheduleService>(context);
 final auth = Provider.of<AuthService>(context);
 final memoryService = Provider.of<MemoryLaneService>(context);

 final activeElderId = auth.currentUser?.effectiveElderId ?? '';
 if (activeElderId.isNotEmpty && activeElderId != memoryService.currentElderId) {
 memoryService.setCurrentElderId(activeElderId);
 }

 WidgetsBinding.instance.addPostFrameCallback((_) {
 final loc = Provider.of<ElderLocationService>(context, listen: false);
 if (auth.isElder && activeElderId.isNotEmpty && !loc.isTracking && loc.isSharingActive) {
 loc.initElderTracking(activeElderId);
 }
 final stepTracker = Provider.of<StepTrackerService>(context, listen: false);
 if (auth.isElder && activeElderId.isNotEmpty && !stepTracker.isInitialized) {
 stepTracker.initForElder(activeElderId);
 }
 });

 final targetGlasses = schedule.hydrationTargetGlasses;
 final currentGlasses = schedule.hydrationCurrentGlasses;
 final targetLiters = schedule.hydrationTargetLiters;

 final chi = aiEngine.updateDynamicCHI(
 hydrationCurrentGlasses: currentGlasses,
 hydrationTargetGlasses: targetGlasses,
 reminders: schedule.reminders,
 );
 final status = aiEngine.getScoreStatus(chi);

 final List<Map<String, dynamic>> rangeGuide = [
 {'range': '90–100', 'key': 'doingGreat', 'emoji': '', 'min': 90, 'max': 100},
 {'range': '75–89', 'key': 'doingWell', 'emoji': '', 'min': 75, 'max': 89},
 {'range': '60–74', 'key': 'needsSupport', 'emoji': '', 'min': 60, 'max': 74},
 {'range': '40–59', 'key': 'needsPractice', 'emoji': '', 'min': 40, 'max': 59},
 {'range': '20–39', 'key': 'practiceTogether', 'emoji': '', 'min': 20, 'max': 39},
 {'range': '0–19', 'key': 'extraSupport', 'emoji': '', 'min': 0, 'max': 19},
 ];

 return RefreshIndicator(
 onRefresh: () async {
 final auth = Provider.of<AuthService>(context, listen: false);
 final schedule = Provider.of<ScheduleService>(context, listen: false);
 final memorySvc = Provider.of<MemoryLaneService>(context, listen: false);
 await auth.loadState();
 final activeId = auth.currentUser?.effectiveElderId ?? '';
 if (activeId.isNotEmpty) {
 await auth.fetchElderProfileCloud(activeId);
 await schedule.loadSchedules(elderId: activeId);
 await memorySvc.loadMemories(elderId: activeId);
 if (auth.isElder) {
 final locSvc = Provider.of<ElderLocationService>(context, listen: false);
 await locSvc.refreshElderCurrentLocation();
 final stepTracker = Provider.of<StepTrackerService>(context, listen: false);
 await stepTracker.refreshElderToday();
 }
 }
 },
 child: SingleChildScrollView(
 physics: const AlwaysScrollableScrollPhysics(),
 padding: const EdgeInsets.all(16.0),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Welcome Banner with Cognitive Score
 ElderCard(
 backgroundColor: Color(0xFF61C5B0),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 '${i18n.translate("todayDate")}, 8 ${i18n.translate("septemberDate")} 2026',
 style: TextStyle(color: Color(0xFF1B2824), fontSize: 13, fontWeight: FontWeight.w600),
 softWrap: true,
 ),
 SizedBox(height: 10),
 Text(
 i18n.translate('welcomeMessage'),
 style: const TextStyle(color: Color(0xFF1B2824), fontSize: 22, fontWeight: FontWeight.bold),
 ),
 const SizedBox(height: 16),

 // CHI Score Box (Defaults to 0 for New Accounts)
 Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: Colors.white.withOpacity(0.3),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: Colors.white54),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 i18n.translate('cognitiveHealthIndex'),
 style: const TextStyle(color: Color(0xFF1B2824), fontSize: 12, fontWeight: FontWeight.bold),
 softWrap: true,
 ),
 const SizedBox(height: 2),
 Row(
 children: [
 Text(
 '$chi',
 style: const TextStyle(color: Color(0xFF1B2824), fontSize: 32, fontWeight: FontWeight.w900),
 ),
 const Text(
 ' / 100',
 style: TextStyle(color: Color(0xFF1B2824), fontSize: 16, fontWeight: FontWeight.bold),
 ),
 ],
 ),
 Text(
 '${i18n.translate("statusLabel")} ${status['emoji']} ${i18n.translate(status['key'] ?? 'doingGreat')}',
 style: const TextStyle(color: Color(0xFF1B2824), fontSize: 12, fontWeight: FontWeight.bold),
 softWrap: true,
 ),
 ],
 ),
 ),
 const CircleAvatar(
 radius: 22,
 backgroundColor: Colors.white,
 child: Icon(Icons.psychology, color: Color(0xFF1B2824), size: 26),
 ),
 ],
 ),
 ),
 ],
 ),
 ),

 // Assigned Caregiver Details Banner Card
 Builder(
 builder: (ctx) {
 final authService = Provider.of<AuthService>(ctx);
 final u = authService.currentUser;
 final mId = u?.mappedElderId ?? '';
 final profile = authService.elderProfiles[mId] ?? {};
 final cNameRaw = (profile['caretakerName'] ?? u?.caretakerPhone ?? '').toString().trim();
 final cPhoneRaw = (profile['caretakerPhone'] ?? u?.caretakerPhone ?? '').toString().trim();
 final bool hasCaretaker = cNameRaw.isNotEmpty || cPhoneRaw.isNotEmpty;

 final cName = hasCaretaker ? (cNameRaw.isNotEmpty ? cNameRaw : 'Caregiver') : i18n.translate('notCreatedNotLinked');
 final cPhone = hasCaretaker ? (cPhoneRaw.isNotEmpty ? cPhoneRaw : '+91 9876543210') : i18n.translate('notAvailable');

 return ElderCard(
 backgroundColor: const Color(0xFFE6F4F1),
 border: Border.all(color: Color(0xFF61C5B0), width: 1.5),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 '${i18n.translate("linkedCaregiverNameLabel")} : $cName',
 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 softWrap: true,
 ),
 SizedBox(height: 4),
 Text(
 '${i18n.translate("phoneNumberLabel")} : $cPhone',
 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF23B39B)),
 softWrap: true,
 ),
 ],
 ),
 );
 },
 ),

 // Elder Daily Activity & Step Counter Card
 if (auth.isElder)
 const ElderStepTrackerCard(),

 // Elder Live Location Sharing Status Card
 if (auth.isElder)
 const ElderLocationSharingCard(),



 // Cognitive Index Range Reference Table Card (Visible only for Caregiver)
 if (auth.isCaretaker)
 ElderCard(
 backgroundColor: Colors.white,
 border: Border.all(color: const Color(0xFF61C5B0).withOpacity(0.4)),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 const Icon(Icons.bar_chart, size: 22, color: Color(0xFF23B39B)),
 SizedBox(width: 8),
 Text(
 i18n.translate('cognitiveIndexRange'),
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 ),
 ],
 ),
 SizedBox(height: 4),
 Text(
 i18n.translate('cognitiveHealthDesc'),
 style: const TextStyle(fontSize: 11, color: Colors.grey),
 ),
 const SizedBox(height: 12),

 // Table Header
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 decoration: BoxDecoration(
 color: const Color(0xFF98DACB).withOpacity(0.3),
 borderRadius: BorderRadius.circular(8),
 ),
 child: Row(
 children: [
 SizedBox(
 width: 70,
 child: Text(i18n.translate('score'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B2824))),
 ),
 Expanded(
 child: Text(i18n.translate('statusLevel'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B2824))),
 ),
 ],
 ),
 ),
 const SizedBox(height: 6),

 // Table Rows
 ...rangeGuide.map((item) {
 final isCurrentActive = chi >= item['min'] && chi <= item['max'];
 return Container(
 margin: const EdgeInsets.symmetric(vertical: 2),
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 decoration: BoxDecoration(
 color: isCurrentActive ? const Color(0xFF98DACB) : Colors.transparent,
 borderRadius: BorderRadius.circular(8),
 border: isCurrentActive ? Border.all(color: const Color(0xFF23B39B), width: 1.5) : null,
 ),
 child: Row(
 children: [
 SizedBox(
 width: 70,
 child: Text(
 item['range']!,
 style: TextStyle(
 fontWeight: isCurrentActive ? FontWeight.w900 : FontWeight.bold,
 fontSize: 13,
 color: const Color(0xFF1B2824),
 ),
 ),
 ),
 Expanded(
 child: Row(
 children: [
 Text(item['emoji']!, style: TextStyle(fontSize: 16)),
 SizedBox(width: 8),
 Expanded(
 child: Text(
 i18n.translate(item['key']!),
 style: TextStyle(
 fontWeight: isCurrentActive ? FontWeight.bold : FontWeight.w600,
 fontSize: 13,
 color: const Color(0xFF1B2824),
 ),
 ),
 ),
 if (isCurrentActive)
 Container(
 padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: Color(0xFF23B39B),
 borderRadius: BorderRadius.circular(6),
 ),
 child: Text(i18n.translate('current'), style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }).toList(),
 ],
 ),
 ),





 // Live Scheduled Reminders Preview Card for Elder
 ElderCard(
 backgroundColor: Colors.white,
 border: Border.all(color: Color(0xFF61C5B0).withOpacity(0.4)),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 ' ${i18n.translate("todayScheduleOverview")}',
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 ),
 SizedBox(height: 4),
 InkWell(
 onTap: () => onNavigateTab(2),
 child: Text(
 i18n.translate("viewAll"),
 style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF23B39B)),
 ),
 ),
 SizedBox(height: 10),

 if (schedule.reminders.isEmpty) ...[
 Text(i18n.translate('noRemindersSet'), style: TextStyle(fontSize: 12, color: Colors.grey)),
 ] else ...[
 ...schedule.reminders.take(3).map((r) => Container(
 margin: const EdgeInsets.only(bottom: 6),
 padding: const EdgeInsets.all(10),
 decoration: BoxDecoration(
 color: const Color(0xFF98DACB).withOpacity(0.3),
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: const Color(0xFF98DACB)),
 ),
 child: Row(
 children: [
 Icon(r.type == ReminderType.medicine ? Icons.medication : (r.type == ReminderType.appointment ? Icons.medical_services : Icons.access_time), size: 20, color: const Color(0xFF23B39B)),
 const SizedBox(width: 10),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2824)), softWrap: true, overflow: TextOverflow.visible),
 Text('${r.time} • ${r.detail}', style: const TextStyle(fontSize: 11, color: Color(0xFF1B2824)), softWrap: true, overflow: TextOverflow.visible),
 ],
 ),
 ),
 Icon(
 r.isCompleted ? Icons.check_circle : Icons.circle_outlined,
 color: r.isCompleted ? const Color(0xFF23B39B) : Colors.grey,
 size: 24,
 ),
 ],
 ),
 )).toList(),
 ],
 ],
 ),
 ),

 // Today's Cognitive Exercises Card (Mix of Games & Personal Memories)
 ElderCard(
 backgroundColor: Colors.white,
 border: Border.all(color: const Color(0xFF61C5B0).withOpacity(0.5), width: 1.5),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Row(
 children: [
 const Icon(Icons.psychology, size: 22, color: Color(0xFF23B39B)),
 const SizedBox(width: 8),
 Expanded(
 child: Text(
 i18n.translate('cognitiveExerciseHeader'),
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 softWrap: true,
 ),
 ),
 ],
 ),
 ),
 const SizedBox(width: 6),
 Chip(
 label: Text(
 '${aiEngine.completedExerciseCount}/${aiEngine.dailyExercises.length} ${i18n.translate("completedLabel")}',
 style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
 ),
 backgroundColor: const Color(0xFF23B39B),
 ),
 ],
 ),
 const SizedBox(height: 4),
 Text(
 i18n.translate('dailyCognitiveExercisesDesc'),
 style: const TextStyle(fontSize: 12, color: Colors.black54),
 softWrap: true,
 ),
 const SizedBox(height: 12),

 ...aiEngine.dailyExercises.map((ex) {
 final isDone = ex['isCompleted'] == true;
 final isGame = ex['type'] == 'game';

 return Container(
 margin: const EdgeInsets.only(bottom: 8),
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: isDone
 ? const Color(0xFFF0FDF4)
 : (isGame ? const Color(0xFFE6F4F1) : const Color(0xFFFFFBEB)),
 borderRadius: BorderRadius.circular(14),
 border: Border.all(
 color: isDone
 ? const Color(0xFF23B39B)
 : (isGame ? const Color(0xFF61C5B0) : const Color(0xFFF59E0B)),
 width: isDone ? 1.5 : 1.0,
 ),
 ),
 child: Row(
 children: [
 Text(ex['icon'] as String, style: const TextStyle(fontSize: 24)),
 const SizedBox(width: 10),
 Expanded(
 child: GestureDetector(
 onTap: () {
 if (ex['id'] == 'ex_visual_game') {
 Navigator.push(context, MaterialPageRoute(builder: (_) => const FamiliarFacesGameScreen()));
 } else if (ex['id'] == 'ex_pattern_game') {
 Navigator.push(context, MaterialPageRoute(builder: (_) => const SpotDiffGameScreen()));
 } else {
 onNavigateTab(3); // Navigate to Memory Lane
 }
 },
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Expanded(
 child: Text(
 i18n.translate(ex['titleKey'] as String),
 style: TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 13,
 color: const Color(0xFF1B2824),
 decoration: isDone ? TextDecoration.lineThrough : null,
 ),
 softWrap: true,
 ),
 ),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: isGame ? const Color(0xFF61C5B0) : const Color(0xFFF59E0B),
 borderRadius: BorderRadius.circular(6),
 ),
 child: Text(
 isGame ? i18n.translate('gameBadge') : i18n.translate('memoryBadge'),
 style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
 ),
 ),
 ],
 ),
 const SizedBox(height: 2),
 Text(
 i18n.translate(ex['subtitleKey'] as String),
 style: TextStyle(
 fontSize: 11,
 color: isDone ? Colors.grey : Colors.black87,
 ),
 softWrap: true,
 ),
 ],
 ),
 ),
 ),
 const SizedBox(width: 8),
 IconButton(
 padding: EdgeInsets.zero,
 constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
 icon: Icon(
 isDone ? Icons.check_circle : Icons.circle_outlined,
 color: isDone ? const Color(0xFF23B39B) : Colors.grey,
 size: 26,
 ),
 onPressed: () {
 aiEngine.toggleExerciseCompletion(ex['id'] as String);
 },
 ),
 ],
 ),
 );
 }).toList(),
 ],
 ),
 ),
 ],
 ),
 ),
 );
}
}
