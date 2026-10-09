import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../services/i18n_service.dart';
import '../services/auth_service.dart';
import '../services/memory_lane_service.dart';
import '../models/memory_item.dart';
import '../widgets/elder_card.dart';
import '../widgets/elder_button.dart';
import '../widgets/favorite_music_section.dart';
import '../widgets/favorite_place_section.dart';

class MemoryLaneScreen extends StatefulWidget {
 const MemoryLaneScreen({Key? key}) : super(key: key);

 @override
 State<MemoryLaneScreen> createState() => _MemoryLaneScreenState();
}

class _MemoryLaneScreenState extends State<MemoryLaneScreen> {
 // 3 Category Options: 0 = Favourite Music, 1 = Favourite Places, 2 = Personal Memories
 int _selectedTab = 0;

 @override
 void initState() {
 super.initState();
 WidgetsBinding.instance.addPostFrameCallback((_) {
 final auth = Provider.of<AuthService>(context, listen: false);
 final memoryService = Provider.of<MemoryLaneService>(context, listen: false);
 final mappedId = auth.currentUser?.mappedElderId ?? '';
 if (mappedId.isNotEmpty) {
 memoryService.loadMemories(elderId: mappedId);
 }
 });
 }

 final List<Map<String, String>> _galleryPhotos = [
 {'name': 'Family Reunion Gathering 🌸', 'path': 'assets/images/kaziranga.jpg'},
 {'name': 'Grandchildren Birthday 🎂', 'path': 'assets/images/app_logo.png'},
 {'name': 'Living Root Bridge Trek 🌉', 'path': 'assets/images/living_root_bridge.jpg'},
 {'name': 'Bihu Cultural Folk Dance 💃', 'path': 'assets/images/bihu_dance.jpg'},
 {'name': 'Morning Tea Garden Walk 🍵', 'path': 'assets/images/kaziranga.jpg'},
 {'name': 'Temple Pilgrimage Moment 🛕', 'path': 'assets/images/living_root_bridge.jpg'},
 ];

 final List<Map<String, String>> _galleryVideos = [
 {'name': 'Family Celebration Clip 🎥', 'path': 'assets/videos/kaziranga_safari.mp4', 'thumb': 'assets/images/kaziranga.jpg'},
 {'name': 'Grandson First Steps Video 🎥', 'path': 'assets/videos/root_bridge_tour.mp4', 'thumb': 'assets/images/living_root_bridge.jpg'},
 {'name': 'Bihu Festival Dance Video 🎥', 'path': 'assets/videos/bihu_dance.mp4', 'thumb': 'assets/images/bihu_dance.jpg'},
 ];

 final List<Map<String, String>> _sampleMusicTracks = [
 {'name': 'Bihu Folk Flute Tune 🎶', 'path': 'assets/videos/bihu_dance.mp4', 'duration': '02:45'},
 {'name': 'Carnatic Morning Veena Raga 🪕', 'path': 'assets/videos/kaziranga_safari.mp4', 'duration': '03:12'},
 {'name': 'Rabha Folk Bamboo Melody 🎵', 'path': 'assets/videos/root_bridge_tour.mp4', 'duration': '02:18'},
 {'name': 'Gentle Morning Nature Sounds 🌿', 'path': 'assets/videos/bihu_dance.mp4', 'duration': '04:05'},
 ];

 // Mobile gallery helper pickers...
 Future<void> _pickFromMobileGallery(BuildContext context, String mediaType, Function(String path) onSelected) async {
 try {
 if (mediaType == 'photo') {
 final picker = ImagePicker();
 final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
 if (image != null) {
 onSelected(image.path);
 return;
 }
 } else if (mediaType == 'video') {
 final picker = ImagePicker();
 final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
 if (video != null) {
 onSelected(video.path);
 return;
 }
 } else if (mediaType == 'audio') {
 final FilePickerResult? result = await FilePicker.platform.pickFiles(
 type: FileType.custom,
 allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac', 'opus', 'wma', 'amr'],
 );
 if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
 onSelected(result.files.single.path!);
 return;
 }
 }
 } catch (e) {
 debugPrint('Mobile gallery picker error: $e');
 }
 }

 // --- DIALOG 3: PERSONAL MEMORIES UPLOAD (Option 3) ---
 void _showAddMemoryDialog(BuildContext context) {
 final i18n = Provider.of<I18nService>(context, listen: false);
 final auth = Provider.of<AuthService>(context, listen: false);
 final memoryService = Provider.of<MemoryLaneService>(context, listen: false);

 final titleCtrl = TextEditingController();
 DateTime selectedDate = DateTime.now();
 final dateCtrl = TextEditingController(
 text: "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
 );
 final storyCtrl = TextEditingController();

 String selectedMediaType = 'photo';
 String selectedPhotoPath = '';
 String selectedVideoPath = '';
 bool hasRecordedVoice = false;

 showModalBottomSheet(
 context: context,
 isScrollControlled: true,
 backgroundColor: Colors.white,
 shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
 builder: (ctx) {
 return StatefulBuilder(
 builder: (modalCtx, setModalState) {
 final isRecording = memoryService.isRecording;
 final recSecs = memoryService.recordSeconds;
 final spokenText = memoryService.recordedSpokenText;

 return Padding(
 padding: EdgeInsets.only(
 bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16,
 top: 20,
 left: 20,
 right: 20,
 ),
 child: SingleChildScrollView(
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Row(
 children: [
 Image.asset(
 'assets/images/camera_icon.png',
 width: 28,
 height: 28,
 fit: BoxFit.contain,
 errorBuilder: (ctx, err, stack) => const Text('📸', style: TextStyle(fontSize: 22)),
 ),
 const SizedBox(width: 8),
 Expanded(
 child: Text(
 i18n.translate('uploadPersonalMemoryTitle'),
 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
 softWrap: true,
 ),
 ),
 ],
 ),
 ),
 IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(modalCtx)),
 ],
 ),
 const SizedBox(height: 12),

 TextField(
 controller: titleCtrl,
 decoration: InputDecoration(
 labelText: i18n.translate('memoryCaption'),
 hintText: 'e.g. Family gathering at home',
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 prefixIcon: const Icon(Icons.title, color: Color(0xFF61C5B0)),
 ),
 ),
 const SizedBox(height: 12),

 TextField(
 controller: storyCtrl,
 maxLines: 2,
 decoration: InputDecoration(
 labelText: i18n.translate('memoryStory'),
 hintText: 'e.g. Celebrating birthday with children and grandchildren',
 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
 prefixIcon: const Icon(Icons.note_alt, color: Color(0xFF61C5B0)),
 ),
 ),
 const SizedBox(height: 14),

 Row(
 children: [
 Expanded(
 child: ChoiceChip(
 label: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(i18n.translate('mediaTypePhoto'))]),
 selected: selectedMediaType == 'photo',
 selectedColor: const Color(0xFF61C5B0).withOpacity(0.2),
 onSelected: (val) {
 if (val) setModalState(() => selectedMediaType = 'photo');
 },
 ),
 ),
 const SizedBox(width: 10),
 Expanded(
 child: ChoiceChip(
 label: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(i18n.translate('mediaTypeVideo'))]),
 selected: selectedMediaType == 'video',
 selectedColor: const Color(0xFF61C5B0).withOpacity(0.2),
 onSelected: (val) {
 if (val) setModalState(() => selectedMediaType = 'video');
 },
 ),
 ),
 ],
 ),
 const SizedBox(height: 14),

 if (selectedMediaType == 'photo') ...[
 GestureDetector(
 onTap: () {
 _pickFromMobileGallery(context, 'photo', (path) {
 setModalState(() => selectedPhotoPath = path);
 });
 },
 child: Container(
 height: 100,
 decoration: BoxDecoration(
 color: const Color(0xFFF0FDF9),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: const Color(0xFF61C5B0), width: 1.5),
 ),
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 const Icon(Icons.add_photo_alternate_rounded, size: 34, color: Color(0xFF23B39B)),
 const SizedBox(height: 4),
 Text(
 selectedPhotoPath.isNotEmpty ? 'Photo Selected ' : 'Choose Photo from Gallery ',
 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2824)),
 ),
 ],
 ),
 ),
 ),
 ] else ...[
 GestureDetector(
 onTap: () {
 _pickFromMobileGallery(context, 'video', (path) {
 setModalState(() => selectedVideoPath = path);
 });
 },
 child: Container(
 height: 100,
 decoration: BoxDecoration(
 color: const Color(0xFFFFF7ED),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(color: const Color(0xFFF97316), width: 1.5),
 ),
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 const Icon(Icons.video_call_rounded, size: 34, color: Color(0xFFF97316)),
 const SizedBox(height: 4),
 Text(
 selectedVideoPath.isNotEmpty ? 'Video Selected ' : 'Choose Video from Gallery ',
 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2824)),
 ),
 ],
 ),
 ),
 ),
 ],
 const SizedBox(height: 14),

 // Voice Recording Section for Audio Story
 Consumer<MemoryLaneService>(
 builder: (modalCtx, memSrv, child) {
 final recIsRecording = memSrv.isRecording;
 final recSecs = memSrv.recordSeconds;
 final recordedPath = memSrv.lastRecordedVoiceNotePath;
 final hasAudio = (recordedPath != null && recordedPath.isNotEmpty) || hasRecordedVoice;
 final isTamil = i18n.currentLang == 'ta';

 return Container(
 padding: const EdgeInsets.all(14),
 decoration: BoxDecoration(
 color: recIsRecording ? const Color(0xFFFFF0F0) : (hasAudio ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF)),
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: recIsRecording ? const Color(0xFFDC2626) : (hasAudio ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
 width: 1.5,
 ),
 ),
 child: Column(
 children: [
 Row(
 children: [
 Icon(
 recIsRecording ? Icons.graphic_eq : (hasAudio ? Icons.check_circle : Icons.mic),
 color: recIsRecording ? const Color(0xFFDC2626) : (hasAudio ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
 size: 24,
 ),
 const SizedBox(width: 10),
 Expanded(
 child: Text(
 recIsRecording
 ? (isTamil ? 'குரல் கதை பதிவு செய்யப்படுகிறது... (${recSecs}வி)' : 'Recording Audio Story... (${recSecs}s)')
 : (hasAudio
 ? (isTamil ? 'குரல் கதை பதிவு செய்யப்பட்டது! ️' : 'Voice Story Recorded! ️')
 : (isTamil ? 'குரல் கதை / ஒலி குறிப்பு பதிவு செய் ️' : 'Record Voice Story / Audio Note ️')),
 style: TextStyle(
 fontWeight: FontWeight.bold,
 fontSize: 13,
 color: recIsRecording ? const Color(0xFFDC2626) : (hasAudio ? const Color(0xFF047857) : const Color(0xFF1B2824)),
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 10),
 ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: recIsRecording ? const Color(0xFFDC2626) : (hasAudio ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
 ),
 icon: Icon(recIsRecording ? Icons.stop : (hasAudio ? Icons.refresh : Icons.fiber_manual_record), color: Colors.white, size: 18),
 label: Text(
 recIsRecording
 ? (isTamil ? 'பதிவை நிறுத்து (${recSecs}வி)' : 'Stop Recording (${recSecs}s)')
 : (hasAudio
 ? (isTamil ? 'மீண்டும் குரல் பதிவு செய்' : 'Re-record Voice Story')
 : (isTamil ? 'குரல் பதிவு செய் ️' : 'Record Voice Story ️')),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
 ),
 onPressed: () async {
 if (!recIsRecording) {
 final ok = await memSrv.startRecording(langCode: i18n.currentLang);
 setModalState(() => hasRecordedVoice = false);
 if (!ok && modalCtx.mounted) {
 ScaffoldMessenger.of(modalCtx).showSnackBar(
 SnackBar(content: Text(isTamil ? 'ஒலிப்பதிவுக்கு மைக்ரோஃபோன் அனுமதி தேவை.' : 'Microphone permission required for audio recording.')),
 );
 }
 } else {
 final path = await memSrv.stopRecording();
 setModalState(() {
 hasRecordedVoice = path != null && path.isNotEmpty;
 });
 }
 },
 ),
 ],
 ),
 );
 },
 ),
 const SizedBox(height: 16),

 ElderButton(
 backgroundColor: const Color(0xFF23B39B),
 textColor: Colors.white,
 label: i18n.translate('saveMemoryBtn'),
 onPressed: () async {
 final title = titleCtrl.text.trim();
 final dateStr = dateCtrl.text.trim();
 final story = storyCtrl.text.trim();

 if (title.isEmpty) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(i18n.translate('enterMemoryTitleError'))),
 );
 return;
 }

 if (memoryService.isRecording) {
 await memoryService.stopRecording();
 await Future.delayed(const Duration(milliseconds: 150));
 }

 if (Navigator.of(modalCtx, rootNavigator: true).canPop()) {
 Navigator.of(modalCtx, rootNavigator: true).pop();
 } else if (Navigator.canPop(modalCtx)) {
 Navigator.pop(modalCtx);
 }

 await memoryService.addMemory(
 title: title,
 date: dateStr,
 storyNote: story.isNotEmpty ? story : 'Personal family memory uploaded by ${auth.isCaretaker ? "Caregiver" : "Elder"}.',
 imagePath: selectedMediaType == 'photo' ? selectedPhotoPath : selectedVideoPath,
 videoPath: selectedMediaType == 'video' ? selectedVideoPath : null,
 audioPath: memoryService.lastRecordedVoiceNotePath,
 voiceNotePath: memoryService.lastRecordedVoiceNotePath,
 mediaType: selectedMediaType,
 category: 'personal',
 createdByRole: auth.isCaretaker ? 'caretaker' : 'elder',
 );

 if (context.mounted) {
 _showMemorySavedSuccessDialog(context, title, selectedMediaType);
 }
 },
 ),
 const SizedBox(height: 10),
 ],
 ),
 ),
 );
 },
 );
 },
 );
 }

 void _showMemorySavedSuccessDialog(BuildContext context, String title, String mediaType) {
 showDialog(
 context: context,
 builder: (dialogCtx) => AlertDialog(
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
 backgroundColor: const Color(0xFFFDF0E6),
 title: const Row(
 children: [
 Icon(Icons.check_circle, color: Color(0xFF23B39B), size: 30),
 SizedBox(width: 10),
 Expanded(
 child: Text(
 ' Successfully Uploaded!',
 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B2824)),
 ),
 ),
 ],
 ),
 content: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Your memory "$title" has been successfully uploaded and synced to Elder page!',
 style: const TextStyle(fontSize: 14, color: Color(0xFF1B2824)),
 ),
 ],
 ),
 actions: [
 ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF23B39B),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
 padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
 ),
 onPressed: () => Navigator.pop(dialogCtx),
 icon: const Icon(Icons.check, color: Colors.white, size: 18),
 label: const Text('OK ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
 ),
 ],
 ),
 );
 }

 void _confirmDelete(BuildContext context, MemoryLaneService memoryService, MemoryItem item) {
 showDialog(
 context: context,
 builder: (ctx) => AlertDialog(
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
 title: Text(Provider.of<I18nService>(context, listen: false).translate('deleteMemoryConfirmTitle'), style: const TextStyle(fontWeight: FontWeight.bold)),
 content: Text(Provider.of<I18nService>(context, listen: false).translate('deleteMemoryConfirmDesc')),
 actions: [
 TextButton(
 onPressed: () => Navigator.pop(ctx),
 child: Text(Provider.of<I18nService>(context, listen: false).translate('cancelBtn'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
 ),
 ElevatedButton(
 style: ElevatedButton.styleFrom(
 backgroundColor: Colors.red,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 onPressed: () {
 memoryService.deleteMemory(item.id);
 Navigator.pop(ctx);
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(Provider.of<I18nService>(context, listen: false).translate('memoryDeletedSuccessToast'))),
 );
 },
 child: Text('${Provider.of<I18nService>(context, listen: false).translate("deleteBtn")} ️', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
 ),
 ],
 ),
 );
 }

 Widget _buildMemoryImage(String path, {double? height = 195, BoxFit fit = BoxFit.cover}) {
 if (path.isEmpty) return _imageFallbackContainer(height ?? 195);

 if (path.startsWith('/') || path.contains('file://') || path.contains('data/')) {
 final cleanPath = path.replaceAll('file://', '');
 final file = File(cleanPath);
 if (file.existsSync()) {
 return Image.file(
 file,
 height: height,
 width: double.infinity,
 fit: fit,
 errorBuilder: (ctx, err, stack) => _imageFallbackContainer(height ?? 195),
 );
 }
 }

 if (path.startsWith('http')) {
 return Image.network(
 path,
 height: height,
 width: double.infinity,
 fit: fit,
 errorBuilder: (ctx, err, stack) => _imageFallbackContainer(height ?? 195),
 );
 }
 return Image.asset(
 path,
 height: height,
 width: double.infinity,
 fit: fit,
 errorBuilder: (ctx, err, stack) => _imageFallbackContainer(height ?? 195),
 );
 }

 Widget _imageFallbackContainer(double height) {
 return Container(
 height: height,
 color: const Color(0xFF61C5B0),
 alignment: Alignment.center,
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 const Icon(Icons.photo_library, color: Colors.white, size: 48),
 const SizedBox(height: 6),
 Text(Provider.of<I18nService>(context, listen: false).translate('elderPersonalMemoryCorner'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
 ],
 ),
 );
 }

 void _showVideoPlayerModal(BuildContext context, MemoryItem item) {
 showDialog(
 context: context,
 builder: (ctx) => MemoryVideoPlayerDialog(item: item),
 );
 }

 void _showEnlargedImageModal(BuildContext context, MemoryItem item) {
 final i18n = Provider.of<I18nService>(context, listen: false);
 final titleStr = item.titleKey.isNotEmpty ? i18n.translate(item.titleKey) : item.title;
 final storyStr = item.storyKey.isNotEmpty ? i18n.translate(item.storyKey) : item.storyNote;

 showDialog(
 context: context,
 builder: (ctx) => Dialog(
 backgroundColor: Colors.transparent,
 insetPadding: const EdgeInsets.all(12),
 child: Stack(
 alignment: Alignment.topRight,
 children: [
 Container(
 clipBehavior: Clip.antiAlias,
 decoration: BoxDecoration(
 color: const Color(0xFF1B2824),
 borderRadius: BorderRadius.circular(24),
 boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)],
 ),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 ClipRRect(
 borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
 child: Container(
 constraints: BoxConstraints(
 maxHeight: MediaQuery.of(context).size.height * 0.65,
 maxWidth: double.infinity,
 ),
 color: Colors.black,
 child: InteractiveViewer(
 panEnabled: true,
 boundaryMargin: const EdgeInsets.all(20),
 minScale: 0.8,
 maxScale: 4.0,
 child: _buildMemoryImage(item.imagePath, height: null, fit: BoxFit.contain),
 ),
 ),
 ),
 Container(
 padding: const EdgeInsets.all(16),
 decoration: const BoxDecoration(
 color: Color(0xFF1B2824),
 borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Text(
 titleStr,
 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
 softWrap: true,
 ),
 ),
 const SizedBox(width: 8),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(color: const Color(0xFF23B39B), borderRadius: BorderRadius.circular(8)),
 child: Text(item.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
 ),
 ],
 ),
 if (storyStr.isNotEmpty) ...[
 const SizedBox(height: 8),
 Text(storyStr, style: const TextStyle(fontSize: 13, color: Colors.white70), softWrap: true),
 ],
 ],
 ),
 ),
 ],
 ),
 ),
 Positioned(
 top: 10,
 right: 10,
 child: IconButton(
 style: IconButton.styleFrom(backgroundColor: Colors.black54),
 icon: const Icon(Icons.close, color: Colors.white, size: 24),
 onPressed: () => Navigator.of(ctx).pop(),
 ),
 ),
 ],
 ),
 ),
 );
 }

 Widget _buildSectionTabCard({
   required int index,
   required String title,
   required String subtitle,
   required IconData icon,
   required int count,
 }) {
   final isSelected = _selectedTab == index;
   return GestureDetector(
     onTap: () => setState(() => _selectedTab = index),
     child: AnimatedContainer(
       duration: const Duration(milliseconds: 200),
       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
       decoration: BoxDecoration(
         color: isSelected ? const Color(0xFFE6F4F1) : Colors.white,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(
           color: isSelected ? const Color(0xFF23B39B) : Colors.grey.shade300,
           width: isSelected ? 2.0 : 1.0,
         ),
         boxShadow: isSelected
             ? [
                 BoxShadow(
                   color: const Color(0xFF23B39B).withOpacity(0.18),
                   blurRadius: 8,
                   offset: const Offset(0, 3),
                 )
               ]
             : null,
       ),
       child: Row(
         children: [
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: isSelected ? const Color(0xFF23B39B) : const Color(0xFFF0FDF4),
               shape: BoxShape.circle,
             ),
             child: Icon(
               icon,
               color: isSelected ? Colors.white : const Color(0xFF23B39B),
               size: 20,
             ),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   title,
                   style: TextStyle(
                     fontSize: 15,
                     fontWeight: FontWeight.bold,
                     color: isSelected ? const Color(0xFF1B2824) : Colors.black87,
                   ),
                 ),
                 const SizedBox(height: 2),
                 Text(
                   subtitle,
                   style: TextStyle(
                     fontSize: 11,
                     color: isSelected ? const Color(0xFF23B39B) : Colors.grey,
                     fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                   ),
                 ),
               ],
             ),
           ),
           if (count > 0)
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
               decoration: BoxDecoration(
                 color: isSelected ? const Color(0xFF23B39B) : Colors.grey.shade200,
                 borderRadius: BorderRadius.circular(10),
               ),
               child: Text(
                 '$count',
                 style: TextStyle(
                   fontSize: 11,
                   fontWeight: FontWeight.bold,
                   color: isSelected ? Colors.white : Colors.black87,
                 ),
               ),
             ),
         ],
       ),
     ),
   );
 }

 @override
 Widget build(BuildContext context) {
 final i18n = Provider.of<I18nService>(context);
 final auth = Provider.of<AuthService>(context);
 final memoryService = Provider.of<MemoryLaneService>(context);
 final isTamil = i18n.currentLang == 'ta';

 final mappedId = auth.currentUser?.mappedElderId ?? 'NER-9431';
 memoryService.setCurrentElderId(mappedId);

 final personalItems = memoryService.memories
     .where((m) => m.category == 'personal' || (m.category != 'music' && m.category != 'places' && !m.isPublicLandmark))
     .toList();
 final musicItems = memoryService.musicMemories;
 final placeItems = memoryService.placesMemories;
 final isPlayingVoice = memoryService.isPlayingVoiceNote;

 return RefreshIndicator(
   onRefresh: () async {
     await memoryService.loadMemories(elderId: mappedId);
     setState(() {});
   },
   child: ListView(
     padding: const EdgeInsets.all(16),
     children: [
       // Top Header
       Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Expanded(
             child: Row(
               children: [
                 Image.asset(
                   'assets/images/camera_icon.png',
                   width: 36,
                   height: 36,
                   fit: BoxFit.contain,
                   errorBuilder: (ctx, err, stack) => const Text('📸', style: TextStyle(fontSize: 26)),
                 ),
                 const SizedBox(width: 10),
                 Expanded(
                   child: Text(
                     i18n.translate('memoryLane'),
                     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                   ),
                 ),
               ],
             ),
           ),
           if (_selectedTab == 0)
             IconButton(
               icon: const Icon(Icons.add_circle, color: Color(0xFF23B39B), size: 36),
               onPressed: () => _showAddMemoryDialog(context),
               tooltip: isTamil ? 'நினைவு சேர்' : 'Add Memory',
             ),
         ],
       ),
       const SizedBox(height: 16),

       // OVERALL MEMORYLANE STRUCTURE (3 Navigation Cards):
       // 1. Personal Memories (Existing Feature — 100% Unchanged)
       // 2. Favorite Music (New Feature)
       // 3. Favorite Places (New Feature)
       _buildSectionTabCard(
         index: 0,
         title: isTamil ? 'சொந்த நினைவுகள்' : 'Personal Memories',
         subtitle: isTamil ? 'புகைப்படம் • காணொளி • குரல்' : 'Photos • Video • Voice Story',
         icon: Icons.photo_library,
         count: personalItems.length,
       ),
       const SizedBox(height: 10),
       _buildSectionTabCard(
         index: 1,
         title: isTamil ? '❤️ பிடித்த இசை' : '❤️ Favorite Music',
         subtitle: isTamil ? 'பராமரிப்பாளர் சேர்த்த MP3 இசை' : 'Caregiver adds music • MP3',
         icon: Icons.music_note,
         count: musicItems.length,
       ),
       const SizedBox(height: 10),
       _buildSectionTabCard(
         index: 2,
         title: isTamil ? '📍 பிடித்த இடங்கள்' : '📍 Favorite Places',
         subtitle: isTamil ? 'புகைப்படங்கள் • வீடியோ • கதை' : 'Photos • Video • Story',
         icon: Icons.place,
         count: placeItems.length,
       ),
       const SizedBox(height: 16),

       // --- SECTION 1: PERSONAL MEMORIES (EXISTING FEATURE — UNCHANGED) ---
       if (_selectedTab == 0) ...[
         // Upload Personal Memory Action Banner Button
         Container(
           margin: const EdgeInsets.only(bottom: 16),
           child: ElevatedButton.icon(
             style: ElevatedButton.styleFrom(
               backgroundColor: const Color(0xFF23B39B),
               padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
             ),
             icon: const Icon(
               Icons.add_photo_alternate,
               color: Colors.white,
             ),
             label: Text(
               isTamil ? '🖼️ சொந்த நினைவை பதிவேற்று' : '🖼️ Upload Personal Memory',
               style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
             ),
             onPressed: () => _showAddMemoryDialog(context),
           ),
         ),

         // Active Playing Sticky Audio Banner
         if (isPlayingVoice) ...[
           Container(
             margin: const EdgeInsets.only(bottom: 16),
             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
             decoration: BoxDecoration(
               color: const Color(0xFFFEF2F2),
               borderRadius: BorderRadius.circular(14),
               border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Expanded(
                   child: Row(
                     children: [
                       const Icon(Icons.volume_up, color: Color(0xFFDC2626), size: 22),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           isTamil ? ' ஒலி இயங்குகிறது...' : ' Playing Voice Note...',
                           style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B), fontSize: 13),
                         ),
                       ),
                     ],
                   ),
                 ),
                 ElevatedButton.icon(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFFDC2626),
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                   ),
                   icon: const Icon(Icons.stop, color: Colors.white, size: 16),
                   label: Text(
                     i18n.translate('stopAudioBtn'),
                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                   ),
                   onPressed: () => memoryService.stopVoiceNote(),
                 ),
               ],
             ),
           ),
         ],

         ..._buildMediaCardsContent(context, personalItems, memoryService, auth, i18n),
       ],

       // --- SECTION 2: FAVORITE MUSIC (NEW FEATURE) ---
       if (_selectedTab == 1) ...[
         FavoriteMusicSection(isCaregiver: auth.isCaretaker),
       ],

       // --- SECTION 3: FAVORITE PLACES (NEW FEATURE) ---
       if (_selectedTab == 2) ...[
         FavoritePlaceSection(isCaregiver: auth.isCaretaker),
       ],
     ],
   ),
 );
 }

 // --- RENDERING FOR PERSONAL MEMORIES ---
 List<Widget> _buildMediaCardsContent(
 BuildContext context,
 List<MemoryItem> items,
 MemoryLaneService memoryService,
 AuthService auth,
 I18nService i18n,
 ) {
 final isTamil = i18n.currentLang == 'ta';

 if (items.isEmpty) {
 return [
 ElderCard(
 child: Padding(
 padding: const EdgeInsets.all(20),
 child: Column(
 children: [
 Image.asset(
 'assets/images/camera_icon.png',
 width: 54,
 height: 54,
 fit: BoxFit.contain,
 errorBuilder: (ctx, err, stack) => const Text('📸', style: TextStyle(fontSize: 38)),
 ),
 const SizedBox(height: 10),
 Text(
 isTamil ? 'இன்னும் எதுவும் சேர்க்கப்படவில்லை.' : 'No items added yet.',
 textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
 ),
 ],
 ),
 ),
 ),
 ];
 }

 return items.map<Widget>((m) {
 final titleStr = m.titleKey.isNotEmpty ? i18n.translate(m.titleKey) : m.title;
 final storyStr = m.storyKey.isNotEmpty ? i18n.translate(m.storyKey) : m.storyNote;
 final isVideo = m.mediaType == 'video';

 return Padding(
 padding: const EdgeInsets.only(bottom: 16),
 child: ElderCard(
 padding: EdgeInsets.zero,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Thumbnail Image or Video
 Stack(
 alignment: Alignment.center,
 children: [
 GestureDetector(
 onTap: isVideo ? () => _showVideoPlayerModal(context, m) : () => _showEnlargedImageModal(context, m),
 child: ClipRRect(
 borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
 child: isVideo
 ? MemoryVideoThumbnailWidget(videoPath: m.videoPath ?? m.imagePath, height: 195)
 : Stack(
 alignment: Alignment.bottomRight,
 children: [
 _buildMemoryImage(m.imagePath, height: 195),
 Container(
 margin: const EdgeInsets.all(8),
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 const Icon(Icons.zoom_in, color: Colors.white, size: 14),
 const SizedBox(width: 4),
 Text(
 isTamil ? 'புகைப்படத்தை பார்' : 'View Photo',
 style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 ),
 if (isVideo)
 GestureDetector(
 onTap: () => _showVideoPlayerModal(context, m),
 child: Container(
 height: 195,
 width: double.infinity,
 color: Colors.black38,
 alignment: Alignment.center,
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 const Icon(Icons.play_circle_fill, color: Colors.white, size: 58),
 const SizedBox(height: 4),
 Text(
 isTamil ? 'வீடியோவை பார் ' : 'Play Video Clip ',
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
 ),
 ],
 ),
 ),
 ),
 Positioned(
 top: 12,
 right: 12,
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(
 color: isVideo ? const Color(0xFFDC2626) : const Color(0xFF1B2824).withOpacity(0.8),
 borderRadius: BorderRadius.circular(12),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(isVideo ? Icons.videocam : Icons.photo_camera, color: Colors.white, size: 14),
 const SizedBox(width: 4),
 Text(
 isVideo ? (isTamil ? 'காணொளி' : 'Video') : (isTamil ? 'புகைப்படம்' : 'Photo'),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
 ),
 ],
 ),
 ),
 ),
 ],
 ),

 // Card Body Details
 Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Text(
 titleStr,
 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0)),
 ),
 ),
 const SizedBox(width: 8),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
 decoration: BoxDecoration(color: const Color(0xFFE6F4F1), borderRadius: BorderRadius.circular(8)),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 const Icon(Icons.calendar_month, size: 13, color: Color(0xFF61C5B0)),
 const SizedBox(width: 4),
 Text(m.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0))),
 ],
 ),
 ),
 if (auth.isCaretaker || m.isCustom)
 IconButton(
 icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
 onPressed: () => _confirmDelete(context, memoryService, m),
 ),
 ],
 ),
 if (storyStr.isNotEmpty) ...[
 const SizedBox(height: 8),
 Text(storyStr, style: const TextStyle(fontSize: 13, color: Color(0xFF1B2824))),
 ],

 // Recorded Voice Note / Audio Story Playback Bar
 const SizedBox(height: 12),
 Consumer<MemoryLaneService>(
 builder: (ctx, memSrv, _) {
 final isPlayingThis = memSrv.currentlyPlayingId == m.id && memSrv.isPlayingVoiceNote;
 final hasVoiceFile = (m.voiceNotePath != null && m.voiceNotePath!.isNotEmpty) ||
 (m.audioPath != null && m.audioPath!.isNotEmpty);

 return Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 decoration: BoxDecoration(
 color: isPlayingThis ? const Color(0xFFECFDF5) : (hasVoiceFile ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB)),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: isPlayingThis ? const Color(0xFF10B981) : (hasVoiceFile ? const Color(0xFF34D399) : Colors.grey.shade300),
 width: 1.2,
 ),
 ),
 child: Row(
 children: [
 ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: isPlayingThis ? const Color(0xFFDC2626) : (hasVoiceFile ? const Color(0xFF10B981) : const Color(0xFF23B39B)),
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 icon: Icon(isPlayingThis ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 18),
 label: Text(
 isPlayingThis
 ? (isTamil ? 'நிறுத்து' : 'Pause')
 : (hasVoiceFile
 ? (isTamil ? 'குரல் குறிப்பை இயக்கு ️' : 'Play Voice Note ️')
 : (isTamil ? 'கதையை வாசி ️' : 'Read Audio Story ️')),
 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
 ),
 onPressed: () {
 memSrv.playVoiceNote(m, i18n.currentLang, customText: storyStr.isNotEmpty ? storyStr : m.title);
 },
 ),
 const SizedBox(width: 10),
 Expanded(
 child: Text(
 isPlayingThis
 ? (isTamil ? ' ஒலி இயங்குகிறது...' : ' Playing voice note...')
 : (hasVoiceFile
 ? (isTamil ? '️ பதிவு செய்யப்பட்ட குரல் உள்ளது' : '️ Recorded Voice Note')
 : (isTamil ? 'ஒலி வடிவில் கேட்க தட்டவும்' : 'Tap to listen to audio')),
 style: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.bold,
 color: isPlayingThis ? const Color(0xFF10B981) : (hasVoiceFile ? const Color(0xFF047857) : Colors.grey.shade700),
 ),
 ),
 ),
 ],
 ),
 );
 },
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 );
 }).toList();
 }
}

// Memory Video Player Dialog Widget
class MemoryVideoPlayerDialog extends StatefulWidget {
 final MemoryItem item;
 const MemoryVideoPlayerDialog({Key? key, required this.item}) : super(key: key);

 @override
 State<MemoryVideoPlayerDialog> createState() => _MemoryVideoPlayerDialogState();
}

class _MemoryVideoPlayerDialogState extends State<MemoryVideoPlayerDialog> {
 VideoPlayerController? _controller;
 bool _isInit = false;
 bool _hasError = false;
 String _errorMsg = '';

 @override
 void initState() {
 super.initState();
 _initVideo();
 }

   Future<void> _initVideo() async {
    final vPath = widget.item.videoPath ?? widget.item.imagePath;
    if (vPath.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = 'Video path is empty.';
        });
      }
      return;
    }

    try {
      if (vPath.startsWith('/') || vPath.contains('file://') || vPath.contains('data/')) {
        final cleanPath = vPath.replaceAll('file://', '');
        final file = File(cleanPath);
        if (file.existsSync()) {
          _controller = VideoPlayerController.file(file);
        } else {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMsg = 'Video file not found on device.';
            });
          }
          return;
        }
      } else if (vPath.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(vPath));
      } else {
        _controller = VideoPlayerController.asset(vPath);
      }

      await _controller!.initialize();
      _controller!.setLooping(true);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInit = true;
        });
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = 'Could not play video: $e';
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
 String twoDigits(int n) => n.toString().padLeft(2, '0');
 final minutes = twoDigits(duration.inMinutes.remainder(60));
 final seconds = twoDigits(duration.inSeconds.remainder(60));
 return '$minutes:$seconds';
 }

 @override
 Widget build(BuildContext context) {
 return Dialog(
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
 backgroundColor: Colors.white,
 insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
 decoration: const BoxDecoration(
 color: Color(0xFF1B2824),
 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(
 child: Text(
 ' ${widget.item.title}',
 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
 ),
 ),
 IconButton(
 icon: const Icon(Icons.close, color: Colors.white),
 onPressed: () => Navigator.pop(context),
 ),
 ],
 ),
 ),
 Container(
 height: 250,
 color: Colors.black,
 child: _hasError
 ? Center(
 child: Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 const Icon(Icons.video_camera_back, color: Colors.amber, size: 48),
 const SizedBox(height: 8),
 Text(_errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
 ],
 ),
 ),
 )
 : (_isInit && _controller != null && _controller!.value.isInitialized)
 ? Stack(
 alignment: Alignment.bottomCenter,
 children: [
 Center(
 child: AspectRatio(
 aspectRatio: _controller!.value.aspectRatio,
 child: VideoPlayer(_controller!),
 ),
 ),
 Container(
 color: Colors.black45,
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
 child: Row(
 children: [
 IconButton(
 icon: Icon(
 _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
 color: const Color(0xFF23B39B),
 size: 32,
 ),
 onPressed: () {
 setState(() {
 _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
 });
 },
 ),
 const SizedBox(width: 8),
 Expanded(
 child: VideoProgressIndicator(
 _controller!,
 allowScrubbing: true,
 colors: const VideoProgressColors(
 playedColor: Color(0xFF23B39B),
 bufferedColor: Colors.white30,
 backgroundColor: Colors.white10,
 ),
 ),
 ),
 const SizedBox(width: 8),
 ValueListenableBuilder(
 valueListenable: _controller!,
 builder: (context, VideoPlayerValue val, child) {
 return Text(
 '${_formatDuration(val.position)} / ${_formatDuration(val.duration)}',
 style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
 );
 },
 ),
 ],
 ),
 ),
 ],
 )
 : const Center(child: CircularProgressIndicator(color: Color(0xFF23B39B))),
 ),
 Padding(
 padding: const EdgeInsets.all(16),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text('Added On: ${widget.item.date}', style: const TextStyle(fontSize: 13, color: Color(0xFF23B39B), fontWeight: FontWeight.bold)),
 if (widget.item.storyNote.isNotEmpty) ...[
 const SizedBox(height: 8),
 Text(widget.item.storyNote, style: const TextStyle(fontSize: 13, color: Colors.black87)),
 ],
 const SizedBox(height: 12),
 Align(
 alignment: Alignment.centerRight,
 child: ElevatedButton.icon(
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF23B39B),
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
 ),
 onPressed: () => Navigator.pop(context),
 icon: const Icon(Icons.check, color: Colors.white, size: 16),
 label: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }
}

// Memory Video Thumbnail Helper Widget
class MemoryVideoThumbnailWidget extends StatefulWidget {
 final String videoPath;
 final double height;
 const MemoryVideoThumbnailWidget({Key? key, required this.videoPath, this.height = 195}) : super(key: key);

 @override
 State<MemoryVideoThumbnailWidget> createState() => _MemoryVideoThumbnailWidgetState();
}

class _MemoryVideoThumbnailWidgetState extends State<MemoryVideoThumbnailWidget> {
 VideoPlayerController? _controller;
 bool _isInit = false;

 @override
 void initState() {
 super.initState();
 _initThumb();
 }

 Future<void> _initThumb() async {
 try {
 if (widget.videoPath.startsWith('/') || widget.videoPath.contains('file://') || widget.videoPath.contains('data/')) {
 final cleanPath = widget.videoPath.replaceAll('file://', '');
 final file = File(cleanPath);
 if (file.existsSync()) {
 _controller = VideoPlayerController.file(file);
 } else {
 return;
 }
 } else if (widget.videoPath.startsWith('http')) {
 _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
 } else {
 _controller = VideoPlayerController.asset(widget.videoPath);
 }
 await _controller!.initialize();
 await _controller!.seekTo(const Duration(milliseconds: 500));
 if (mounted) {
 setState(() {
 _isInit = true;
 });
 }
 } catch (_) {}
 }

 @override
 void dispose() {
 _controller?.dispose();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 if (_isInit && _controller != null && _controller!.value.isInitialized) {
 return SizedBox(
 height: widget.height,
 width: double.infinity,
 child: AspectRatio(
 aspectRatio: _controller!.value.aspectRatio,
 child: VideoPlayer(_controller!),
 ),
 );
 }
 return Container(
 height: widget.height,
 color: Colors.black87,
 child: const Center(
 child: Icon(Icons.movie_creation_rounded, color: Color(0xFF61C5B0), size: 48),
 ),
 );
 }
}
