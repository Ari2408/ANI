import re

screen_path = '/home/dinakar3108/Downloads/PR1/lib/screens/memory_lane_screen.dart'
with open(screen_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Replace empty video picker box in _showAddMemoryDialog and _showEditMemoryDialog
old_picker_box = """                        GestureDetector(
                          onTap: () {
                            _pickFromMobileGallery(context, 'video', (path) {
                              setModalState(() {
                                selectedVideoPath = path;
                              });
                            });
                          },
                          child: Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF97316), width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.video_call_rounded, size: 38, color: Color(0xFFF97316)),
                                const SizedBox(height: 6),
                                const Text(
                                  'Choose Video from Mobile Gallery 🎥',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2824)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Open phone video gallery',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )"""

new_picker_box = """                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _pickFromMobileGallery(context, 'video', (path) {
                                  setModalState(() {
                                    selectedVideoPath = path;
                                  });
                                });
                              },
                              child: Container(
                                height: 85,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFF97316), width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.video_call_rounded, size: 34, color: Color(0xFFF97316)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Choose Video from Gallery 🎥',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2824)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Pick video from phone storage',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFF97316)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () {
                                  _showGalleryPickerSheet(context, 'video', (path) {
                                    setModalState(() {
                                      selectedVideoPath = path;
                                    });
                                  });
                                },
                                icon: const Icon(Icons.video_library, color: Color(0xFFF97316), size: 18),
                                label: const Text(
                                  'Select Preloaded Sample Video 🎬',
                                  style: TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        )"""

code = code.replace(old_picker_box, new_picker_box)

with open(screen_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Enhanced video picker options in memory_lane_screen.dart.")
