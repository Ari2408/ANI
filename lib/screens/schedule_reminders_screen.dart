import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import '../services/i18n_service.dart';
import '../services/schedule_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/reminder.dart';
import '../widgets/elder_card.dart';
import '../widgets/elder_button.dart';
import 'webrtc_pairing_screen.dart';

class ScheduleRemindersScreen extends StatefulWidget {
 const ScheduleRemindersScreen({Key? key}) : super(key: key);

 @override
 State<ScheduleRemindersScreen> createState() => _ScheduleRemindersScreenState();
}

class _ScheduleRemindersScreenState extends State<ScheduleRemindersScreen> {
 // Selected Section Index (null = 4 Grid Boxes Dashboard, 0 = Hydration, 1 = Medicine, 2 = Appointments, 3 = Activities)
 int? _selectedSection;
 // Active Reminder Filter (0 = All, 1 = Medicine, 2 = Doctor, 3 = Routine, 4 = Pending, 5 = Done)
 int _remindersFilterIndex = 0;
 // Selected Date Filter for Reminders Calendar
 DateTime? _selectedFilterDate;
 int _selectedProgressDayIndex = DateTime.now().weekday - 1;

 // Medicine Image Upload Path
 String? _medicineImagePath;

 // Hydration Input Controller (starts empty, synced with ScheduleService)
 final _litersCtrl = TextEditingController();
 bool _litersCtrlInitialized = false;

 // Medicine Reminder Form Controllers
 final _medNameCtrl = TextEditingController();
 final _medPillsCtrl = TextEditingController(text: '1');
 final _medTimeCtrl = TextEditingController(text: '08:00 AM');
 String _mealInstructionKey = 'mealBreakfast';

 // Appointment Form Controllers
 final _aptTitleCtrl = TextEditingController();
 final _aptDateTimeCtrl = TextEditingController(text: '15 Sep 2026, 10:30 AM');
 final _aptLocationCtrl = TextEditingController();

 // Daily Activity Form Controllers
 final _actTitleCtrl = TextEditingController();
 final _actTimeCtrl = TextEditingController(text: '07:00 AM');
 final _actDetailsCtrl = TextEditingController();

 // Custom & Cloned Voice Mode State (0 = Standard AI Voice, 1 = Custom Voice Note, 2 = Cloned Family AI Voice, 3 = Select from Saved Ones)
 int _voiceMode = 0;
 bool _isRecordingVoice = false;
 String? _recordingMealType;
 int _recordSeconds = 0;
 String? _customVoicePath;
 Timer? _recordTimer;

 bool _isRecordingSample = false;
 int _sampleRecordSeconds = 0;
 String? _clonedVoiceSamplePath;
 Timer? _sampleRecordTimer;

 final AudioRecorder _audioRecorder = AudioRecorder();
 final AudioPlayer _audioPlayer = AudioPlayer();

 final List<String> _mealInstructionKeys = [
 'mealBreakfastBefore',
 'mealBreakfast',
 'mealLunch',
 'mealLunchAfter',
 'mealDinnerBefore',
 'mealDinner',
 'mealSleep',
 ];

 @override
 void didChangeDependencies() {
 super.didChangeDependencies();
 if (!_litersCtrlInitialized) {
 final schedule = Provider.of<ScheduleService>(context, listen: false);
 if (schedule.hydrationTargetLiters > 0) {
 _litersCtrl.text = schedule.hydrationTargetLiters.toStringAsFixed(1);
 }
 _litersCtrlInitialized = true;
 }
 }

 @override
 void dispose() {
 _recordTimer?.cancel();
 _sampleRecordTimer?.cancel();
 _audioRecorder.dispose();
 _audioPlayer.dispose();
 _litersCtrl.dispose();
 _medNameCtrl.dispose();
 _medPillsCtrl.dispose();
 _medTimeCtrl.dispose();
 _aptTitleCtrl.dispose();
 _aptDateTimeCtrl.dispose();
 _aptLocationCtrl.dispose();
 _actTitleCtrl.dispose();
 _actTimeCtrl.dispose();
 _actDetailsCtrl.dispose();
 super.dispose();
 }

 Future<void> _startRecordingCustomVoice() async {
 try {
 final hasPermission = await _audioRecorder.hasPermission();
 if (!hasPermission) {
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(Provider.of<I18nService>(context, listen: false).translate('micPermReqVoice'))),
 );
 }
 return;
 }

 final dir = await getApplicationDocumentsDirectory();
 final path = '${dir.path}/custom_reminder_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

 await _audioRecorder.start(
 const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
 path: path,
 );

 setState(() {
 _isRecordingVoice = true;
 _recordSeconds = 0;
 _customVoicePath = path;
 });

 _recordTimer?.cancel();
 _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
 if (mounted) {
 setState(() {
 _recordSeconds++;
 });
 }
 });
 } catch (e) {
 debugPrint('Error starting custom voice recording: $e');
 }
 }

 Future<void> _stopRecordingCustomVoice() async {
 _recordTimer?.cancel();
 _recordTimer = null;
 try {
 final path = await _audioRecorder.stop();
 setState(() {
 _isRecordingVoice = false;
 if (path != null && path.isNotEmpty && File(path).existsSync()) {
 _customVoicePath = path;
 _voiceMode = 1;
 }
 });
 } catch (e) {
 debugPrint('Error stopping custom voice recording: $e');
 setState(() {
 _isRecordingVoice = false;
 });
 }
 }

 Future<void> _playPreviewCustomVoice() async {
 if (_customVoicePath != null && File(_customVoicePath!).existsSync()) {
 try {
 await _audioPlayer.stop();
 await _audioPlayer.play(DeviceFileSource(_customVoicePath!));
 } catch (e) {
 debugPrint('Error playing preview custom voice: $e');
 }
 }
 }

 Future<void> _startRecordingMealVoice(String mealType) async {
 try {
 final hasPermission = await _audioRecorder.hasPermission();
 if (!hasPermission) {
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(Provider.of<I18nService>(context, listen: false).translate('micPermReqVoice'))),
 );
 }
 return;
 }

 final dir = await getApplicationDocumentsDirectory();
 final path = '${dir.path}/meal_voice_${mealType}_${DateTime.now().millisecondsSinceEpoch}.m4a';

 await _audioRecorder.start(
 const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
 path: path,
 );

 setState(() {
 _isRecordingVoice = true;
 _recordingMealType = mealType;
 _recordSeconds = 0;
 });

 _recordTimer?.cancel();
 _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
 if (mounted) {
 setState(() {
 _recordSeconds++;
 });
 }
 });
 } catch (e) {
 debugPrint('Error starting meal voice recording: $e');
 }
 }

 Future<void> _stopRecordingMealVoice(ScheduleService schedule) async {
 _recordTimer?.cancel();
 _recordTimer = null;
 final currentMealType = _recordingMealType;
 try {
 final path = await _audioRecorder.stop();
 if (currentMealType != null && path != null && path.isNotEmpty && File(path).existsSync()) {
 await schedule.setMealVoicePath(currentMealType, path);
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(Provider.of<I18nService>(context, listen: false).translate('itemSaved'))),
 );
 }
 }
 } catch (e) {
 debugPrint('Error stopping meal voice recording: $e');
 } finally {
 if (mounted) {
 setState(() {
 _isRecordingVoice = false;
 _recordingMealType = null;
 });
 }
 }
 }

 Future<void> _playMealVoice(String path) async {
 if (File(path).existsSync()) {
 try {
 await _audioPlayer.stop();
 await _audioPlayer.play(DeviceFileSource(path));
 } catch (e) {
 debugPrint('Error playing meal voice recording: $e');
 }
 }
 }

 Future<void> _startRecordingGrandsonVoice() async {
 try {
 final hasPermission = await _audioRecorder.hasPermission();
 if (!hasPermission) {
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(Provider.of<I18nService>(context, listen: false).translate('micPermReqVoice'))),
 );
 }
 return;
 }

 final dir = await getApplicationDocumentsDirectory();
 final path = '${dir.path}/grandson_voice_sample_${DateTime.now().millisecondsSinceEpoch}.m4a';

 await _audioRecorder.start(
 const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
 path: path,
 );

 setState(() {
 _isRecordingSample = true;
 _sampleRecordSeconds = 0;
 _clonedVoiceSamplePath = path;
 });

 _sampleRecordTimer?.cancel();
 _sampleRecordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
 if (mounted) {
 setState(() {
 _sampleRecordSeconds++;
 });
 if (_sampleRecordSeconds >= 5) {
 _stopRecordingGrandsonVoice();
 }
 }
 });
 } catch (e) {
 debugPrint('Error starting grandson voice sample recording: $e');
 }
 }

 Future<void> _stopRecordingGrandsonVoice() async {
 _sampleRecordTimer?.cancel();
 _sampleRecordTimer = null;
 try {
 final path = await _audioRecorder.stop();
 setState(() {
 _isRecordingSample = false;
 if (path != null && path.isNotEmpty && File(path).existsSync()) {
 _clonedVoiceSamplePath = path;
 }
 });
 } catch (e) {
 debugPrint('Error stopping grandson voice sample recording: $e');
 setState(() {
 _isRecordingSample = false;
 });
 }
 }

 Future<void> _playPreviewGrandsonVoice() async {
 if (_clonedVoiceSamplePath != null && File(_clonedVoiceSamplePath!).existsSync()) {
 try {
 await _audioPlayer.stop();
 await _audioPlayer.play(DeviceFileSource(_clonedVoiceSamplePath!));
 } catch (e) {
 debugPrint('Error playing preview grandson voice sample: $e');
 }
 }
 }

 Future<void> _pickMedicineImageFromGallery() async {
 try {
 final picker = ImagePicker();
 final XFile? image = await picker.pickImage(source: ImageSource.gallery);
 if (image != null) {
 setState(() {
 _medicineImagePath = image.path;
 });
 }
 } catch (e) {
 debugPrint('Error picking medicine image from gallery: $e');
 }
 }

 Widget _buildVoiceRecorderCard(I18nService i18n, {bool showGrandsonOption = true}) {
 final effectiveVoiceMode = (!showGrandsonOption) ? 1 : _voiceMode;
 return Container(
 padding: const EdgeInsets.all(12),
 margin: const EdgeInsets.symmetric(vertical: 8),
 decoration: BoxDecoration(
 color: effectiveVoiceMode == 1
 ? const Color(0xFFFFFBEB)
 : (effectiveVoiceMode == 2
 ? const Color(0xFFEEF2FF)
 : (effectiveVoiceMode == 3 ? const Color(0xFFFAF5FF) : const Color(0xFFF9FAFB))),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: effectiveVoiceMode == 1
 ? const Color(0xFFF59E0B)
 : (effectiveVoiceMode == 2
 ? const Color(0xFF6366F1)
 : (effectiveVoiceMode == 3 ? const Color(0xFF9333EA) : Colors.grey.shade300)),
 width: 1.5,
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 i18n.translate('voiceOptionTitle'),
 style: TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 14,
 color: effectiveVoiceMode == 1
 ? const Color(0xFFB45309)
 : (effectiveVoiceMode == 2
 ? const Color(0xFF3730A3)
 : (effectiveVoiceMode == 3 ? const Color(0xFF6B21A8) : const Color(0xFF374151))),
 ),
 ),
 const SizedBox(height: 10),

 // Voice Mode Selection Cards
 Column(
 children: [
 // Option 1: Direct Custom Recorded Voice Note
 GestureDetector(
 onTap: () => setState(() => _voiceMode = 1),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
 margin: const EdgeInsets.only(bottom: 6),
 decoration: BoxDecoration(
 color: effectiveVoiceMode == 1 ? const Color(0xFFFEF3C7) : Colors.white,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: effectiveVoiceMode == 1 ? const Color(0xFFF59E0B) : Colors.grey.shade300),
 ),
 child: Row(
 children: [
 Radio<int>(
 value: 1,
 groupValue: effectiveVoiceMode,
 activeColor: const Color(0xFFD97706),
 onChanged: (val) => setState(() => _voiceMode = val!),
 ),
 Expanded(
 child: Text(
 i18n.translate('option1DirectVoice'),
 style: TextStyle(
 fontSize: 12,
 fontWeight: effectiveVoiceMode == 1 ? FontWeight.bold : FontWeight.normal,
 color: const Color(0xFF92400E),
 ),
 ),
 ),
 ],
 ),
 ),
 ),

 // Option 2: AI Voice Cloned from Family (Grandson's Voice) - Hidden for Routine
 if (showGrandsonOption)
 GestureDetector(
 onTap: () => setState(() => _voiceMode = 2),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
 margin: const EdgeInsets.only(bottom: 6),
 decoration: BoxDecoration(
 color: effectiveVoiceMode == 2 ? const Color(0xFFE0E7FF) : Colors.white,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: effectiveVoiceMode == 2 ? const Color(0xFF6366F1) : Colors.grey.shade300),
 ),
 child: Row(
 children: [
 Radio<int>(
 value: 2,
 groupValue: effectiveVoiceMode,
 activeColor: const Color(0xFF4F46E5),
 onChanged: (val) => setState(() => _voiceMode = val!),
 ),
 Expanded(
 child: Text(
 i18n.translate('option2ClonedAiVoice'),
 style: TextStyle(
 fontSize: 12,
 fontWeight: effectiveVoiceMode == 2 ? FontWeight.bold : FontWeight.normal,
 color: const Color(0xFF3730A3),
 ),
 ),
 ),
 ],
 ),
 ),
 ),

 // Option 3 / Default: Standard AI Voice (System TTS) - Hidden for Routine
 if (showGrandsonOption)
 GestureDetector(
 onTap: () => setState(() => _voiceMode = 0),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
 margin: const EdgeInsets.only(bottom: 6),
 decoration: BoxDecoration(
 color: effectiveVoiceMode == 0 ? const Color(0xFFF3F4F6) : Colors.white,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: effectiveVoiceMode == 0 ? const Color(0xFF9CA3AF) : Colors.grey.shade300),
 ),
 child: Row(
 children: [
 Radio<int>(
 value: 0,
 groupValue: effectiveVoiceMode,
 activeColor: const Color(0xFF4B5563),
 onChanged: (val) => setState(() => _voiceMode = val!),
 ),
 Expanded(
 child: Text(
 i18n.translate('option3StandardAiVoice'),
 style: TextStyle(
 fontSize: 12,
 fontWeight: effectiveVoiceMode == 0 ? FontWeight.bold : FontWeight.normal,
 color: const Color(0xFF374151),
 ),
 ),
 ),
 ],
 ),
 ),
 ),

 // Option 4: Select from Saved Ones 
 GestureDetector(
 onTap: () => setState(() => _voiceMode = 3),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
 decoration: BoxDecoration(
 color: effectiveVoiceMode == 3 ? const Color(0xFFF3E8FF) : Colors.white,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: effectiveVoiceMode == 3 ? const Color(0xFF9333EA) : Colors.grey.shade300),
 ),
 child: Row(
 children: [
 Radio<int>(
 value: 3,
 groupValue: effectiveVoiceMode,
 activeColor: const Color(0xFF9333EA),
 onChanged: (val) => setState(() => _voiceMode = val!),
 ),
 Expanded(
 child: Text(
 i18n.translate('option4SavedVoice'),
 style: TextStyle(
 fontSize: 12,
 fontWeight: effectiveVoiceMode == 3 ? FontWeight.bold : FontWeight.normal,
 color: const Color(0xFF6B21A8),
 ),
 ),
 ),
 ],
 ),
 ),
 ),
 ],
 ),

 // Option 1 Panel: Direct Custom Voice Recorder
 if (effectiveVoiceMode == 1) ...[
 const SizedBox(height: 10),
 if (_isRecordingVoice && _recordingMealType == null) ...[
 ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: Colors.red,
 minimumSize: const Size(double.infinity, 44),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 icon: const Icon(Icons.stop, color: Colors.white),
 label: Text(
 i18n.translate('recordingCustomVoice').replaceAll('{sec}', '$_recordSeconds'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
 ),
 onPressed: _stopRecordingCustomVoice,
 ),
 ] else ...[
 Row(
 children: [
 Expanded(
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFFD97706),
 minimumSize: const Size(0, 44),
 padding: const EdgeInsets.symmetric(horizontal: 6),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 icon: const Icon(Icons.mic, color: Colors.white, size: 18),
 label: FittedBox(
 fit: BoxFit.scaleDown,
 child: Text(
 _customVoicePath != null && File(_customVoicePath!).existsSync()
 ? i18n.translate('reRecordVoiceBtn')
 : i18n.translate('recordCustomVoiceBtn'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
 ),
 ),
 onPressed: _startRecordingCustomVoice,
 ),
 ),
 if (_customVoicePath != null && File(_customVoicePath!).existsSync()) ...[
 const SizedBox(width: 8),
 Expanded(
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF059669),
 minimumSize: const Size(0, 44),
 padding: const EdgeInsets.symmetric(horizontal: 6),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
 label: FittedBox(
 fit: BoxFit.scaleDown,
 child: Text(
 i18n.translate('playPreviewBtn'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
 ),
 ),
 onPressed: _playPreviewCustomVoice,
 ),
 ),
 ],
 ],
 ),
 if (_customVoicePath != null && File(_customVoicePath!).existsSync()) ...[
 const SizedBox(height: 6),
 Text(
 i18n.translate('customVoiceSuccess'),
 style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold),
 ),
 ],
 ],
 ],

 // Option 2 Panel: Cloned Family Grandson Voice Sample Recorder
 if (showGrandsonOption && effectiveVoiceMode == 2) ...[
 const SizedBox(height: 10),
 if (_isRecordingSample) ...[
 ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: Colors.red,
 minimumSize: const Size(double.infinity, 44),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 icon: const Icon(Icons.stop, color: Colors.white),
 label: Text(
 i18n.translate('recordingGrandsonVoice').replaceAll('{sec}', '$_sampleRecordSeconds'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
 ),
 onPressed: _stopRecordingGrandsonVoice,
 ),
 ] else ...[
 Row(
 children: [
 Expanded(
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF4F46E5),
 minimumSize: const Size(0, 44),
 padding: const EdgeInsets.symmetric(horizontal: 6),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 icon: const Icon(Icons.record_voice_over, color: Colors.white, size: 18),
 label: FittedBox(
 fit: BoxFit.scaleDown,
 child: Text(
 _clonedVoiceSamplePath != null && File(_clonedVoiceSamplePath!).existsSync()
 ? i18n.translate('reRecordVoiceBtn')
 : i18n.translate('recordGrandsonVoiceBtn'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
 ),
 ),
 onPressed: _startRecordingGrandsonVoice,
 ),
 ),
 if (_clonedVoiceSamplePath != null && File(_clonedVoiceSamplePath!).existsSync()) ...[
 const SizedBox(width: 8),
 Expanded(
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF059669),
 minimumSize: const Size(0, 44),
 padding: const EdgeInsets.symmetric(horizontal: 6),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
 label: FittedBox(
 fit: BoxFit.scaleDown,
 child: Text(
 i18n.translate('playPreviewBtn'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
 ),
 ),
 onPressed: _playPreviewGrandsonVoice,
 ),
 ),
 ],
 ],
 ),
 if (_clonedVoiceSamplePath != null && File(_clonedVoiceSamplePath!).existsSync()) ...[
 const SizedBox(height: 6),
 Text(
 i18n.translate('grandsonVoiceSuccess'),
 style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold),
 ),
 ],
 ],
 ],

 // Option 4 Panel: Select from Saved Voice Records
 if (effectiveVoiceMode == 3) ...[
 const SizedBox(height: 10),
 Builder(
 builder: (context) {
 final schedule = Provider.of<ScheduleService>(context, listen: false);
 final isTamil = i18n.currentLang == 'ta';
 final savedRecords = schedule.getSavedVoiceRecords(i18n);
 if (savedRecords.isEmpty) {
 return Container(
 width: double.infinity,
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: Colors.purple.shade50,
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: Colors.purple.shade200),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 i18n.translate('noSavedVoicesFound'),
 style: TextStyle(fontSize: 13, color: Colors.purple.shade900, fontWeight: FontWeight.bold),
 ),
 const SizedBox(height: 4),
 Text(
 isTamil
 ? 'உணவு நேர குரல் குறிப்புகள் பகுதியில் காலை, மதிய அல்லது இரவு உணவிற்கான குரலை பதிவு செய்து இங்கே தேர்ந்தெடுக்கலாம்.'
 : 'Record a custom voice note for Breakfast, Lunch, or Dinner in the Voice Notes section to select it here.',
 style: TextStyle(fontSize: 11, color: Colors.purple.shade700),
 ),
 ],
 ),
 );
 }

 String? selectedLabel;
 savedRecords.forEach((label, path) {
 if (path == _customVoicePath) {
 selectedLabel = label;
 }
 });

 // Smart meal voice note matching based on selected meal timing
 if (selectedLabel == null && savedRecords.isNotEmpty) {
 final timing = _mealInstructionKey.toLowerCase();
 for (var entry in savedRecords.entries) {
 final kLower = entry.key.toLowerCase();
 if ((timing.contains('breakfast') || timing.contains('morning')) && kLower.contains('breakfast')) {
 selectedLabel = entry.key;
 _customVoicePath = entry.value;
 break;
 } else if ((timing.contains('lunch') || timing.contains('afternoon')) && kLower.contains('lunch')) {
 selectedLabel = entry.key;
 _customVoicePath = entry.value;
 break;
 } else if ((timing.contains('dinner') || timing.contains('night') || timing.contains('sleep')) && kLower.contains('dinner')) {
 selectedLabel = entry.key;
 _customVoicePath = entry.value;
 break;
 }
 }
 if (selectedLabel == null) {
 selectedLabel = savedRecords.keys.first;
 _customVoicePath = savedRecords[selectedLabel];
 }
 }

 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
 decoration: BoxDecoration(
 color: Colors.white,
 borderRadius: BorderRadius.circular(8),
 border: Border.all(color: const Color(0xFF9333EA)),
 ),
 child: DropdownButtonHideUnderline(
 child: DropdownButton<String>(
 isExpanded: true,
 value: selectedLabel,
 hint: Text(i18n.translate('selectSavedVoiceHint')),
 items: savedRecords.entries.map((entry) {
 return DropdownMenuItem<String>(
 value: entry.key,
 child: Text(
 entry.key,
 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4C1D95)),
 overflow: TextOverflow.ellipsis,
 ),
 );
 }).toList(),
 onChanged: (val) {
 if (val != null && savedRecords.containsKey(val)) {
 setState(() {
 _customVoicePath = savedRecords[val];
 });
 }
 },
 ),
 ),
 ),
 const SizedBox(height: 8),
 if (_customVoicePath != null && File(_customVoicePath!).existsSync()) ...[
 ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF9333EA),
 minimumSize: const Size(double.infinity, 38),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
 ),
 icon: const Icon(Icons.volume_up, color: Colors.white, size: 18),
 label: Text(
 i18n.translate('playAudioPreview'),
 style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
 ),
 onPressed: _playPreviewCustomVoice,
 ),
 ],
 ],
 );
 },
 ),
 ],
 ],
 ),
 );
 }

 String _formatReminderDateTimeDisplay(String rawTime) {
 if (rawTime.trim().isEmpty) return '';

 final t = rawTime.trim();
 final hasDateInText = t.contains('Jan') ||
 t.contains('Feb') ||
 t.contains('Mar') ||
 t.contains('Apr') ||
 t.contains('May') ||
 t.contains('Jun') ||
 t.contains('Jul') ||
 t.contains('Aug') ||
 t.contains('Sep') ||
 t.contains('Oct') ||
 t.contains('Nov') ||
 t.contains('Dec') ||
 t.contains('-') ||
 t.contains('/');

 if (hasDateInText) {
 return ' $t';
 } else {
 final now = DateTime.now();
 final todayStr = "${now.day} ${_getMonthName(now.month)} ${now.year}";
 return ' $todayStr • $t';
 }
 }

 void _selectTime(TextEditingController controller) async {
 final TimeOfDay? pickedTime = await showTimePicker(
 context: context,
 initialTime: TimeOfDay.now(),
 );
 if (pickedTime != null) {
 final formattedTime = pickedTime.format(context);
 setState(() {
 controller.text = formattedTime;
 });
 }
 }

 void _selectDateTime(TextEditingController controller) async {
 final DateTime? pickedDate = await showDatePicker(
 context: context,
 initialDate: DateTime.now().add(const Duration(days: 1)),
 firstDate: DateTime.now(),
 lastDate: DateTime.now().add(const Duration(days: 365)),
 );
 if (pickedDate != null) {
 final TimeOfDay? pickedTime = await showTimePicker(
 context: context,
 initialTime: const TimeOfDay(hour: 10, minute: 30),
 );
 if (pickedTime != null) {
 final timeStr = pickedTime.format(context);
 final dateStr = "${pickedDate.day} ${_getMonthName(pickedDate.month)} ${pickedDate.year}";
 setState(() {
 controller.text = "$dateStr at $timeStr";
 });
 }
 }
 }

 String _getMonthName(int month) {
 const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
 return months[month - 1];
 }

 void _applyHydrationTarget(double liters, ScheduleService schedule) {
 final i18n = Provider.of<I18nService>(context, listen: false);
 schedule.setHydrationTargetLiters(liters, i18n: i18n);
 if (liters > 0) {
 _litersCtrl.text = liters.toStringAsFixed(1);
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text('${i18n.translate("hydrationUpdatedToast")} (${liters.toStringAsFixed(1)} L)')),
 );
 } else {
 _litersCtrl.clear();
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(i18n.translate('hydrationClearedToast'))),
 );
 }
 }

 Widget _buildCategoryCard(Map<String, dynamic> cat, I18nService i18n) {
 final isTamil = i18n.currentLang == 'ta';
 return InkWell(
 onTap: () {
 setState(() {
 _selectedSection = cat['index'] as int;
 });
 },
 borderRadius: BorderRadius.circular(16),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
 decoration: BoxDecoration(
 color: cat['bgColor'] as Color,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: cat['borderColor'] as Color, width: 1.5),
 boxShadow: [
 BoxShadow(
 color: (cat['borderColor'] as Color).withOpacity(0.10),
 blurRadius: 6,
 offset: const Offset(0, 3),
 ),
 ],
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 Text(cat['icon'] as String, style: const TextStyle(fontSize: 24)),
 Flexible(
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
 decoration: BoxDecoration(
 color: cat['badgeColor'] as Color,
 borderRadius: BorderRadius.circular(8),
 ),
 child: Text(
 cat['badge'] as String,
 style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
 softWrap: true,
 overflow: TextOverflow.visible,
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 6),
 Text(
 cat['title'] as String,
 style: TextStyle(
 fontSize: 13,
 fontWeight: FontWeight.bold,
 color: cat['borderColor'] as Color,
 ),
 softWrap: true,
 overflow: TextOverflow.visible,
 ),
 const SizedBox(height: 2),
 Text(
 cat['subtitle'] as String,
 style: const TextStyle(fontSize: 10.5, color: Colors.black54),
 softWrap: true,
 overflow: TextOverflow.visible,
 ),
 ],
 ),
 const SizedBox(height: 8),
 Row(
 mainAxisAlignment: MainAxisAlignment.end,
 children: [
 Text(
 isTamil ? 'திற ' : 'Open ',
 style: TextStyle(
 fontSize: 10.5,
 fontWeight: FontWeight.bold,
 color: cat['borderColor'] as Color,
 ),
 softWrap: true,
 overflow: TextOverflow.visible,
 ),
 ],
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildCategoryGrid(I18nService i18n, ScheduleService schedule, double targetLiters) {
 final isTamil = i18n.currentLang == 'ta';
 final medCount = schedule.reminders.where((r) => r.type == ReminderType.medicine).length;
 final aptCount = schedule.reminders.where((r) => r.type == ReminderType.appointment).length;
 final actCount = schedule.reminders.where((r) => r.type == ReminderType.routine).length;

 final categories = [
 {
 'index': 0,
 'title': i18n.translate('hydrationGoal'),
 'subtitle': isTamil ? 'குடிநீர் அளவு மற்றும் பதிவு' : 'Water goal & intake log',
 'icon': '💧',
 'bgColor': const Color(0xFFFDF0E6),
 'borderColor': const Color(0xFF23B39B),
 'badge': targetLiters > 0
 ? (isTamil ? '${targetLiters.toStringAsFixed(1)} எல் இலக்கு' : '${targetLiters.toStringAsFixed(1)} L Goal')
 : (isTamil ? 'இலக்கு அமை' : 'Set Target'),
 'badgeColor': const Color(0xFF61C5B0),
 },
 {
 'index': 1,
 'title': i18n.translate('addMedReminder'),
 'subtitle': isTamil ? 'மருந்து அளவு மற்றும் நேரங்கள்' : 'Pill dosage & timings',
 'icon': '💊',
 'bgColor': const Color(0xFFF0FDF4),
 'borderColor': const Color(0xFF23B39B),
 'badge': '$medCount ${i18n.translate("activeStatus")}',
 'badgeColor': const Color(0xFF23B39B),
 },
 {
 'index': 2,
 'title': i18n.translate('scheduleAppt'),
 'subtitle': i18n.translate('apptsSubtitle'),
 'icon': '🩺',
 'bgColor': const Color(0xFFFFFBEB),
 'borderColor': const Color(0xFFF59E0B),
 'badge': '$aptCount ${i18n.translate("upcomingStatus")}',
 'badgeColor': const Color(0xFFF59E0B),
 },
 {
 'index': 3,
 'title': i18n.translate('scheduleDailyActivity'),
 'subtitle': i18n.translate('routinesSubtitle'),
 'icon': '🏃‍♂️',
 'bgColor': const Color(0xFFE6F4F1),
 'borderColor': const Color(0xFF61C5B0),
 'badge': '$actCount ${i18n.translate("activeStatus")}',
 'badgeColor': const Color(0xFF0284C7),
 },
 {
 'index': 4,
 'title': i18n.translate('mealVoiceNotesTitle'),
 'subtitle': isTamil ? 'காலை, மதிய, இரவு உணவு குரல் பதிவுகள்' : 'Breakfast, Lunch & Dinner voice notes',
 'icon': '🎙️',
 'bgColor': const Color(0xFFFAF5FF),
 'borderColor': const Color(0xFF9333EA),
 'badge': isTamil ? '3 உணவுகள்' : '3 Meals',
 'badgeColor': const Color(0xFF9333EA),
 },
 ];

 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Padding(
 padding: const EdgeInsets.only(bottom: 8.0),
 child: Row(
 children: [
 const Icon(Icons.grid_view_rounded, color: Color(0xFF23B39B), size: 22),
 const SizedBox(width: 8),
 Text(
 i18n.translate('scheduleCategories'),
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
 ),
 ],
 ),
 ),
 IntrinsicHeight(
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Expanded(child: _buildCategoryCard(categories[0], i18n)),
 const SizedBox(width: 10),
 Expanded(child: _buildCategoryCard(categories[1], i18n)),
 ],
 ),
 ),
 const SizedBox(height: 10),
 IntrinsicHeight(
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Expanded(child: _buildCategoryCard(categories[2], i18n)),
 const SizedBox(width: 10),
 Expanded(child: _buildCategoryCard(categories[3], i18n)),
 ],
 ),
 ),
 const SizedBox(height: 10),
 _buildCategoryCard(categories[4], i18n),
 ],
 );
 }

 Widget _buildIndividualSectionHeader(I18nService i18n) {
 final isTamil = i18n.currentLang == 'ta';
 final sectionTitles = isTamil
 ? [
 '💧 தினசரி குடிநீர்',
 '💊 மருந்து நினைவூட்டல்கள்',
 '🩺 மருத்துவ சந்திப்புகள்',
 '🏃‍♂️ தினசரி நடவடிக்கைகள்',
 '🎙️ உணவு நேர குரல் குறிப்புகள்',
 ]
 : [
 '💧 Daily Hydration',
 '💊 Medicine Reminders',
 '🩺 Medical Appointments',
 '🏃‍♂️ Daily Activities',
 '🎙️ Meal Voice Notes',
 ];
 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF23B39B),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
 ),
 icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
 label: Text(
 i18n.translate('allCategories'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
 ),
 onPressed: () {
 setState(() {
 _selectedSection = null;
 });
 },
 ),
 const SizedBox(width: 10),
 Expanded(
 child: Text(
 sectionTitles[_selectedSection ?? 0],
 style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
 softWrap: true,
 ),
 ),
 ],
 ),
 const SizedBox(height: 8),
 SingleChildScrollView(
 scrollDirection: Axis.horizontal,
 child: Row(
 children: [
 _buildMiniTab(0, isTamil ? '💧 குடிநீர்' : '💧 Hydration', const Color(0xFF61C5B0)),
 const SizedBox(width: 6),
 _buildMiniTab(1, isTamil ? '💊 மருந்துகள்' : '💊 Medicines', const Color(0xFF23B39B)),
 const SizedBox(width: 6),
 _buildMiniTab(2, isTamil ? '🩺 சந்திப்புகள்' : '🩺 Appointments', const Color(0xFFF59E0B)),
 const SizedBox(width: 6),
 _buildMiniTab(3, isTamil ? '🏃‍♂️ நடவடிக்கைகள்' : '🏃‍♂️ Activities', const Color(0xFF0284C7)),
 const SizedBox(width: 6),
 _buildMiniTab(4, isTamil ? '🎙️ குரல் குறிப்புகள்' : '🎙️ Voice Notes', const Color(0xFF9333EA)),
 ],
 ),
 ),
 const SizedBox(height: 8),
 ],
 );
 }

 Widget _buildMiniTab(int index, String label, Color color) {
 final isSelected = _selectedSection == index;
 return GestureDetector(
 onTap: () {
 setState(() {
 _selectedSection = index;
 });
 },
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
 decoration: BoxDecoration(
 color: isSelected ? color : color.withOpacity(0.12),
 borderRadius: BorderRadius.circular(20),
 border: Border.all(color: color, width: 1.2),
 ),
 child: Text(
 label,
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.bold,
 color: isSelected ? Colors.white : color,
 ),
 ),
 ),
 );
 }

 Widget _buildHydrationSection(
 I18nService i18n,
 ScheduleService schedule,
 double targetLiters,
 int currentGlasses,
 int targetGlasses,
 ) {
 return ElderCard(
 padding: const EdgeInsets.all(12),
 backgroundColor: const Color(0xFFFDF0E6),
 border: Border.all(color: Color(0xFF23B39B), width: 1.5),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 Text(
 i18n.translate("hydrationGoal"),
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0)),
 softWrap: true,
 ),
 if (targetLiters > 0) ...[
 SizedBox(height: 4),
 Text(
 '$currentGlasses / $targetGlasses ${i18n.translate("glasses")} (${targetLiters.toStringAsFixed(1)} L)',
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF61C5B0)),
 softWrap: true,
 ),
 ],
 const SizedBox(height: 8),

 Row(
 children: [
 Expanded(
 child: TextField(
 controller: _litersCtrl,
 keyboardType: TextInputType.numberWithOptions(decimal: true),
 decoration: InputDecoration(
 labelText: i18n.translate('configureTargetLiters'),
 hintText: i18n.translate('egLitersHint'),
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 ),
 ),
 const SizedBox(width: 8),
 ElevatedButton(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF61C5B0),
 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 ),
 onPressed: () {
 FocusScope.of(context).unfocus();
 final valStr = _litersCtrl.text.trim();
 if (valStr.isEmpty) {
 _applyHydrationTarget(0.0, schedule);
 return;
 }
 final l = double.tryParse(valStr) ?? 0.0;
 _applyHydrationTarget(l, schedule);
 },
 child: Text(i18n.translate('saveGoal'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
 ),
 ],
 ),
 SizedBox(height: 8),

 if (targetLiters > 0) ...[
 ElderButton(
 label: i18n.translate('log1GlassWater'),
 icon: Icons.local_drink,
 backgroundColor: const Color(0xFF61C5B0),
 onPressed: () {
 schedule.logWaterGlass();
 _showHydrationSuccessDialog(context, i18n, schedule);
 },
 ),
 const SizedBox(height: 4),
 ],
 ],
 ),
 );
 }

 void _showHydrationSuccessDialog(BuildContext context, I18nService i18n, ScheduleService schedule) {
 final current = schedule.hydrationCurrentGlasses;
 final target = schedule.hydrationTargetGlasses;
 final liters = schedule.hydrationCurrentLiters.toStringAsFixed(1);
 final targetLiters = schedule.hydrationTargetLiters.toStringAsFixed(1);

 showDialog(
 context: context,
 builder: (ctx) => AlertDialog(
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
 backgroundColor: const Color(0xFFFDF0E6),
 title: Column(
 children: [
 Text('🥛🎉', style: TextStyle(fontSize: 44)),
 SizedBox(height: 8),
 Text(
 i18n.translate('hydrationLoggedTitle'),
 textAlign: TextAlign.center,
 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF23B39B)),
 ),
 ],
 ),
 content: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 Text(
 '${i18n.translate("logged1GlassSuccess")}\n\n ${i18n.translate("currentProgress")}: $current / $target ${i18n.translate("glasses")} ($liters / $targetLiters L)',
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B2824)),
 ),
 ],
 ),
 actionsAlignment: MainAxisAlignment.center,
 actions: [
 ElevatedButton(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF61C5B0),
 padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 ),
 onPressed: () => Navigator.of(ctx).pop(),
 child: Text(
 i18n.translate('okBtn'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildMedicineSection(I18nService i18n, ScheduleService schedule) {
 return ElderCard(
 padding: const EdgeInsets.all(12),
 backgroundColor: const Color(0xFFF0FDF4),
 border: Border.all(color: const Color(0xFF23B39B), width: 1.5),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 const Icon(Icons.medication, size: 24, color: Color(0xFF23B39B)),
 SizedBox(width: 8),
 Expanded(
 child: Text(
 i18n.translate('addMedReminder'),
 style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF23B39B)),
 softWrap: true,
 ),
 ),
 ],
 ),
 SizedBox(height: 8),

 TextField(
 controller: _medNameCtrl,
 decoration: InputDecoration(
 labelText: i18n.translate('medicineName'),
 hintText: i18n.translate('egMedHint'),
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 prefixIcon: const Icon(Icons.medication, color: Color(0xFF23B39B)),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 ),
 const SizedBox(height: 8),

 Row(
 children: [
 Expanded(
 child: TextField(
 controller: _medPillsCtrl,
 keyboardType: TextInputType.number,
 decoration: InputDecoration(
 labelText: i18n.translate('noOfPills'),
 hintText: '1',
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 ),
 ),
 const SizedBox(width: 8),
 Expanded(
 child: TextField(
 controller: _medTimeCtrl,
 readOnly: true,
 onTap: () => _selectTime(_medTimeCtrl),
 decoration: InputDecoration(
 labelText: i18n.translate('timeToRemind'),
 hintText: '08:00 AM',
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 suffixIcon: const Icon(Icons.access_time),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 8),

 DropdownButtonFormField<String>(
 value: _mealInstructionKeys.contains(_mealInstructionKey) ? _mealInstructionKey : _mealInstructionKeys.first,
 isExpanded: true,
 decoration: InputDecoration(
 labelText: i18n.translate('mealTiming'),
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 items: _mealInstructionKeys.map((k) {
 return DropdownMenuItem(
 value: k,
 child: Text(
 i18n.translate(k),
 style: const TextStyle(fontSize: 13),
 ),
 );
 }).toList(),
 onChanged: (val) {
 if (val != null) setState(() => _mealInstructionKey = val);
 },
 ),
 const SizedBox(height: 8),

 // Gallery Medicine Image Picker Card
 Container(
 padding: const EdgeInsets.all(10),
 decoration: BoxDecoration(
 color: Colors.white,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: const Color(0xFF61C5B0), width: 1.2),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 const Icon(Icons.photo_library, color: Color(0xFF23B39B), size: 20),
 const SizedBox(width: 8),
 Expanded(
 child: Text(
 i18n.currentLang == 'ta' ? 'மருந்து படம் (கேலரி)' : 'Medicine Image (Gallery)',
 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
 ),
 ),
 ],
 ),
 const SizedBox(height: 8),
 Row(
 children: [
 Expanded(
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF0284C7),
 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
 label: Text(
 _medicineImagePath != null && File(_medicineImagePath!).existsSync()
 ? (i18n.currentLang == 'ta' ? 'படம் மாற்று' : 'Change Image')
 : (i18n.currentLang == 'ta' ? 'கேலரியில் இருந்து படம் தேர்வு செய்' : 'Select Image from Gallery'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
 ),
 onPressed: _pickMedicineImageFromGallery,
 ),
 ),
 if (_medicineImagePath != null && File(_medicineImagePath!).existsSync()) ...[
 const SizedBox(width: 8),
 IconButton(
 icon: const Icon(Icons.cancel, color: Colors.red),
 onPressed: () {
 setState(() {
 _medicineImagePath = null;
 });
 },
 ),
 ],
 ],
 ),
 if (_medicineImagePath != null && File(_medicineImagePath!).existsSync()) ...[
 const SizedBox(height: 8),
 ClipRRect(
 borderRadius: BorderRadius.circular(10),
 child: Image.file(
 File(_medicineImagePath!),
 height: 90,
 width: 90,
 fit: BoxFit.cover,
 ),
 ),
 ],
 ],
 ),
 ),
 const SizedBox(height: 8),

 _buildVoiceRecorderCard(i18n),
 const SizedBox(height: 8),

 SizedBox(
 width: double.infinity,
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: Color(0xFF23B39B),
 padding: EdgeInsets.symmetric(vertical: 13),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 ),
 icon: Icon(Icons.add_alert, color: Colors.white),
 label: Text(i18n.translate('addMedReminderBtn'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
 onPressed: () {
 final name = _medNameCtrl.text.trim();
 final pills = _medPillsCtrl.text.trim().isEmpty ? '1' : _medPillsCtrl.text.trim();
 final time = _medTimeCtrl.text.trim().isEmpty ? '08:00 AM' : _medTimeCtrl.text.trim();

 if (name.isEmpty) {
 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(i18n.translate('medicineName'))));
 return;
 }

 final auth = Provider.of<AuthService>(context, listen: false);
 final role = auth.currentUser?.role ?? (auth.isCaretaker ? 'caretaker' : 'elder');

 schedule.addMedicineReminder(
 medicineName: name,
 pillsCount: pills,
 time: time,
 instructions: i18n.translate(_mealInstructionKey),
 customVoicePath: (_voiceMode == 1 || _voiceMode == 3) ? (_customVoicePath ?? '') : '',
 voiceMode: _voiceMode,
 clonedVoiceSamplePath: _voiceMode == 2 ? (_clonedVoiceSamplePath ?? '') : '',
 createdByRole: role,
 medicineImagePath: _medicineImagePath ?? '',
 i18n: i18n,
 );

 _medNameCtrl.clear();
 setState(() {
 _medicineImagePath = null;
 });
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text('${i18n.translate("medAddedToast")}: $name ($time)')),
 );
 },
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildAppointmentSection(I18nService i18n, ScheduleService schedule) {
 return ElderCard(
 padding: const EdgeInsets.all(12),
 backgroundColor: const Color(0xFFFFFBEB),
 border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 const Icon(Icons.medical_services, size: 22, color: Color(0xFFF59E0B)),
 SizedBox(width: 8),
 Expanded(
 child: Text(
 i18n.translate('scheduleAppt'),
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
 softWrap: true,
 ),
 ),
 ],
 ),
 SizedBox(height: 8),

 TextField(
 controller: _aptTitleCtrl,
 decoration: InputDecoration(
 labelText: i18n.translate('apptDoctorName'),
 hintText: i18n.translate('egApptHint'),
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 ),
 const SizedBox(height: 8),

 TextField(
 controller: _aptDateTimeCtrl,
 readOnly: true,
 onTap: () => _selectDateTime(_aptDateTimeCtrl),
 decoration: InputDecoration(
 labelText: i18n.translate('apptDateTime'),
 hintText: 'Select Date & Time',
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 suffixIcon: const Icon(Icons.calendar_month),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 ),
 SizedBox(height: 8),

 TextField(
 controller: _aptLocationCtrl,
 decoration: InputDecoration(
 labelText: i18n.translate('clinicLocation'),
 hintText: i18n.translate('egLocHint'),
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 ),
 const SizedBox(height: 10),

 SizedBox(
 width: double.infinity,
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: Color(0xFF23B39B),
 padding: EdgeInsets.symmetric(vertical: 13),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 ),
 icon: Icon(Icons.event_available, color: Colors.white),
 label: Text(i18n.translate('addApptBtn'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
 onPressed: () {
 final title = _aptTitleCtrl.text.trim();
 final dateTime = _aptDateTimeCtrl.text.trim();
 final location = _aptLocationCtrl.text.trim();

 if (title.isEmpty) {
 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(i18n.translate('apptDoctorName'))));
 return;
 }

 final auth = Provider.of<AuthService>(context, listen: false);
 final role = auth.currentUser?.role ?? (auth.isCaretaker ? 'caretaker' : 'elder');

 schedule.addMedicalAppointment(
 title: title,
 dateTime: dateTime,
 location: location,
 customVoicePath: '',
 voiceMode: 0,
 clonedVoiceSamplePath: '',
 createdByRole: role,
 i18n: i18n,
 );

 _aptTitleCtrl.clear();
 _aptLocationCtrl.clear();
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text('${i18n.translate("apptAddedToast")}: $title ($dateTime)')),
 );
 },
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildActivitySection(I18nService i18n, ScheduleService schedule) {
 return ElderCard(
 padding: const EdgeInsets.all(12),
 backgroundColor: const Color(0xFFE6F4F1),
 border: Border.all(color: const Color(0xFF61C5B0), width: 1.5),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 const Icon(Icons.directions_run, size: 22, color: Color(0xFF0284C7)),
 SizedBox(width: 8),
 Expanded(
 child: Text(
 i18n.translate('scheduleDailyActivity'),
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0)),
 softWrap: true,
 ),
 ),
 ],
 ),
 SizedBox(height: 8),

 TextField(
 controller: _actTitleCtrl,
 decoration: InputDecoration(
 labelText: i18n.translate('dailyActivityName'),
 hintText: i18n.translate('egActHint'),
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 ),
 const SizedBox(height: 8),

 Row(
 children: [
 Expanded(
 child: TextField(
 controller: _actTimeCtrl,
 readOnly: true,
 onTap: () => _selectTime(_actTimeCtrl),
 decoration: InputDecoration(
 labelText: i18n.translate('activityTime'),
 hintText: '07:00 AM',
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 suffixIcon: const Icon(Icons.access_time),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 ),
 ),
 ],
 ),
 SizedBox(height: 8),

 TextField(
 controller: _actDetailsCtrl,
 decoration: InputDecoration(
 labelText: i18n.translate('activityNotes'),
 hintText: i18n.translate('egNotesHint'),
 filled: true,
 fillColor: Colors.white,
 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 ),
 ),
 const SizedBox(height: 8),

 _buildVoiceRecorderCard(i18n, showGrandsonOption: false),
 const SizedBox(height: 8),

 SizedBox(
 width: double.infinity,
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: Color(0xFF61C5B0),
 padding: EdgeInsets.symmetric(vertical: 13),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 ),
 icon: Icon(Icons.directions_run, color: Colors.white),
 label: Text(i18n.translate('addActivityBtn'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
 onPressed: () {
 final title = _actTitleCtrl.text.trim();
 final time = _actTimeCtrl.text.trim().isEmpty ? '07:00 AM' : _actTimeCtrl.text.trim();
 final details = _actDetailsCtrl.text.trim();

 if (title.isEmpty) {
 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(i18n.translate('dailyActivityName'))));
 return;
 }

 final auth = Provider.of<AuthService>(context, listen: false);
 final role = auth.currentUser?.role ?? (auth.isCaretaker ? 'caretaker' : 'elder');

 schedule.addDailyActivity(
 activityTitle: title,
 time: time,
 details: details,
 customVoicePath: _customVoicePath ?? '',
 voiceMode: 1,
 clonedVoiceSamplePath: '',
 createdByRole: role,
 i18n: i18n,
 );

 _actTitleCtrl.clear();
 _actDetailsCtrl.clear();
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text('${i18n.translate("actAddedToast")}: $title ($time)')),
 );
 },
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildFilterButtons(I18nService i18n, ScheduleService schedule) {
 final totalCount = schedule.reminders.length;
 final medCount = schedule.reminders.where((r) => r.type == ReminderType.medicine).length;
 final aptCount = schedule.reminders.where((r) => r.type == ReminderType.appointment).length;
 final actCount = schedule.reminders.where((r) => r.type == ReminderType.routine).length;
 final pendingCount = schedule.reminders.where((r) => !r.isCompleted).length;
 final completedCount = schedule.reminders.where((r) => r.isCompleted).length;

 final filterButtons = [
 {'index': 0, 'label': '${i18n.translate("allCategories")} ($totalCount)', 'color': const Color(0xFF23B39B)},
 {'index': 1, 'label': '💊 ${i18n.translate("medicationsTab")} ($medCount)', 'color': const Color(0xFF23B39B)},
 {'index': 2, 'label': '🩺 ${i18n.translate("appointmentsTab")} ($aptCount)', 'color': const Color(0xFFF59E0B)},
 {'index': 3, 'label': '🏃‍♂️ ${i18n.translate("routinesTab")} ($actCount)', 'color': const Color(0xFF0284C7)},
 {'index': 4, 'label': '⏳ ${i18n.translate("pendingStatus")} ($pendingCount)', 'color': const Color(0xFFD97706)},
 {'index': 5, 'label': '✅ ${i18n.translate("completedStatus")} ($completedCount)', 'color': const Color(0xFF059669)},
 ];

 return Container(
 margin: const EdgeInsets.only(bottom: 12),
 child: SingleChildScrollView(
 scrollDirection: Axis.horizontal,
 child: Row(
 children: filterButtons.map((fb) {
 final idx = fb['index'] as int;
 final isSelected = _remindersFilterIndex == idx;
 final color = fb['color'] as Color;
 return Padding(
 padding: const EdgeInsets.only(right: 8),
 child: InkWell(
 onTap: () {
 setState(() {
 _remindersFilterIndex = idx;
 });
 },
 borderRadius: BorderRadius.circular(20),
 child: AnimatedContainer(
 duration: const Duration(milliseconds: 180),
 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
 decoration: BoxDecoration(
 color: isSelected ? color : color.withOpacity(0.12),
 borderRadius: BorderRadius.circular(20),
 border: Border.all(color: color, width: isSelected ? 2.0 : 1.2),
 boxShadow: isSelected
 ? [
 BoxShadow(
 color: color.withOpacity(0.3),
 blurRadius: 6,
 offset: const Offset(0, 2),
 ),
 ]
 : [],
 ),
 child: Text(
 fb['label'] as String,
 style: TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.bold,
 color: isSelected ? Colors.white : color,
 ),
 ),
 ),
 ),
 );
 }).toList(),
 ),
 ),
 );
 }

 Widget _buildRemindersList(I18nService i18n, ScheduleService schedule, {ReminderType? filterType}) {
 final auth = Provider.of<AuthService>(context);
 List<ReminderItem> baseList = filterType == null
 ? schedule.reminders
 : schedule.reminders.where((r) => r.type == filterType).toList();

 if (_remindersFilterIndex == 1) {
    baseList = baseList.where((r) => r.type == ReminderType.medicine).toList();
 } else if (_remindersFilterIndex == 2) {
 baseList = baseList.where((r) => r.type == ReminderType.appointment).toList();
 } else if (_remindersFilterIndex == 3) {
 baseList = baseList.where((r) => r.type == ReminderType.routine).toList();
 } else if (_remindersFilterIndex == 4) {
 baseList = baseList.where((r) => !r.isCompleted).toList();
 } else if (_remindersFilterIndex == 5) {
 baseList = baseList.where((r) => r.isCompleted).toList();
 }

 if (_selectedFilterDate != null) {
 final filterDate = _selectedFilterDate!;
 final targetDateStr = "${filterDate.day} ${_getMonthName(filterDate.month)} ${filterDate.year}";
 final isTodaySelected = filterDate.year == DateTime.now().year &&
 filterDate.month == DateTime.now().month &&
 filterDate.day == DateTime.now().day;

 baseList = baseList.where((r) {
 final t = r.time;
 if (t.contains(targetDateStr)) return true;
 final hasEmbeddedDate = t.contains('Jan') || t.contains('Feb') || t.contains('Mar') ||
 t.contains('Apr') || t.contains('May') || t.contains('Jun') ||
 t.contains('Jul') || t.contains('Aug') || t.contains('Sep') ||
 t.contains('Oct') || t.contains('Nov') || t.contains('Dec') ||
 t.contains('-');
 if (!hasEmbeddedDate && isTodaySelected) return true;
 return false;
 }).toList();
 }

 final filtered = baseList;

 return ElderCard(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
          Expanded(
            child: Text(
              filterType == ReminderType.medicine
                  ? '💊 ${i18n.translate("activeMedsHeader")}'
                  : (filterType == ReminderType.appointment
                      ? '🩺 ${i18n.translate("upcomingApptsHeader")}'
                      : (filterType == ReminderType.routine
                          ? '🏃‍♂️ ${i18n.translate("activeRoutinesHeader")}'
                          : '💊 ${i18n.translate("todayReminders")}')),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0)),
              softWrap: true,
            ),
          ),
 SizedBox(width: 8),
 Chip(
 label: Text('${filtered.length} ${i18n.translate("activeItems")}', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
 backgroundColor: const Color(0xFF61C5B0),
 ),
 ],
 ),
 const SizedBox(height: 12),

 // Touch-friendly Filter Buttons
 _buildFilterButtons(i18n, schedule),

 if (filtered.isEmpty) ...[
 Padding(
 padding: EdgeInsets.all(16),
 child: Text(i18n.translate('noRemindersActive'), style: TextStyle(color: Colors.grey, fontSize: 13)),
 ),
 ] else ...[
 ...filtered.map((r) => Container(
 margin: const EdgeInsets.only(bottom: 10),
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: r.type == ReminderType.appointment
 ? const Color(0xFFFFFBEB)
 : (r.type == ReminderType.routine ? const Color(0xFFE6F4F1) : const Color(0xFFF9FAF8)),
 borderRadius: BorderRadius.circular(14),
 border: Border.all(
 color: r.type == ReminderType.appointment
 ? const Color(0xFFF59E0B)
 : (r.type == ReminderType.routine ? const Color(0xFF61C5B0) : const Color(0xFFCDE4E2)),
 ),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Row(
 children: [
 Text(
 r.type == ReminderType.medicine ? '💊' : (r.type == ReminderType.appointment ? '🩺' : '🏃‍♂️'),
 style: const TextStyle(fontSize: 28),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 r.title,
 style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
 softWrap: true,
 overflow: TextOverflow.visible,
 ),
 const SizedBox(height: 2),
 Text(
 '${_formatReminderDateTimeDisplay(r.time)} • ${r.detail}',
 style: const TextStyle(fontSize: 12, color: Colors.black87),
 softWrap: true,
 overflow: TextOverflow.visible,
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 IconButton(
 padding: EdgeInsets.zero,
 constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
 icon: Icon(
 r.isCompleted ? Icons.check_circle : Icons.circle_outlined,
 color: r.isCompleted ? const Color(0xFF23B39B) : Colors.grey,
 size: 24,
 ),
 onPressed: () => schedule.toggleReminderCompletion(r.id),
 ),
 if (auth.isCaretaker || r.createdByRole == 'elder')
 IconButton(
 padding: EdgeInsets.zero,
 constraints: BoxConstraints(minWidth: 36, minHeight: 36),
 icon: Icon(Icons.delete_outline, color: Colors.red, size: 22),
 onPressed: () {
 schedule.deleteReminder(r.id);
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text('${i18n.translate("reminderDeletedToast")}: ${r.title}')),
 );
 },
 ),
 ],
 ),
 ],
 ),
 )).toList(),
 ],
 ],
 ),
 );
 }

 @override
 Widget build(BuildContext context) {
 final i18n = Provider.of<I18nService>(context);
 final auth = Provider.of<AuthService>(context);
 final schedule = Provider.of<ScheduleService>(context);

 final user = auth.currentUser;
 final activeElderId = (user?.mappedElderId != null && user!.mappedElderId.trim().isNotEmpty)
 ? user.mappedElderId.trim().toUpperCase()
 : (user?.id.isNotEmpty == true ? user!.id.toUpperCase() : 'NER-9431');
 schedule.setCurrentElderId(activeElderId);

 final targetGlasses = schedule.hydrationTargetGlasses;
 final currentGlasses = schedule.hydrationCurrentGlasses;
 final targetLiters = schedule.hydrationTargetLiters;

 return RefreshIndicator(
 onRefresh: () async {
 await schedule.loadSchedules(elderId: activeElderId);
 setState(() {});
 },
 child: ListView(
 padding: const EdgeInsets.all(16),
 children: [
 if (_selectedSection == null) ...[
 _buildCategoryGrid(i18n, schedule, targetLiters),
 const SizedBox(height: 20),
 _buildWeeklyProgressCard(i18n, schedule),
 ] else ...[
 _buildIndividualSectionHeader(i18n),
 if (_selectedSection == 0) ...[
 _buildHydrationSection(i18n, schedule, targetLiters, currentGlasses, targetGlasses),
 ] else if (_selectedSection == 1) ...[
 _buildMedicineSection(i18n, schedule),
 const SizedBox(height: 20),
 _buildWeeklyProgressCard(i18n, schedule),
 ] else if (_selectedSection == 2) ...[
 _buildAppointmentSection(i18n, schedule),
 ] else if (_selectedSection == 3) ...[
 _buildActivitySection(i18n, schedule),
 const SizedBox(height: 20),
 _buildWeeklyProgressCard(i18n, schedule),
 ] else if (_selectedSection == 4) ...[
 _buildMealVoiceNotesSection(i18n, schedule),
 ],
 ],
 ],
 ),
 );
 }

 Widget _buildWeeklyProgressCard(I18nService i18n, ScheduleService schedule) {
 final stats = schedule.getWeeklyProgressStats();
 final medPct = stats['medPercentage'] as int;
 final routinePct = stats['routinePercentage'] as int;
 final overallPct = stats['overallPercentage'] as int;
 final medBars = stats['medWeeklyBars'] as List<double>;
 final routineBars = stats['routineWeeklyBars'] as List<double>;
 final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
 final fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

 final selectedDayName = fullDays[_selectedProgressDayIndex];
 final selectedDayShort = daysOfWeek[_selectedProgressDayIndex];

 final medList = schedule.reminders.where((r) => r.type == ReminderType.medicine).toList();
 final routineList = schedule.reminders.where((r) => r.type == ReminderType.routine).toList();

 return ElderCard(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 const Text('📊', style: TextStyle(fontSize: 26)),
 const SizedBox(width: 10),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 i18n.translate('weeklyProgressTitle'),
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
 ),
 Text(
 i18n.translate('weeklyProgressSubtitle'),
 style: const TextStyle(fontSize: 11.5, color: Colors.black54),
 ),
 ],
 ),
 ),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
 decoration: BoxDecoration(
 gradient: const LinearGradient(
 colors: [Color(0xFF23B39B), Color(0xFF0284C7)],
 ),
 borderRadius: BorderRadius.circular(12),
 ),
 child: Text(
 '$overallPct%',
 style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
 ),
 ),
 ],
 ),
 const SizedBox(height: 16),

 // Horizontal Day-Wise Button Selector Bar
 SingleChildScrollView(
 scrollDirection: Axis.horizontal,
 child: Row(
 children: List.generate(7, (idx) {
 final isSelected = _selectedProgressDayIndex == idx;
 final isMedDone = medBars[idx] >= 1.0;
 final isRoutineDone = routineBars[idx] >= 1.0;
 final isDayFullyDone = isMedDone && isRoutineDone;

 return Padding(
 padding: const EdgeInsets.only(right: 8),
 child: InkWell(
 onTap: () {
 setState(() {
 _selectedProgressDayIndex = idx;
 });
 },
 borderRadius: BorderRadius.circular(20),
 child: AnimatedContainer(
 duration: const Duration(milliseconds: 180),
 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
 decoration: BoxDecoration(
 color: isSelected ? const Color(0xFF23B39B) : const Color(0xFFF1F5F9),
 borderRadius: BorderRadius.circular(20),
 border: Border.all(
 color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
 width: isSelected ? 2.0 : 1.2,
 ),
 boxShadow: isSelected
 ? [
 BoxShadow(
 color: const Color(0xFF23B39B).withOpacity(0.35),
 blurRadius: 6,
 offset: const Offset(0, 2),
 ),
 ]
 : [],
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Text(
 daysOfWeek[idx],
 style: TextStyle(
 fontSize: 12.5,
 fontWeight: FontWeight.bold,
 color: isSelected ? Colors.white : const Color(0xFF334155),
 ),
 ),
 const SizedBox(width: 5),
 Icon(
 isDayFullyDone ? Icons.check_circle : Icons.schedule,
 size: 14,
 color: isSelected ? Colors.white : (isDayFullyDone ? const Color(0xFF16A34A) : Colors.amber.shade700),
 ),
 ],
 ),
 ),
 ),
 );
 }),
 ),
 ),
 const SizedBox(height: 16),

 // 💊 Medicine Weekly Adherence Card
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: const Color(0xFFF0FDF4),
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: const Color(0xFF86EFAC)),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text(
 '💊 ${i18n.translate("medicineAdherence")}',
 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
 ),
 Text(
 '${stats['completedMeds']}/${stats['totalMeds']} Completed • $medPct%',
 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
 ),
 ],
 ),
 const SizedBox(height: 8),
 ClipRRect(
 borderRadius: BorderRadius.circular(6),
 child: LinearProgressIndicator(
 value: medPct / 100.0,
 minHeight: 8,
 backgroundColor: const Color(0xFFDCFCE7),
 valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
 ),
 ),
 const SizedBox(height: 12),
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceAround,
 children: List.generate(7, (idx) {
 final isDone = medBars[idx] >= 1.0;
 final isSelected = _selectedProgressDayIndex == idx;
 return GestureDetector(
 onTap: () {
 setState(() {
 _selectedProgressDayIndex = idx;
 });
 },
 child: Column(
 children: [
 Text(
 daysOfWeek[idx],
 style: TextStyle(
 fontSize: 11,
 color: isSelected ? const Color(0xFF15803D) : Colors.black54,
 fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
 ),
 ),
 const SizedBox(height: 4),
 AnimatedContainer(
 duration: const Duration(milliseconds: 150),
 width: 26,
 height: 26,
 decoration: BoxDecoration(
 color: isDone ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
 shape: BoxShape.circle,
 border: isSelected ? Border.all(color: const Color(0xFF14532D), width: 2.5) : null,
 boxShadow: isSelected
 ? [
 BoxShadow(
 color: const Color(0xFF16A34A).withOpacity(0.4),
 blurRadius: 6,
 spreadRadius: 1,
 )
 ]
 : [],
 ),
 child: Icon(
 isDone ? Icons.check : Icons.schedule,
 size: 14,
 color: Colors.white,
 ),
 ),
 ],
 ),
 );
 }),
 ),
 ],
 ),
 ),
 const SizedBox(height: 12),

 // 🏃‍♂️ Daily Routine Weekly Adherence Card
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: const Color(0xFFF0F9FF),
 borderRadius: BorderRadius.circular(14),
 border: Border.all(color: const Color(0xFFBAE6FD)),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text(
 '🏃‍♂️ ${i18n.translate("routineAdherence")}',
 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF075985)),
 ),
 Text(
 '${stats['completedRoutines']}/${stats['totalRoutines']} Completed • $routinePct%',
 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
 ),
 ],
 ),
 const SizedBox(height: 8),
 ClipRRect(
 borderRadius: BorderRadius.circular(6),
 child: LinearProgressIndicator(
 value: routinePct / 100.0,
 minHeight: 8,
 backgroundColor: const Color(0xFFE0F2FE),
 valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
 ),
 ),
 const SizedBox(height: 12),
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceAround,
 children: List.generate(7, (idx) {
 final isDone = routineBars[idx] >= 1.0;
 final isSelected = _selectedProgressDayIndex == idx;
 return GestureDetector(
 onTap: () {
 setState(() {
 _selectedProgressDayIndex = idx;
 });
 },
 child: Column(
 children: [
 Text(
 daysOfWeek[idx],
 style: TextStyle(
 fontSize: 11,
 color: isSelected ? const Color(0xFF0369A1) : Colors.black54,
 fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
 ),
 ),
 const SizedBox(height: 4),
 AnimatedContainer(
 duration: const Duration(milliseconds: 150),
 width: 26,
 height: 26,
 decoration: BoxDecoration(
 color: isDone ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
 shape: BoxShape.circle,
 border: isSelected ? Border.all(color: const Color(0xFF0C4A6E), width: 2.5) : null,
 boxShadow: isSelected
 ? [
 BoxShadow(
 color: const Color(0xFF0284C7).withOpacity(0.4),
 blurRadius: 6,
 spreadRadius: 1,
 )
 ]
 : [],
 ),
 child: Icon(
 isDone ? Icons.check : Icons.schedule,
 size: 14,
 color: Colors.white,
 ),
 ),
 ],
 ),
 );
 }),
 ),
 ],
 ),
 ),
 const SizedBox(height: 16),

 // 📅 Day-Wise Medicine & Routine Status Breakdown Section
 Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: const Color(0xFFFAF5FF),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: const Color(0xFFD8B4FE), width: 1.5),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 const Text('📅', style: TextStyle(fontSize: 22)),
 const SizedBox(width: 8),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 '$selectedDayName Medicine & Routine Status',
 style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8)),
 ),
 Text(
 i18n.translate('selectDayToView'),
 style: const TextStyle(fontSize: 11, color: Colors.black54),
 ),
 ],
 ),
 ),
 Chip(
 label: Text(
 selectedDayShort,
 style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
 ),
 backgroundColor: const Color(0xFF9333EA),
 ),
 ],
 ),
 const SizedBox(height: 12),
 if (medList.isEmpty && routineList.isEmpty) ...[
 const Padding(
 padding: EdgeInsets.symmetric(vertical: 12),
 child: Center(
 child: Text(
 'No medicines or daily routines scheduled for this day.',
 style: TextStyle(fontSize: 12, color: Colors.grey),
 ),
 ),
 ),
 ] else ...[
 // Medicine items
 if (medList.isNotEmpty) ...[
 const Text(
 '💊 Medicine List',
 style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
 ),
 const SizedBox(height: 6),
 ...medList.map((m) {
 final isTaken = m.isCompletedForDay(_selectedProgressDayIndex);
 return Container(
 margin: const EdgeInsets.only(bottom: 8),
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
 decoration: BoxDecoration(
 color: isTaken ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: isTaken ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Row(
 children: [
 const Text('💊', style: TextStyle(fontSize: 18)),
 const SizedBox(width: 8),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 m.title,
 style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
 ),
 Text(
 '${m.time} • ${m.detail}',
 style: const TextStyle(fontSize: 11, color: Colors.black87),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 InkWell(
 onTap: () {
 schedule.toggleReminderCompletionForDay(m.id, _selectedProgressDayIndex);
 },
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(
 color: isTaken ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
 borderRadius: BorderRadius.circular(12),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 isTaken ? Icons.check_circle : Icons.cancel,
 size: 14,
 color: Colors.white,
 ),
 const SizedBox(width: 4),
 Text(
 isTaken ? i18n.translate('statusTaken') : i18n.translate('statusYetToTake'),
 style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
 ),
 ],
 ),
 ),
 ),
 ],
 ),
 );
 }).toList(),
 const SizedBox(height: 8),
 ],

 // Routine items
 if (routineList.isNotEmpty) ...[
 const Text(
 '🏃‍♂️ Daily Routine List',
 style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF075985)),
 ),
 const SizedBox(height: 6),
 ...routineList.map((r) {
 final isDone = r.isCompletedForDay(_selectedProgressDayIndex);
 return Container(
 margin: const EdgeInsets.only(bottom: 8),
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
 decoration: BoxDecoration(
 color: isDone ? const Color(0xFFE0F2FE) : const Color(0xFFFFFBEB),
 borderRadius: BorderRadius.circular(10),
 border: Border.all(color: isDone ? const Color(0xFFBAE6FD) : const Color(0xFFFDE68A)),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Row(
 children: [
 const Text('🏃‍♂️', style: TextStyle(fontSize: 18)),
 const SizedBox(width: 8),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 r.title,
 style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
 ),
 Text(
 '${r.time} • ${r.detail}',
 style: const TextStyle(fontSize: 11, color: Colors.black87),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 InkWell(
 onTap: () {
 schedule.toggleReminderCompletionForDay(r.id, _selectedProgressDayIndex);
 },
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(
 color: isDone ? const Color(0xFF0284C7) : const Color(0xFFD97706),
 borderRadius: BorderRadius.circular(12),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 isDone ? Icons.check_circle : Icons.schedule,
 size: 14,
 color: Colors.white,
 ),
 const SizedBox(width: 4),
 Text(
 isDone ? i18n.translate('completedStatus') : i18n.translate('pendingStatus'),
 style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
 ),
 ],
 ),
 ),
 ),
 ],
 ),
 );
 }).toList(),
 ],
 ],
 ],
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildMealVoiceNotesSection(I18nService i18n, ScheduleService schedule) {
 final isTamil = i18n.currentLang == 'ta';
 final meals = [
 {
 'key': 'breakfast',
 'title': i18n.translate('morningBreakfastVoice'),
 'subtitle': isTamil ? 'காலை உணவுக்கான குரல் பதிவு' : 'Custom voice note for morning breakfast',
 'icon': '☕',
 'path': schedule.breakfastVoicePath,
 'color': const Color(0xFFF59E0B),
 'bgColor': const Color(0xFFFFFBEB),
 },
 {
 'key': 'lunch',
 'title': i18n.translate('afternoonLunchVoice'),
 'subtitle': isTamil ? 'மதிய உணவுக்கான குரல் பதிவு' : 'Custom voice note for afternoon lunch',
 'icon': '🍛',
 'path': schedule.lunchVoicePath,
 'color': const Color(0xFF0284C7),
 'bgColor': const Color(0xFFE0F2FE),
 },
 {
 'key': 'dinner',
 'title': i18n.translate('nightDinnerVoice'),
 'subtitle': isTamil ? 'இரவு உணவுக்கான குரல் பதிவு' : 'Custom voice note for night dinner',
 'icon': '🌙',
 'path': schedule.dinnerVoicePath,
 'color': const Color(0xFF9333EA),
 'bgColor': const Color(0xFFFAF5FF),
 },
 ];

 return Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 ElderCard(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 const Text('🎙️', style: TextStyle(fontSize: 26)),
 const SizedBox(width: 10),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 i18n.translate('mealVoiceNotesTitle'),
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
 ),
 Text(
 isTamil
 ? 'உணவு நேரங்களுக்கான சொந்த குரல் பதிவுகளை இங்கு பதிவு செய்து சேமிக்கலாம்'
 : 'Record and save custom voice notes for breakfast, lunch & dinner',
 style: const TextStyle(fontSize: 11.5, color: Colors.black54),
 ),
 ],
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 const SizedBox(height: 12),
 ...meals.map((meal) {
 final String mealKey = meal['key'] as String;
 final String title = meal['title'] as String;
 final String subtitle = meal['subtitle'] as String;
 final String icon = meal['icon'] as String;
 final String? voicePath = meal['path'] as String?;
 final Color color = meal['color'] as Color;
 final Color bgColor = meal['bgColor'] as Color;

 final bool hasVoice = voicePath != null && voicePath.isNotEmpty && File(voicePath).existsSync();
 final bool isRecordingThis = _isRecordingVoice && _recordingMealType == mealKey;

 return Container(
 margin: const EdgeInsets.only(bottom: 12),
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: bgColor,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: color, width: 1.5),
 boxShadow: [
 BoxShadow(
 color: color.withOpacity(0.08),
 blurRadius: 6,
 offset: const Offset(0, 3),
 ),
 ],
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 children: [
 Text(icon, style: const TextStyle(fontSize: 26)),
 const SizedBox(width: 10),
 Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 title,
 style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
 ),
 Text(
 subtitle,
 style: const TextStyle(fontSize: 11, color: Colors.black54),
 ),
 ],
 ),
 ],
 ),
 if (hasVoice)
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
 decoration: BoxDecoration(
 color: Colors.green.shade600,
 borderRadius: BorderRadius.circular(10),
 ),
 child: Text(
 isTamil ? 'சேமிக்கப்பட்டது 🔊' : 'Recorded 🔊',
 style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
 ),
 ),
 ],
 ),
 const SizedBox(height: 12),
 if (isRecordingThis) ...[
 ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: Colors.red,
 minimumSize: const Size(double.infinity, 44),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 icon: const Icon(Icons.stop, color: Colors.white),
 label: Text(
 i18n.translate('recordingCustomVoice').replaceAll('{sec}', '$_recordSeconds'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
 ),
 onPressed: () => _stopRecordingMealVoice(schedule),
 ),
 ] else ...[
 Row(
 children: [
 Expanded(
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: color,
 minimumSize: const Size(0, 42),
 padding: const EdgeInsets.symmetric(horizontal: 8),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 icon: const Icon(Icons.mic, color: Colors.white, size: 18),
 label: Text(
 hasVoice ? i18n.translate('reRecordVoiceBtn') : i18n.translate('clickToRecord'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
 ),
 onPressed: () => _startRecordingMealVoice(mealKey),
 ),
 ),
 if (hasVoice) ...[
 const SizedBox(width: 8),
 ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF059669),
 minimumSize: const Size(0, 42),
 padding: const EdgeInsets.symmetric(horizontal: 10),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
 label: Text(
 isTamil ? 'கேட்க' : 'Play',
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
 ),
 onPressed: () => _playMealVoice(voicePath!),
 ),
 const SizedBox(width: 6),
 IconButton(
 icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
 onPressed: () async {
 await schedule.setMealVoicePath(mealKey, null);
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(i18n.translate('deleteSuccessToast'))),
 );
 setState(() {});
 }
 },
 ),
 ],
 ],
 ),
 ],
 ],
 ),
 );
 }).toList(),
 ],
 );
 }
}
