import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/memory_item.dart';
import '../services/memory_lane_service.dart';
import '../services/i18n_service.dart';
import 'elder_card.dart';

class FavoriteMusicSection extends StatefulWidget {
  final bool isCaregiver;

  const FavoriteMusicSection({
    Key? key,
    required this.isCaregiver,
  }) : super(key: key);

  @override
  State<FavoriteMusicSection> createState() => _FavoriteMusicSectionState();
}

class _FavoriteMusicSectionState extends State<FavoriteMusicSection> {
  void _showAddMusicModal(BuildContext context) {
    final i18n = Provider.of<I18nService>(context, listen: false);
    final memoryService = Provider.of<MemoryLaneService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';

    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    String? selectedFilePath;
    String? selectedFileName;
    int selectedFileBytes = 0;
    String uploadStatus = 'idle'; // 'idle', 'uploading', 'saving', 'saved', 'failed'
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                        Row(
                          children: [
                            const Text('🎵', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              isTamil ? 'பிடித்த இசை சேர்' : 'Add Favorite Music',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B2824),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // File Selection Button
                    GestureDetector(
                      onTap: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['mp3'],
                          );

                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.single;
                            final path = file.path;

                            if (path == null) {
                              setModalState(() {
                                errorMessage = isTamil ? 'கோப்பு பாதை செல்லுபடியாகவில்லை' : 'Invalid file path';
                              });
                              return;
                            }

                            // 1. Format validation (MP3 only)
                            if (!path.toLowerCase().endsWith('.mp3')) {
                              setModalState(() {
                                errorMessage = isTamil
                                    ? 'தயவுசெய்து MP3 ஆடியோ கோப்பை மட்டும் தேர்ந்தெடுக்கவும்.'
                                    : 'Please select an MP3 audio file only.';
                              });
                              return;
                            }

                            // 2. File size validation (Max 50 MB)
                            final ioFile = File(path);
                            final bytes = ioFile.existsSync() ? ioFile.lengthSync() : file.size;
                            if (bytes > 50 * 1024 * 1024) {
                              setModalState(() {
                                errorMessage = isTamil
                                    ? 'கோப்பு மிகப்பெரியது (அதிகபட்சம் 50MB). சிறிய கோப்பை தேர்ந்தெடுக்கவும்.'
                                    : 'File is too large (max 50MB). Please choose a smaller file.';
                              });
                              return;
                            }

                            // Auto-populate title if empty
                            String suggestedTitle = file.name.replaceAll(RegExp(r'\.mp3$', caseSensitive: false), '');
                            if (titleCtrl.text.isEmpty) {
                              titleCtrl.text = suggestedTitle;
                            }

                            setModalState(() {
                              selectedFilePath = path;
                              selectedFileName = file.name;
                              selectedFileBytes = bytes;
                              errorMessage = '';
                            });
                          }
                        } catch (e) {
                          setModalState(() {
                            errorMessage = 'File pick error: $e';
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: selectedFilePath != null ? const Color(0xFFECFDF5) : const Color(0xFFF0FDF9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedFilePath != null ? const Color(0xFF10B981) : const Color(0xFF61C5B0),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              selectedFilePath != null ? Icons.check_circle : Icons.audio_file_rounded,
                              size: 38,
                              color: selectedFilePath != null ? const Color(0xFF10B981) : const Color(0xFF23B39B),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedFilePath != null
                                  ? (selectedFileName ?? 'MP3 Selected ✓')
                                  : (isTamil ? 'சாதனத்திலிருந்து MP3 கோப்பைத் தேர்ந்தெடுக்கவும்' : 'Select MP3 file from device'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2824)),
                              textAlign: TextAlign.center,
                            ),
                            if (selectedFileBytes > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${(selectedFileBytes / (1024 * 1024)).toStringAsFixed(1)} MB • MP3 Audio',
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (errorMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Song Title Field (Required)
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: isTamil ? 'பாடல் தலைப்பு *' : 'Song Title *',
                        hintText: isTamil ? 'எ.கா. Ilaya Nila' : 'e.g. Ilaya Nila',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.music_note, color: Color(0xFF61C5B0)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Artist Name Field (Optional)
                    TextField(
                      controller: artistCtrl,
                      decoration: InputDecoration(
                        labelText: isTamil ? 'பாடகர் / கலைஞர் (விருப்பத்தேர்வு)' : 'Artist Name (Optional)',
                        hintText: isTamil ? 'எ.கா. SPB' : 'e.g. SPB',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF61C5B0)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description Field (Optional)
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: isTamil ? 'விளக்கம் (விருப்பத்தேர்வு)' : 'Description (Optional)',
                        hintText: isTamil ? 'அவருக்கு மிகவும் பிடித்த பாடல்' : 'One of his favorite songs',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.notes, color: Color(0xFF61C5B0)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload Progress / Saving / Success Status Indicator
                    if (uploadStatus == 'uploading') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3B82F6)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF3B82F6)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isTamil ? 'பதிவேற்றப்படுகிறது... காத்திருக்கவும்' : 'Uploading... Please wait',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else if (uploadStatus == 'saving') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3B82F6)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF3B82F6)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isTamil ? 'சேமிக்கப்படுகிறது...' : 'Saving...',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else if (uploadStatus == 'saved') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isTamil ? 'இசை சேமிக்கப்பட்டது ✓' : 'Saved ✓',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Upload Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: uploadStatus == 'saved'
                            ? const Color(0xFF10B981)
                            : const Color(0xFF23B39B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: (uploadStatus == 'uploading' || uploadStatus == 'saving')
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : Icon(
                              uploadStatus == 'saved'
                                  ? Icons.check_circle
                                  : (uploadStatus == 'failed' ? Icons.refresh : Icons.cloud_upload),
                              color: Colors.white,
                            ),
                      label: Text(
                        uploadStatus == 'uploading'
                            ? (isTamil ? 'பதிவேற்றப்படுகிறது... காத்திருக்கவும்' : 'Uploading... Please wait')
                            : (uploadStatus == 'saving'
                                ? (isTamil ? 'சேமிக்கப்படுகிறது...' : 'Saving...')
                                : (uploadStatus == 'saved'
                                    ? (isTamil ? 'சேமிக்கப்பட்டது ✓' : 'Saved ✓')
                                    : (uploadStatus == 'failed'
                                        ? (isTamil ? 'பதிவேற்றம் தோல்வி — மீண்டும் முயல்க' : 'Upload failed — Try again')
                                        : (isTamil ? 'இசையை பதிவேற்று' : 'Upload Music')))),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: (uploadStatus == 'uploading' || uploadStatus == 'saving' || uploadStatus == 'saved')
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              final artist = artistCtrl.text.trim();
                              final desc = descCtrl.text.trim();

                              if (selectedFilePath == null || selectedFilePath!.isEmpty) {
                                setModalState(() {
                                  errorMessage = isTamil ? 'தயவுசெய்து ஒரு MP3 கோப்பைத் தேர்ந்தெடுக்கவும்.' : 'Please select an MP3 file.';
                                });
                                return;
                              }

                              if (title.isEmpty) {
                                setModalState(() {
                                  errorMessage = isTamil ? 'பாடல் தலைப்பை உள்ளிடவும்.' : 'Please enter the song title.';
                                });
                                return;
                              }

                              setModalState(() {
                                errorMessage = '';
                                uploadStatus = 'uploading';
                              });

                              try {
                                await memoryService.addFavoriteMusic(
                                  title: title,
                                  artist: artist.isNotEmpty ? artist : null,
                                  description: desc.isNotEmpty ? desc : null,
                                  audioPath: selectedFilePath!,
                                  fileName: selectedFileName,
                                  createdByRole: 'caretaker',
                                  onStatusChanged: (status) {
                                    if (modalCtx.mounted) {
                                      setModalState(() {
                                        uploadStatus = status;
                                      });
                                    }
                                  },
                                );

                                if (modalCtx.mounted) {
                                  setModalState(() {
                                    uploadStatus = 'saved';
                                  });
                                }

                                await Future.delayed(const Duration(milliseconds: 900));

                                if (modalCtx.mounted) {
                                  Navigator.pop(modalCtx);
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF10B981),
                                      content: Text(
                                        isTamil ? 'இசை வெற்றிகரமாக பதிவேற்றப்பட்டது!' : 'Favorite music uploaded successfully!',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                }
                              } catch (err) {
                                if (modalCtx.mounted) {
                                  setModalState(() {
                                    uploadStatus = 'failed';
                                    errorMessage = isTamil
                                        ? 'பதிவேற்றம் தோல்வியடைந்தது — மீண்டும் முயல்க ($err)'
                                        : 'Upload failed — Try again ($err)';
                                  });
                                }
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

  void _confirmDeleteMusic(BuildContext context, MemoryLaneService memoryService, MemoryItem item) {
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isTamil ? 'பாடலை நீக்கவா?' : 'Delete Song?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isTamil ? '"${item.title}" பாடல் பட்டியலிலிருந்து நீக்கப்படும்.' : 'Are you sure you want to delete "${item.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isTamil ? 'ரத்து' : 'Cancel',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
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
                SnackBar(content: Text(isTamil ? 'பாடல் நீக்கப்பட்டது' : 'Song deleted')),
              );
            },
            child: Text(
              isTamil ? 'நீக்கு 🗑️' : 'Delete 🗑️',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final i18n = Provider.of<I18nService>(context);
    final memoryService = Provider.of<MemoryLaneService>(context);
    final isTamil = i18n.currentLang == 'ta';
    final musicTracks = memoryService.musicMemories;

    final playingId = memoryService.currentlyPlayingMusicId;
    final isPlaying = memoryService.isMusicPlaying;
    final pos = memoryService.musicPosition;
    final dur = memoryService.musicDuration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('❤️', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  isTamil ? 'பிடித்த இசை' : 'Favorite Music',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                ),
              ],
            ),
            if (widget.isCaregiver)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF23B39B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: Text(
                  isTamil ? '+ இசை சேர்' : '+ Add Music',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _showAddMusicModal(context),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Caregiver Add Music Quick Action Banner
        if (widget.isCaregiver)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF61C5B0), width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF23B39B), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isTamil
                        ? 'பெரியவருக்கு பிடித்த MP3 பாடல்களை பதிவேற்றலாம். பதிவேற்றியதும் உடனடியாக பெரியவர் திரையில் தோன்றும்.'
                        : 'Upload elder\'s favorite MP3 songs. Uploaded music is instantly synced and available to elder.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1B2824)),
                  ),
                ),
              ],
            ),
          ),

        // Empty State
        if (musicTracks.isEmpty)
          ElderCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Column(
                children: [
                  const Text('🎵', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    isTamil ? 'உங்கள் விருப்பமான இசை இங்கே தோன்றும்.' : 'Your favorite music will appear here.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.isCaregiver
                        ? (isTamil ? 'மேலே உள்ள "+ இசை சேர்" பொத்தானைத் தட்டவும்.' : 'Tap "+ Add Music" above to upload an MP3 track.')
                        : (isTamil ? 'பராமரிப்பாளர் சேர்த்த இசை இங்கே கிடைக்கும்.' : 'Music uploaded by your caregiver will be displayed here.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...musicTracks.map((item) {
            final isCurrentTrack = playingId == item.id;
            final isTrackPlaying = isCurrentTrack && isPlaying;
            final isOffline = memoryService.isItemOfflineAvailable(item);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ElderCard(
                backgroundColor: isCurrentTrack ? const Color(0xFFF0FDF9) : Colors.white,
                border: Border.all(
                  color: isCurrentTrack ? const Color(0xFF10B981) : const Color(0xFF61C5B0).withOpacity(0.35),
                  width: isCurrentTrack ? 1.8 : 1.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Artist Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrentTrack ? const Color(0xFF10B981) : const Color(0xFFE6F4F1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isTrackPlaying ? Icons.music_note : Icons.music_note_outlined,
                            color: isCurrentTrack ? Colors.white : const Color(0xFF23B39B),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B2824),
                                ),
                              ),
                              if (item.artist != null && item.artist!.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  item.artist!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF61C5B0),
                                  ),
                                ),
                              ],
                              if (item.storyNote.isNotEmpty && item.storyNote != 'Favourite music track for Elder.') ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.storyNote,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Offline Badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOffline ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOffline ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isOffline ? (isTamil ? 'ஆஃப்லைனில் கிடைக்கும் ✓' : 'Available Offline ✓') : 'Downloaded ✓',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isOffline ? const Color(0xFF047857) : const Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                            if (widget.isCaregiver) ...[
                              const SizedBox(height: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _confirmDeleteMusic(context, memoryService, item),
                                tooltip: isTamil ? 'நீக்கு' : 'Delete',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Playback Controls Row (Large, elderly-friendly)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Large Play / Pause button
                              SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isTrackPlaying ? const Color(0xFFDC2626) : const Color(0xFF23B39B),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 18),
                                  ),
                                  icon: Icon(
                                    isTrackPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  label: Text(
                                    isTrackPlaying ? (isTamil ? 'நிறுத்து' : 'Pause') : (isTamil ? 'இயக்கு' : 'Play'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  onPressed: () {
                                    memoryService.playMusic(item);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTrackPlaying
                                          ? (isTamil ? 'இசை ஒலிக்கிறது... 🎵' : 'Playing Music... 🎵')
                                          : (isCurrentTrack ? (isTamil ? 'இடைநிறுத்தப்பட்டது' : 'Paused') : (isTamil ? 'கேட்க தட்டவும்' : 'Tap to Play')),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isTrackPlaying ? const Color(0xFF10B981) : Colors.grey.shade700,
                                      ),
                                    ),
                                    if (isCurrentTrack && dur > Duration.zero) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isCurrentTrack)
                                IconButton(
                                  icon: const Icon(Icons.stop_circle, color: Color(0xFFDC2626), size: 28),
                                  onPressed: () => memoryService.stopMusic(),
                                  tooltip: isTamil ? 'நிறுத்து' : 'Stop',
                                ),
                            ],
                          ),

                          // Seek Bar if this track is currently active
                          if (isCurrentTrack && dur > Duration.zero) ...[
                            const SizedBox(height: 6),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                activeTrackColor: const Color(0xFF23B39B),
                                inactiveTrackColor: Colors.grey.shade300,
                                thumbColor: const Color(0xFF23B39B),
                              ),
                              child: Slider(
                                value: pos.inMilliseconds.toDouble().clamp(0.0, dur.inMilliseconds.toDouble()),
                                max: dur.inMilliseconds.toDouble(),
                                onChanged: (val) {
                                  memoryService.seekMusic(Duration(milliseconds: val.toInt()));
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
