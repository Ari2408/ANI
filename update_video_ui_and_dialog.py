import re

screen_path = '/home/dinakar3108/Downloads/PR1/lib/screens/memory_lane_screen.dart'
with open(screen_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Replace save memory callback in _showAddMemoryDialog
old_add_save = """                        Navigator.pop(modalCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(i18n.translate('personalMemorySavedToast'))),
                        );"""

new_add_save = """                        Navigator.pop(modalCtx);
                        if (selectedMediaType == 'video') {
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              backgroundColor: const Color(0xFFFDF0E6),
                              title: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF23B39B), size: 30),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      Provider.of<I18nService>(context, listen: false).translate('videoSavedSuccessTitle'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B2824)),
                                    ),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Provider.of<I18nService>(context, listen: false).translate('videoSavedSuccessDesc'),
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF1B2824)),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF61C5B0)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.movie_creation_rounded, color: Color(0xFFF97316), size: 24),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            title.isNotEmpty ? title : 'Personal Memory Video',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2824)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF23B39B),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                                  label: const Text('OK 🎬', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(i18n.translate('personalMemorySavedToast'))),
                          );
                        }"""

code = code.replace(old_add_save, new_add_save)

# Replace save memory callback in _showEditMemoryDialog
old_edit_save = """                        Navigator.pop(modalCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(i18n.translate('memoryUpdatedSuccessToast'))),
                        );"""

new_edit_save = """                        Navigator.pop(modalCtx);
                        if (selectedMediaType == 'video') {
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              backgroundColor: const Color(0xFFFDF0E6),
                              title: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF23B39B), size: 30),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      Provider.of<I18nService>(context, listen: false).translate('videoSavedSuccessTitle'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B2824)),
                                    ),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Provider.of<I18nService>(context, listen: false).translate('videoSavedSuccessDesc'),
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF1B2824)),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF61C5B0)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.movie_creation_rounded, color: Color(0xFFF97316), size: 24),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            title.isNotEmpty ? title : 'Personal Memory Video',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B2824)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF23B39B),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                                  label: const Text('OK 🎬', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(i18n.translate('memoryUpdatedSuccessToast'))),
                          );
                        }"""

code = code.replace(old_edit_save, new_edit_save)

with open(screen_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Updated video save success dialog popup in memory_lane_screen.dart.")
