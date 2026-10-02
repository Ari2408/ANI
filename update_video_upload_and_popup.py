import re

# 1. Update i18n_service.dart to add videoSavedSuccessTitle and videoSavedSuccessDesc
i18n_path = '/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart'
with open(i18n_path, 'r', encoding='utf-8') as f:
    i18n_code = f.read()

if 'videoSavedSuccessTitle' not in i18n_code:
    new_keys = """      'videoSavedSuccessTitle': "Video Saved Successfully!",
      'videoSavedSuccessDesc': "Your memory video has been saved to Memory Lane. You can now tap to watch your video anytime.",\n"""
    idx = i18n_code.find("'en': {") + len("'en': {")
    i18n_code = i18n_code[:idx] + "\n" + new_keys + i18n_code[idx:]
    with open(i18n_path, 'w', encoding='utf-8') as f:
        f.write(i18n_code)
    print("Added videoSavedSuccessTitle and videoSavedSuccessDesc to i18n_service.dart.")

# 2. Update memory_lane_screen.dart
screen_path = '/home/dinakar3108/Downloads/PR1/lib/screens/memory_lane_screen.dart'
with open(screen_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Update _pickFromMobileGallery signature and fallback implementation
old_picker = """  Future<void> _pickFromMobileGallery(String mediaType, Function(String path) onSelected) async {
    final ImagePicker picker = ImagePicker();
    try {
      if (mediaType == 'photo') {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (image != null) {
          onSelected(image.path);
        }
      } else {
        final XFile? video = await picker.pickVideo(
          source: ImageSource.gallery,
        );
        if (video != null) {
          onSelected(video.path);
        }
      }
    } catch (e) {
      debugPrint('Mobile gallery picker error: $e');
    }
  }"""

new_picker = """  Future<void> _pickFromMobileGallery(BuildContext context, String mediaType, Function(String path) onSelected) async {
    final ImagePicker picker = ImagePicker();
    try {
      if (mediaType == 'photo') {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (image != null) {
          onSelected(image.path);
          return;
        }
      } else {
        final XFile? video = await picker.pickVideo(
          source: ImageSource.gallery,
        );
        if (video != null) {
          onSelected(video.path);
          return;
        }
      }
    } catch (e) {
      debugPrint('Mobile gallery picker error: $e');
    }

    // Fallback to preloaded gallery selector if device picker returns null or fails
    if (context.mounted) {
      _showGalleryPickerSheet(context, mediaType, onSelected);
    }
  }"""

code = code.replace(old_picker, new_picker)

# Replace all calls to _pickFromMobileGallery to pass context as first argument
code = code.replace("_pickFromMobileGallery('photo',", "_pickFromMobileGallery(context, 'photo',")
code = code.replace("_pickFromMobileGallery('video',", "_pickFromMobileGallery(context, 'video',")

with open(screen_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Updated _pickFromMobileGallery implementation and call sites.")
