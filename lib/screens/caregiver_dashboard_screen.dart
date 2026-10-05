import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ai_cognitive_engine.dart';
import '../services/auth_service.dart';
import '../services/schedule_service.dart';
import '../services/i18n_service.dart';
import '../models/reminder.dart';
import '../widgets/elder_card.dart';
import '../widgets/elder_button.dart';
import '../widgets/elder_location_map_card.dart';
import '../widgets/caregiver_activity_card.dart';
import '../services/memory_lane_service.dart';
import '../services/elder_location_service.dart';
import '../services/step_tracker_service.dart';
import 'elder_location_screen.dart';
import 'memory_lane_screen.dart';

class CaregiverDashboardScreen extends StatefulWidget {
 const CaregiverDashboardScreen({Key? key}) : super(key: key);

 @override
 State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
 @override
 void initState() {
 super.initState();
 WidgetsBinding.instance.addPostFrameCallback((_) {
 final auth = Provider.of<AuthService>(context, listen: false);
 final mappedId = auth.currentUser?.mappedElderId ?? 'NER-9431';
 final locSvc = Provider.of<ElderLocationService>(context, listen: false);
 locSvc.listenToElderLocation(mappedId);
 final stepTracker = Provider.of<StepTrackerService>(context, listen: false);
 stepTracker.initForCaregiver(mappedId);
 });
 }

 void _triggerSOS() {
 final i18n = Provider.of<I18nService>(context, listen: false);
 showDialog(
 context: context,
 builder: (ctx) => AlertDialog(
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
 backgroundColor: Color(0xFFFFF0F0),
 title: Text(i18n.translate('sosAlertSentTitle'), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
 content: Text(i18n.translate('sosAlertSentDesc')),
 actions: [
 TextButton(
 onPressed: () => Navigator.pop(ctx),
 child: Text(i18n.translate('dismiss'), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
 )
 ],
 ),
 );
 }

 @override
 Widget build(BuildContext context) {
 final aiEngine = Provider.of<AiCognitiveEngine>(context);
 final auth = Provider.of<AuthService>(context);
 final schedule = Provider.of<ScheduleService>(context);
 final memoryService = Provider.of<MemoryLaneService>(context);
 final i18n = Provider.of<I18nService>(context);

 final user = auth.currentUser;
 final chi = aiEngine.updateDynamicCHI(
 hydrationCurrentGlasses: schedule.hydrationCurrentGlasses,
 hydrationTargetGlasses: schedule.hydrationTargetGlasses,
 reminders: schedule.reminders,
 );
 final risk = aiEngine.getRiskLevel();

 final mappedElderId = user?.mappedElderId ?? 'NER-9431';
 schedule.setCurrentElderId(mappedElderId);
 memoryService.setCurrentElderId(mappedElderId);

 final elderProfile = auth.elderProfiles[mappedElderId] ?? {
 'id': mappedElderId,
 'name': 'Elder ($mappedElderId)',
 'age': 72,
 'location': user?.location ?? 'Guwahati, Assam',
 'language': user?.language ?? 'en',
 'emergencyPhone': user?.emergencyPhone ?? '',
 'caretakerPhone': user?.caretakerPhone ?? '',
 };

 final targetGlasses = schedule.hydrationTargetGlasses;
 final currentGlasses = schedule.hydrationCurrentGlasses;
 final targetLiters = schedule.hydrationTargetLiters;

 return RefreshIndicator(
 onRefresh: () async {
 await auth.loadState();
 await schedule.loadSchedules(elderId: mappedElderId);
 final locSvc = Provider.of<ElderLocationService>(context, listen: false);
 await locSvc.refreshLocation(mappedElderId);
 final stepTracker = Provider.of<StepTrackerService>(context, listen: false);
 await stepTracker.fetchCaregiverElderActivity(mappedElderId);
 setState(() {});
 },
 child: ListView(
 padding: const EdgeInsets.all(16),
 children: [
 // 1. Caregiver Header Banner
 ElderCard(
 backgroundColor: const Color(0xFF61C5B0),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 '${i18n.translate("caregiverPortal")}: ${user?.name ?? i18n.translate("healthWorker")}',
 style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
 ),
 SizedBox(height: 2),
 Text(
 '${i18n.translate("mapElderIdLabel")}: $mappedElderId',
 style: const TextStyle(color: Color(0xFFFFE0B2), fontSize: 13, fontWeight: FontWeight.bold),
 ),
 const SizedBox(height: 4),
 Row(
 children: [
 Icon(Icons.cloud_done, color: Colors.white, size: 14),
 SizedBox(width: 4),
 Text(
 i18n.translate('cloudSyncActiveLabel'),
 style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
 ),
 ],
 ),
 ],
 ),
 ),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(
 color: risk == 'low' ? Color(0xFF23B39B) : (risk == 'moderate' ? Color(0xFFF59E0B) : Color(0xFFDC2626)),
 borderRadius: BorderRadius.circular(14),
 ),
 child: Text(
 i18n.translate(risk == 'low' ? 'lowRisk' : (risk == 'moderate' ? 'moderateRisk' : 'highRisk')).toUpperCase(),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
 ),
 ),
 ],
 ),
 ],
 ),
 ),

 // 1.5 Mapped Elder Details Banner Card
 ElderCard(
 backgroundColor: const Color(0xFFFEF3C7),
 border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 '${i18n.translate("linkedElderNameLabel")} : ${elderProfile["name"] ?? "Elder ($mappedElderId)"}',
 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
 softWrap: true,
 ),
 SizedBox(height: 4),
 Text(
 '${i18n.translate("phoneNumberLabel")} : ${elderProfile["emergencyPhone"]?.toString().isNotEmpty == true ? elderProfile["emergencyPhone"] : (elderProfile["phone"]?.toString().isNotEmpty == true ? elderProfile["phone"] : (user?.phone.isNotEmpty == true ? user!.phone : "+91 9876543210"))}',
 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
 softWrap: true,
 ),
 ],
 ),
 ),
 ElevatedButton.icon(
 onPressed: () async {
 await auth.loadState();
 await auth.fetchElderProfileCloud(mappedElderId);
 await schedule.loadSchedules(elderId: mappedElderId);
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(' ${i18n.translate("syncSuccessToast")} ($mappedElderId)')),
 );
 setState(() {});
 },
 icon: Icon(Icons.sync, size: 16, color: Colors.white),
 label: Text(i18n.translate('syncNowBtn'), style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFFD97706),
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 ),
 ],
 ),
 ],
 ),
 ),

 // 1.7 Elder Live GPS Map Location Tracker Card
 ElderLocationMapCard(
 elderName: elderProfile["name"]?.toString() ?? 'Elder ($mappedElderId)',
 elderId: mappedElderId,
 locationText: elderProfile["location"]?.toString() ?? 'Guwahati, Assam',
 phone: elderProfile["emergencyPhone"]?.toString().isNotEmpty == true
 ? elderProfile["emergencyPhone"].toString()
 : (elderProfile["phone"]?.toString().isNotEmpty == true
 ? elderProfile["phone"].toString()
 : (user?.phone.isNotEmpty == true ? user!.phone : "+91 9876543210")),
 onRefreshLocation: () async {
 await auth.loadState();
 await auth.fetchElderProfileCloud(mappedElderId);
 final locSvc = Provider.of<ElderLocationService>(context, listen: false);
 await locSvc.refreshLocation(mappedElderId);
 setState(() {});
 },
 ),

 // 1.75 Elder Live Activity & Step Counter Summary Card
 CaregiverActivityCard(
 elderName: elderProfile["name"]?.toString() ?? 'Elder ($mappedElderId)',
 elderId: mappedElderId,
 ),

 // 1.8 Caregiver Personal Memory Upload Shortcut Card
 ElderCard(
 backgroundColor: const Color(0xFFE6F4F1),
 border: Border.all(color: const Color(0xFF61C5B0), width: 1.5),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Row(
 children: [
 Image.asset(
 'assets/images/camera_icon.png',
 width: 26,
 height: 26,
 errorBuilder: (c, e, s) => const Icon(Icons.photo, size: 22, color: Colors.teal),
 ),
 SizedBox(width: 8),
 Expanded(
 child: Text(
 i18n.translate('elderPersonalMemoryCorner'),
 style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 softWrap: true,
 ),
 ),
 ],
 ),
 ),
 ElevatedButton.icon(
 onPressed: () {
 Navigator.push(
 context,
 MaterialPageRoute(builder: (_) => const MemoryLaneScreen()),
 );
 },
 icon: const Icon(Icons.add_a_photo, size: 16, color: Colors.white),
 label: Text(i18n.translate('addPhotosVideos'), style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF23B39B),
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 ),
 ],
 ),
 const SizedBox(height: 6),
 Text(
 'Uploaded memories push to Cloud Realtime Database for $mappedElderId and immediately appear on the Elder device.',
 style: const TextStyle(fontSize: 11, color: Colors.black87),
 ),
 if (memoryService.memories.where((m) => m.isCustom).isNotEmpty) ...[
 const SizedBox(height: 8),
 Container(
 padding: const EdgeInsets.all(8),
 decoration: BoxDecoration(
 color: Colors.white,
 borderRadius: BorderRadius.circular(10),
 ),
 child: Row(
 children: [
 const Icon(Icons.collections_bookmark, size: 16, color: Color(0xFF23B39B)),
 const SizedBox(width: 6),
 Text(
 '${memoryService.memories.where((m) => m.isCustom).length} Personal Memories Active for $mappedElderId',
 style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 ),
 ],
 ),
 ),
 ],
 ],
 ),
 ),

 // 2. KPI Metric Cards Overview
 Row(
 children: [
 Expanded(
 child: ElderCard(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerLeft,
 child: Text(i18n.translate('cognitiveHealthIndex'), style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
 ),
 const SizedBox(height: 4),
 FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerLeft,
 child: Text('$chi / 100', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF61C5B0))),
 ),
 FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerLeft,
 child: Text(i18n.translate('activeBaseline'), style: TextStyle(fontSize: 11, color: Color(0xFF23B39B), fontWeight: FontWeight.bold)),
 ),
 ],
 ),
 ),
 ),
 const SizedBox(width: 10),
 Expanded(
 child: ElderCard(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerLeft,
 child: Text(i18n.translate('hydrationGoal'), style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
 ),
 SizedBox(height: 4),
 FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerLeft,
 child: Text(
 targetLiters > 0.0 ? '${targetLiters.toStringAsFixed(1)} L ${i18n.translate("targetLabel")}' : '0.0 L ${i18n.translate("targetLabel")}',
 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF61C5B0)),
 ),
 ),
 FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerLeft,
 child: Text(
 targetLiters > 0.0 ? '$currentGlasses/$targetGlasses ${i18n.translate("glasses")}' : i18n.translate('goalNotSet'),
 style: TextStyle(fontSize: 11, color: targetLiters > 0.0 ? const Color(0xFF61C5B0) : Colors.grey, fontWeight: FontWeight.bold),
 ),
 ),
 ],
 ),
 ),
 ),
 ],
 ),

 // 3. Analytics Graph Card (7-Day Cognitive Trendline)
 ElderCard(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Text(
 i18n.translate('cognitiveHealthTrend'),
 style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0)),
 softWrap: true,
 ),
 ),
 SizedBox(width: 8),
 Chip(
 label: Text(i18n.translate('liveAnalytics'), style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
 backgroundColor: Color(0xFF61C5B0),
 ),
 ],
 ),
 SizedBox(height: 4),
 Text(i18n.translate('cognitiveTrendDesc'), style: TextStyle(fontSize: 11, color: Colors.grey)),
 const SizedBox(height: 16),
 SizedBox(
 height: 170,
 child: LineChart(
 LineChartData(
 gridData: const FlGridData(show: true, drawVerticalLine: false),
 titlesData: const FlTitlesData(show: false),
 borderData: FlBorderData(show: false),
 lineBarsData: [
 LineChartBarData(
 spots: aiEngine.chiHistory.asMap().entries.map((e) {
 return FlSpot(e.key.toDouble(), (e.value['score'] as num).toDouble());
 }).toList().followedBy([
 if (aiEngine.chiHistory.length == 1) FlSpot(1.0, chi.toDouble())
 ]).toList(),
 isCurved: true,
 color: const Color(0xFF61C5B0),
 barWidth: 4,
 dotData: const FlDotData(show: true),
 ),
 ],
 ),
 ),
 ),
 ],
 ),
 ),

 // Cognitive Index Range Reference Table Card (For Caregiver Reference)
 ElderCard(
 backgroundColor: Colors.white,
 border: Border.all(color: const Color(0xFF61C5B0).withOpacity(0.4)),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 const Icon(Icons.bar_chart, size: 22, color: Color(0xFF23B39B)),
 const SizedBox(width: 8),
 Text(
 i18n.translate('cognitiveIndexRange'),
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 ),
 ],
 ),
 const SizedBox(height: 4),
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
 child: Text(i18n.translate('score'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B2824))),
 ),
 Expanded(
 child: Text(i18n.translate('statusLevel'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B2824))),
 ),
 ],
 ),
 ),
 const SizedBox(height: 6),

 // Table Rows
 ...[
 {'range': '90–100', 'key': 'doingGreat', 'emoji': '', 'min': 90, 'max': 100},
 {'range': '75–89', 'key': 'doingWell', 'emoji': '', 'min': 75, 'max': 89},
 {'range': '60–74', 'key': 'needsSupport', 'emoji': '', 'min': 60, 'max': 74},
 {'range': '40–59', 'key': 'needsPractice', 'emoji': '', 'min': 40, 'max': 59},
 {'range': '20–39', 'key': 'practiceTogether', 'emoji': '', 'min': 20, 'max': 39},
 {'range': '0–19', 'key': 'extraSupport', 'emoji': '', 'min': 0, 'max': 19},
 ].map((item) {
 final isCurrentActive = chi >= (item['min'] as int) && chi <= (item['max'] as int);
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
 item['range'] as String,
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
 Text(item['emoji'] as String, style: const TextStyle(fontSize: 16)),
 const SizedBox(width: 8),
 Expanded(
 child: Text(
 i18n.translate(item['key'] as String),
 style: TextStyle(
 fontWeight: isCurrentActive ? FontWeight.bold : FontWeight.w600,
 fontSize: 13,
 color: const Color(0xFF1B2824),
 ),
 ),
 ),
 if (isCurrentActive)
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
 decoration: BoxDecoration(
 color: const Color(0xFF23B39B),
 borderRadius: BorderRadius.circular(6),
 ),
 child: Text(i18n.translate('current'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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

 // 4. DISPLAY THAT DAY'S SCHEDULES (Dashboard Summary Card)
 ElderCard(
 backgroundColor: Colors.white,
 border: Border.all(color: const Color(0xFFCDE4E2)),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Row(
 children: [
 const Icon(Icons.calendar_month, size: 22, color: Color(0xFF23B39B)),
 SizedBox(width: 8),
 Expanded(
 child: Text(
 i18n.translate('todayScheduleOverview'),
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0)),
 softWrap: true,
 ),
 ),
 ],
 ),
 ),
 SizedBox(width: 6),
 Chip(
 label: Text('${schedule.reminders.length} ${i18n.translate("activeItems")}', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
 backgroundColor: Color(0xFF23B39B),
 ),
 ],
 ),
 SizedBox(height: 4),
 Text(i18n.translate('todayOverviewDesc'), style: TextStyle(fontSize: 12, color: Colors.grey)),
 const SizedBox(height: 12),

 // Hydration Summary Item
 Container(
 margin: const EdgeInsets.only(bottom: 8),
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: const Color(0xFFE6F4F1),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: const Color(0xFF61C5B0)),
 ),
 child: Row(
 children: [
 const Icon(Icons.water_drop, size: 24, color: Color(0xFF23B39B)),
 SizedBox(width: 10),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(i18n.translate('hydrationGoal'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF61C5B0)), softWrap: true),
 Text(
 targetLiters > 0.0
 ? '$currentGlasses / $targetGlasses ${i18n.translate("glasses")} (${targetLiters.toStringAsFixed(1)} L ${i18n.translate("targetLabel")})'
 : i18n.translate('noHydrationTarget'),
 style: const TextStyle(fontSize: 12, color: Colors.black87),
 softWrap: true,
 ),
 ],
 ),
 ),
 ],
 ),
 ),

 // Medicines, Appointments, and Daily Activities List
 if (schedule.reminders.isEmpty) ...[
 Padding(
 padding: EdgeInsets.all(12),
 child: Text(i18n.translate('noRemindersActive'), style: TextStyle(fontSize: 12, color: Colors.grey)),
 ),
 ] else ...[
 ...schedule.reminders.map((r) => Container(
 margin: const EdgeInsets.only(bottom: 8),
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: r.type == ReminderType.appointment
 ? const Color(0xFFFFFBEB)
 : (r.type == ReminderType.routine ? const Color(0xFFE6F4F1) : Colors.white),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: r.type == ReminderType.appointment
 ? const Color(0xFFF59E0B)
 : (r.type == ReminderType.routine ? const Color(0xFF61C5B0) : const Color(0xFFCDE4E2)),
 ),
 ),
 child: Row(
 children: [
 Icon(
 r.type == ReminderType.medicine
 ? Icons.medication
 : (r.type == ReminderType.appointment ? Icons.medical_services : Icons.access_time),
 size: 22,
 color: const Color(0xFF23B39B),
 ),
 const SizedBox(width: 10),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), softWrap: true, overflow: TextOverflow.visible),
 Text('${r.time} • ${r.detail}', style: const TextStyle(fontSize: 12, color: Colors.black87), softWrap: true, overflow: TextOverflow.visible),
 ],
 ),
 ),
 const SizedBox(width: 6),
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

 // 5. Emergency Alert SOS Button
 Container(
 margin: const EdgeInsets.only(bottom: 16),
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: const Color(0xFFFFF0F0),
 borderRadius: BorderRadius.circular(20),
 border: Border.all(color: Color(0xFFDC2626), width: 2),
 ),
 child: Column(
 children: [
 Text(i18n.translate('emergencyAlert'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
 SizedBox(height: 4),
 Text(i18n.translate('emergencyAlertDesc'), style: TextStyle(fontSize: 13, color: Colors.black54), textAlign: TextAlign.center),
 const SizedBox(height: 12),
 SizedBox(
 width: double.infinity,
 height: 52,
 child: ElevatedButton(
 onPressed: _triggerSOS,
 style: ElevatedButton.styleFrom(
 backgroundColor: Color(0xFFDC2626),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
 ),
 child: Text(i18n.translate('sendSosAlertBtn'), style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
 ),
 ),
 ],
 ),
 ),

 // 6. Export Printable Clinical Report PDF
 ElderButton(
 backgroundColor: Color(0xFF61C5B0),
 label: i18n.translate('exportPdfBtn'),
 icon: Icons.print,
 isOutline: true,
 onPressed: () {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(i18n.translate('exportPdfToast'))),
 );
 },
 ),
 ],
 ),
 );
}
}
