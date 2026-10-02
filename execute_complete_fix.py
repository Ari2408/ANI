import os
import re

# 1. Update I1nService -> I18nService in all dart files in lib/
lib_dir = '/home/dinakar3108/Downloads/PR1/lib'
updated_files = []

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace I1nService with I18nService (except in typedef I1nService = I18nService)
            # Use regex to match I1nService
            if 'I1nService' in content and not file == 'i18n_service.dart':
                new_content = re.sub(r'\bI1nService\b', 'I18nService', content)
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                updated_files.append(file)

print(f"Updated I1nService -> I18nService in {len(updated_files)} files.")

# 2. Update i18n_service.dart class name and translations
from build_100pct_translations import en_kv, full_translate

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace class name
content = re.sub(r'class\s+I1nService\s+extends\s+ChangeNotifier', 'class I18nService extends ChangeNotifier', content)

# Generate updated translation dictionaries for all 8 languages
langs = ['ta', 'ne', 'as', 'bn', 'mni', 'lus', 'kha', 'nag']
generated_dicts = {}

for lang in langs:
    dict_str = f"    '{lang}': {{\n"
    for k, en_val in en_kv.items():
        translated_val = full_translate(en_val, lang)
        safe_val = translated_val.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
        dict_str += f"      '{k}': '{safe_val}',\n"
    dict_str += "    },"
    generated_dicts[lang] = dict_str

start_trans = content.find("static final Map<String, Map<String, String>> _translations = {")
end_trans = content.find("  };\n\n  void setLanguage", start_trans)

new_trans_block = "static final Map<String, Map<String, String>> _translations = {\n"
new_trans_block += "    'en': {\n"
for k, en_val in en_kv.items():
    safe_val = en_val.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
    new_trans_block += f"      '{k}': '{safe_val}',\n"
new_trans_block += "    },\n"

for lang in langs:
    new_trans_block += generated_dicts[lang] + "\n"

content = content[:start_trans] + new_trans_block + content[end_trans:]

# Ensure typedef is present at bottom for backward compatibility
if 'typedef I1nService = I18nService;' not in content:
    content += "\ntypedef I1nService = I18nService;\n"

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Saved updated i18n_service.dart with 100% native translations for all 8 languages.")
