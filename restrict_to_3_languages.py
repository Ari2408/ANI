import re

# 1. Update i18n_service.dart
with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Update languageNames
old_names_start = content.find("final Map<String, String> languageNames = {")
old_names_end = content.find("};", old_names_start) + 2

new_names = """final Map<String, String> languageNames = {
      'en': 'English',
      'ta': 'தமிழ் (Tamil)',
      'ne': 'नेपाली (Nepali)',
  };"""

content = content[:old_names_start] + new_names + content[old_names_end:]

# Filter _translations map to keep only 'en', 'ta', 'ne'
def extract_dict(lang_code, src):
    pattern = f"'{lang_code}': {{"
    start = src.find(pattern)
    if start == -1: return ""
    lines = []
    depth = 0
    in_dict = False
    for line in src[start:].split('\n'):
        if '{' in line:
            depth += line.count('{')
            in_dict = True
        if '}' in line:
            depth -= line.count('}')
        if in_dict:
            lines.append(line)
        if in_dict and depth == 0:
            break
    return "\n".join(lines)

en_str = extract_dict('en', content)
ta_str = extract_dict('ta', content)
ne_str = extract_dict('ne', content)

start_trans = content.find("static final Map<String, Map<String, String>> _translations = {")
end_trans = content.find("  };\n\n  void setLanguage", start_trans)

new_trans_block = "static final Map<String, Map<String, String>> _translations = {\n"
new_trans_block += en_str + ",\n"
new_trans_block += ta_str + ",\n"
new_trans_block += ne_str + ",\n"

content = content[:start_trans] + new_trans_block + content[end_trans:]

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated i18n_service.dart to contain only en, ta, ne.")

# 2. Update auth_onboarding_screen.dart
auth_path = '/home/dinakar3108/Downloads/PR1/lib/screens/auth_onboarding_screen.dart'
with open(auth_path, 'r', encoding='utf-8') as f:
    auth_code = f.read()

start_langs = auth_code.find("final List<Map<String, String>> _languages = [")
end_langs = auth_code.find("];", start_langs) + 2

new_langs = """final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇬🇧'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்', 'flag': '🛕'},
    {'code': 'ne', 'name': 'Nepali', 'native': 'नेपाली', 'flag': '🇳🇵'},
  ];"""

auth_code = auth_code[:start_langs] + new_langs + auth_code[end_langs:]

with open(auth_path, 'w', encoding='utf-8') as f:
    f.write(auth_code)

print("Updated auth_onboarding_screen.dart _languages list.")

# 3. Update main.dart
main_path = '/home/dinakar3108/Downloads/PR1/lib/main.dart'
with open(main_path, 'r', encoding='utf-8') as f:
    main_code = f.read()

main_code = main_code.replace(
    "fontFamily: i18n.currentLang == 'ta' ? 'Noto Serif Tamil' : (['as', 'bn', 'mni', 'ne'].contains(i18n.currentLang) ? null : 'Comic Relief'),",
    "fontFamily: i18n.currentLang == 'ta' ? 'Noto Serif Tamil' : (i18n.currentLang == 'ne' ? null : 'Comic Relief'),"
)

with open(main_path, 'w', encoding='utf-8') as f:
    f.write(main_code)

print("Updated main.dart font configuration.")

