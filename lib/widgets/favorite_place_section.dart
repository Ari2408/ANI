import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/memory_item.dart';
import '../services/memory_lane_service.dart';
import '../services/i18n_service.dart';
import 'elder_card.dart';

class FavoritePlaceSection extends StatefulWidget {
  final bool isCaregiver;

  const FavoritePlaceSection({
    Key? key,
    required this.isCaregiver,
  }) : super(key: key);

  @override
  State<FavoritePlaceSection> createState() => _FavoritePlaceSectionState();
}

class _FavoritePlaceSectionState extends State<FavoritePlaceSection> {
  final ImagePicker _picker = ImagePicker();

  void _showAddPlaceModal(BuildContext context) {
    final i18n = Provider.of<I18nService>(context, listen: false);
    final memoryService = Provider.of<MemoryLaneService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    List<String> selectedPhotos = [];
    String? selectedVideoPath;
    String? recordedVoicePath;
    bool hasRecordedVoice = false;
    String saveStatus = 'idle'; // 'idle', 'saving', 'saved', 'failed'
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
            final isRecording = memoryService.isRecording;
            final recSecs = memoryService.recordSeconds;

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
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('📍', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              isTamil ? 'பிடித்த இடம் சேர்' : 'Add Favorite Place',
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

                    // Field 1: Place Name
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: isTamil ? 'இடத்தின் பெயர் *' : 'Place Name *',
                        hintText: isTamil ? 'எ.கா. மெரினா கடற்கரை' : 'e.g. Marina Beach',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF61C5B0)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Field 2: Short Description
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: isTamil ? 'சுருக்கமான விளக்கம்' : 'Short Description',
                        hintText: isTamil
                            ? 'அவர் மாலை நேரத்தை கழிக்க விரும்பிய பிடித்த இடங்களில் ஒன்று.'
                            : 'One of his favorite places where he used to spend evenings.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.description, color: Color(0xFF61C5B0)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Field 3: Photo Upload (Single or Multiple)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isTamil ? 'புகைப்படங்கள் (${selectedPhotos.length})' : 'Photos (${selectedPhotos.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B2824)),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF23B39B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                icon: const Icon(Icons.add_photo_alternate, size: 16, color: Colors.white),
                                label: Text(
                                  isTamil ? '+ புகைப்படங்கள்' : '+ Add Photos',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  try {
                                    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
                                    if (images.isNotEmpty) {
                                      setModalState(() {
                                        for (final img in images) {
                                          if (!selectedPhotos.contains(img.path)) {
                                            selectedPhotos.add(img.path);
                                          }
                                        }
                                      });
                                    }
                                  } catch (e) {
                                    setModalState(() {
                                      errorMessage = 'Image pick error: $e';
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          if (selectedPhotos.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: selectedPhotos.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, idx) {
                                  final p = selectedPhotos[idx];
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          File(p),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              selectedPhotos.removeAt(idx);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Field 4: Video Upload
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isTamil ? 'காணொளி (வீடியோ)' : 'Video',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B2824)),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF97316),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                icon: const Icon(Icons.videocam, size: 16, color: Colors.white),
                                label: Text(
                                  selectedVideoPath != null
                                      ? (isTamil ? 'மாற்று' : 'Replace Video')
                                      : (isTamil ? '+ வீடியோ சேர்' : '+ Add Video'),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  try {
                                    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                                    if (video != null) {
                                      setModalState(() {
                                        selectedVideoPath = video.path;
                                      });
                                    }
                                  } catch (e) {
                                    setModalState(() {
                                      errorMessage = 'Video pick error: $e';
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          if (selectedVideoPath != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF97316)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFFF97316), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isTamil ? 'வீடியோ தேர்ந்தெடுக்கப்பட்டது ✓' : 'Video selected ✓',
                                      style: const TextStyle(color: Color(0xFFC2410C), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                                    onPressed: () {
                                      setModalState(() {
                                        selectedVideoPath = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Field 5: Voice Story / Narration Recording
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isRecording
                            ? const Color(0xFFFFF0F0)
                            : (hasRecordedVoice ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isRecording
                              ? const Color(0xFFDC2626)
                              : (hasRecordedVoice ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isRecording ? Icons.graphic_eq : Icons.mic,
                                color: isRecording
                                    ? const Color(0xFFDC2626)
                                    : (hasRecordedVoice ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isTamil ? '🎙️ இடத்தின் குரல் கதை / விவரிப்பு' : '🎙️ Voice Story / Narration',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isRecording ? const Color(0xFFDC2626) : const Color(0xFF1B2824),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isTamil
                                ? 'எ.கா: "இது மெரினா கடற்கரை. நாம் ஒவ்வொரு ஞாயிற்றுக்கிழமையும் இங்கு வருவோம்..."'
                                : 'e.g. "This is Marina Beach. We used to come here every Sunday evening. You loved watching the sunset here..."',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              // Record / Stop Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isRecording
                                      ? const Color(0xFFDC2626)
                                      : (hasRecordedVoice ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: Icon(
                                  isRecording ? Icons.stop : (hasRecordedVoice ? Icons.refresh : Icons.fiber_manual_record),
                                  color: Colors.white,
                                  size: 16,
                                ),
                                label: Text(
                                  isRecording
                                      ? (isTamil ? 'நிறுத்து ($recSecs வி)' : 'Stop ($recSecs s)')
                                      : (hasRecordedVoice
                                          ? (isTamil ? 'மீண்டும் பதிவு செய்' : 'Re-record')
                                          : (isTamil ? 'பதிவு செய்' : 'Start Recording')),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                onPressed: () async {
                                  if (!isRecording) {
                                    // Request microphone permission only when user taps Record
                                    final ok = await memoryService.startRecording(langCode: i18n.currentLang);
                                    if (!ok) {
                                      setModalState(() {
                                        errorMessage = isTamil
                                            ? 'கதையை பதிவு செய்ய மைக்ரோஃபோன் அனுமதி தேவை.'
                                            : 'Microphone permission is required to record the story.';
                                      });
                                    } else {
                                      setModalState(() {
                                        errorMessage = '';
                                      });
                                    }
                                  } else {
                                    final path = await memoryService.stopRecording();
                                    setModalState(() {
                                      recordedVoicePath = path;
                                      hasRecordedVoice = path != null && path.isNotEmpty;
                                    });
                                  }
                                },
                              ),

                              // Preview Play Button
                              if (hasRecordedVoice && !isRecording && recordedVoicePath != null) ...[
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF23B39B),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                                  label: Text(
                                    isTamil ? 'கேள்' : 'Play',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  onPressed: () {
                                    final tempItem = MemoryItem(
                                      id: 'temp_preview',
                                      title: 'Preview',
                                      date: '',
                                      imagePath: '',
                                      audioPath: recordedVoicePath,
                                      voiceNotePath: recordedVoicePath,
                                      storyNote: '',
                                    );
                                    memoryService.playVoiceNote(tempItem, i18n.currentLang);
                                  },
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  tooltip: isTamil ? 'நீக்கு' : 'Delete',
                                  onPressed: () {
                                    setModalState(() {
                                      recordedVoicePath = null;
                                      hasRecordedVoice = false;
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Progress / Success Indicator
                    if (saveStatus == 'saving') ...[
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
                                isTamil ? 'சேமிக்கப்படுகிறது... காத்திருக்கவும்' : 'Saving... Please wait',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else if (saveStatus == 'saved') ...[
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
                                isTamil ? 'இடம் வெற்றிகரமாக சேமிக்கப்பட்டது ✓' : 'Saved ✓',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Save Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: saveStatus == 'saved'
                            ? const Color(0xFF10B981)
                            : const Color(0xFF23B39B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: saveStatus == 'saving'
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : Icon(
                              saveStatus == 'saved'
                                  ? Icons.check_circle
                                  : (saveStatus == 'failed' ? Icons.refresh : Icons.check),
                              color: Colors.white,
                            ),
                      label: Text(
                        saveStatus == 'saving'
                            ? (isTamil ? 'சேமிக்கப்படுகிறது...' : 'Saving...')
                            : (saveStatus == 'saved'
                                ? (isTamil ? 'சேமிக்கப்பட்டது ✓' : 'Saved ✓')
                                : (saveStatus == 'failed'
                                    ? (isTamil ? 'சேமிக்க முடியவில்லை — மீண்டும் முயல்க' : 'Save failed — Try again')
                                    : (isTamil ? 'பிடித்த இடத்தை சேமி' : 'Save Favorite Place'))),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: (saveStatus == 'saving' || saveStatus == 'saved')
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final desc = descCtrl.text.trim();

                              if (name.isEmpty) {
                                setModalState(() {
                                  errorMessage = isTamil ? 'இடத்தின் பெயரை உள்ளிடவும்.' : 'Please enter place name.';
                                });
                                return;
                              }

                              if (memoryService.isRecording) {
                                final p = await memoryService.stopRecording();
                                recordedVoicePath = p;
                              }

                              setModalState(() {
                                saveStatus = 'saving';
                                errorMessage = '';
                              });

                              try {
                                await memoryService.addFavoritePlace(
                                  placeName: name,
                                  description: desc.isNotEmpty ? desc : 'Favorite place added by caregiver.',
                                  photos: selectedPhotos,
                                  videoPath: selectedVideoPath,
                                  audioPath: recordedVoicePath,
                                  createdByRole: 'caretaker',
                                  onStatusChanged: (status) {
                                    if (modalCtx.mounted) {
                                      setModalState(() {
                                        saveStatus = status;
                                      });
                                    }
                                  },
                                );

                                if (modalCtx.mounted) {
                                  setModalState(() {
                                    saveStatus = 'saved';
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
                                        isTamil ? 'பிடித்த இடம் வெற்றிகரமாக சேமிக்கப்பட்டது!' : 'Favorite place saved successfully!',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (modalCtx.mounted) {
                                  setModalState(() {
                                    saveStatus = 'failed';
                                    errorMessage = isTamil
                                        ? 'சேமிக்க முடியவில்லை — மீண்டும் முயல்க ($e)'
                                        : 'Save failed — Try again ($e)';
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

  void _confirmDeletePlace(BuildContext context, MemoryLaneService memoryService, MemoryItem item) {
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isTamil ? 'இடத்தை நீக்கவா?' : 'Delete Favorite Place?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isTamil ? '"${item.title}" நீக்கப்படும்.' : 'Are you sure you want to delete "${item.title}"?',
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
                SnackBar(content: Text(isTamil ? 'இடம் நீக்கப்பட்டது' : 'Place deleted')),
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

  void _showVideoDialog(BuildContext context, String videoPath, String title) {
    showDialog(
      context: context,
      builder: (ctx) => _PlaceVideoPlayerModal(videoPath: videoPath, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = Provider.of<I18nService>(context);
    final memoryService = Provider.of<MemoryLaneService>(context);
    final isTamil = i18n.currentLang == 'ta';
    final places = memoryService.placesMemories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('📍', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  isTamil ? 'பிடித்த இடங்கள்' : 'Favorite Places',
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
                icon: const Icon(Icons.add_location_alt, color: Colors.white, size: 18),
                label: Text(
                  isTamil ? '+ இடம் சேர்' : '+ Add Place',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _showAddPlaceModal(context),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Caregiver Quick Action Banner
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
                const Icon(Icons.place_outlined, color: Color(0xFF23B39B), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isTamil
                        ? 'பெரியவருக்கு பிடித்த இடங்களை புகைப்படங்கள், வீடியோ மற்றும் உங்கள் குரல் கதையுடன் உருவாக்கலாம்.'
                        : 'Create memories of elder\'s favorite places with photos, video, and your voice narration story.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1B2824)),
                  ),
                ),
              ],
            ),
          ),

        // Empty State
        if (places.isEmpty)
          ElderCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Column(
                children: [
                  const Text('🏞️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    isTamil
                        ? 'பராமரிப்பாளர் சேர்த்த பிடித்த இடங்கள் இங்கே தோன்றும்.'
                        : 'Favorite places added by your caregiver will appear here.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.isCaregiver
                        ? (isTamil ? 'மேலே உள்ள "+ இடம் சேர்" பொத்தானைத் தட்டவும்.' : 'Tap "+ Add Place" above to add a favorite place memory.')
                        : (isTamil ? 'இன்னும் இடங்கள் எதுவும் சேர்க்கப்படவில்லை.' : 'No favorite places have been added yet.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...places.map((place) {
            final isOffline = memoryService.isItemOfflineAvailable(place);
            final photoList = place.photos.isNotEmpty
                ? place.photos
                : (place.imagePath.isNotEmpty ? [place.imagePath] : <String>[]);
            final hasVideo = place.videoPath != null && place.videoPath!.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElderCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header / Photo Gallery Carousel
                    if (photoList.isNotEmpty) ...[
                      _PlaceGalleryWidget(photos: photoList),
                    ] else ...[
                      Container(
                        height: 180,
                        color: const Color(0xFF61C5B0),
                        child: const Center(child: Icon(Icons.place, color: Colors.white, size: 54)),
                      ),
                    ],

                    // Card Body
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Place Name and Offline Status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Text('❤️ ', style: TextStyle(fontSize: 18)),
                                    Expanded(
                                      child: Text(
                                        place.title,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1B2824),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOffline ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isOffline ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                  ),
                                ),
                                child: Text(
                                  isOffline ? (isTamil ? 'ஆஃப்லைனில் உள்ளது ✓' : 'Available Offline ✓') : 'Downloaded ✓',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isOffline ? const Color(0xFF047857) : const Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                              if (widget.isCaregiver) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () => _confirmDeletePlace(context, memoryService, place),
                                  tooltip: isTamil ? 'நீக்கு' : 'Delete',
                                ),
                              ],
                            ],
                          ),

                          // Short Description
                          if (place.storyNote.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              place.storyNote,
                              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Video Button Section
                          if (hasVideo) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF97316), width: 1.2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.movie_creation, color: Color(0xFFF97316), size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        isTamil ? '🎥 காணொளி' : '🎥 Video',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF9A3412)),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF97316),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                                    label: Text(
                                      isTamil ? 'வீடியோ பார்' : 'Watch Video',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    onPressed: () => _showVideoDialog(context, place.videoPath!, place.title),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Voice Narration Section
                          Consumer<MemoryLaneService>(
                            builder: (ctx, memSrv, _) {
                              final isPlayingVoice = memSrv.currentlyPlayingId == place.id && memSrv.isPlayingVoiceNote;

                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isPlayingVoice ? const Color(0xFFECFDF5) : const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isPlayingVoice ? const Color(0xFF10B981) : const Color(0xFF34D399),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            isPlayingVoice ? Icons.volume_up : Icons.mic,
                                            color: isPlayingVoice ? const Color(0xFF10B981) : const Color(0xFF047857),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              isPlayingVoice
                                                  ? (isTamil ? '🎙️ கதை ஒலிக்கிறது...' : '🎙️ Story Playing...')
                                                  : (isTamil ? '🎙️ உங்கள் நினைவு கதை' : '🎙️ Your Memory Story'),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isPlayingVoice ? const Color(0xFF047857) : const Color(0xFF1B2824),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isPlayingVoice ? const Color(0xFFDC2626) : const Color(0xFF23B39B),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: Icon(
                                        isPlayingVoice ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isPlayingVoice
                                            ? (isTamil ? 'நிறுத்து' : 'Pause')
                                            : (isTamil ? 'கதையை கேள்' : 'Listen to Story'),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      onPressed: () {
                                        memSrv.playVoiceNote(place, i18n.currentLang);
                                      },
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
          }),
      ],
    );
  }
}

// Swipeable Photo Gallery Widget
class _PlaceGalleryWidget extends StatefulWidget {
  final List<String> photos;

  const _PlaceGalleryWidget({Key? key, required this.photos}) : super(key: key);

  @override
  State<_PlaceGalleryWidget> createState() => _PlaceGalleryWidgetState();
}

class _PlaceGalleryWidgetState extends State<_PlaceGalleryWidget> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  Widget _buildPhoto(String path) {
    if (path.startsWith('/') || path.contains('file://') || path.contains('data/')) {
      final clean = path.replaceAll('file://', '');
      final file = File(clean);
      if (file.existsSync()) {
        return Image.file(file, height: 220, width: double.infinity, fit: BoxFit.cover);
      }
    }
    if (path.startsWith('http')) {
      return Image.network(path, height: 220, width: double.infinity, fit: BoxFit.cover);
    }
    return Image.asset(path, height: 220, width: double.infinity, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: widget.photos.length == 1
                ? _buildPhoto(widget.photos.first)
                : PageView.builder(
                    controller: _pageController,
                    itemCount: widget.photos.length,
                    onPageChanged: (idx) => setState(() => _currentIndex = idx),
                    itemBuilder: (ctx, i) => _buildPhoto(widget.photos[i]),
                  ),
          ),
        ),
        if (widget.photos.length > 1) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentIndex + 1} / ${widget.photos.length}',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }
}

// Place Video Modal Player
class _PlaceVideoPlayerModal extends StatefulWidget {
  final String videoPath;
  final String title;

  const _PlaceVideoPlayerModal({
    Key? key,
    required this.videoPath,
    required this.title,
  }) : super(key: key);

  @override
  State<_PlaceVideoPlayerModal> createState() => _PlaceVideoPlayerModalState();
}

class _PlaceVideoPlayerModalState extends State<_PlaceVideoPlayerModal> {
  VideoPlayerController? _controller;
  bool _isInit = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final v = widget.videoPath;
      if (v.startsWith('/') || v.contains('file://') || v.contains('data/')) {
        final clean = v.replaceAll('file://', '');
        final file = File(clean);
        if (file.existsSync()) {
          _controller = VideoPlayerController.file(file);
        } else {
          setState(() => _hasError = true);
          return;
        }
      } else if (v.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(v));
      } else {
        _controller = VideoPlayerController.asset(v);
      }

      await _controller!.initialize();
      _controller!.setLooping(true);
      await _controller!.play();

      if (mounted) {
        setState(() => _isInit = true);
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
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
                    '🎥 ${widget.title}',
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
            height: 240,
            color: Colors.black,
            child: _hasError
                ? const Center(
                    child: Text('Video could not be loaded.', style: TextStyle(color: Colors.white70)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                    color: const Color(0xFF23B39B),
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                                    });
                                  },
                                ),
                                Expanded(
                                  child: VideoProgressIndicator(
                                    _controller!,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(playedColor: Color(0xFF23B39B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator(color: Color(0xFF23B39B))),
          ),
        ],
      ),
    );
  }
}
