import re

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace languageNames
old_lang_names = """  final Map<String, String> languageNames = {
      'en': 'English',
      'ne': 'নেपाली (Nepali)',
      'ta': 'தமிழ் (Tamil)',
  };"""

new_lang_names = """  final Map<String, String> languageNames = {
      'en': 'English',
      'ne': 'নেपाली (Nepali)',
      'ta': 'தமிழ் (Tamil)',
      'as': 'অসমীয়া (Assamese)',
      'bn': 'বাংলা (Bengali)',
      'mni': 'মৈতৈলোন্ (Manipuri)',
      'lus': 'Mizo ţawng (Mizo)',
      'kha': 'Ka Ktien Khasi (Khasi)',
      'nag': 'Nagamese',
  };"""

if old_lang_names in content:
    content = content.replace(old_lang_names, new_lang_names)
    print("Updated languageNames map.")
else:
    print("WARNING: Could not find exact old_lang_names string!")

# Now get generated language maps
import create_full_i18n

new_dicts = "\n".join(create_full_i18n.generated_maps.values())

# Insert new dicts before the end of _translations
# _translations ends with '  };\n' right before void setLanguage
target_marker = "  };\n\n  void setLanguage(String langCode) {"
if target_marker in content:
    content = content.replace(target_marker, new_dicts + "\n  };\n\n  void setLanguage(String langCode) {")
    print("Inserted 6 new language dictionaries into _translations.")
else:
    print("WARNING: Could not find target_marker string!")

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Saved updated i18n_service.dart successfully.")
