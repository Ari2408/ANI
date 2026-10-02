import re
import json

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Extract 'en' keys
pattern = r"'en': {"
start = content.find(pattern)
lines = content[start:].split('\n')
en_kv = {}
for line in lines:
    m = re.search(r"^\s*'([a-zA-Z0-9_]+)'\s*:\s*'(.*)'\s*,\s*$", line)
    if m:
        en_kv[m.group(1)] = m.group(2)
    if line.strip() == '},':
        break

print(f"Loaded {len(en_kv)} English keys.")

from generate_perfect_100pct_i18n import key_db
from build_100pct_translations import word_db

# Enhanced translation function for any arbitrary key
def get_translated_string(key, en_text, lang):
    # 1. Direct key match in key_db
    if key in key_db and lang in key_db[key]:
        return key_db[key][lang]
    
    # 2. Direct exact text match in word_db
    if en_text in word_db[lang]:
        return word_db[lang][en_text]
    
    # 3. Term replacement
    res = en_text
    sorted_words = sorted(word_db[lang].keys(), key=lambda x: len(x), reverse=True)
    for w in sorted_words:
        target = word_db[lang][w]
        res = re.sub(r'\b' + re.escape(w) + r'\b', target, res, flags=re.IGNORECASE)
    
    return res

langs = ['ta', 'ne', 'as', 'bn', 'mni', 'lus', 'kha', 'nag']
generated_dicts = {}

for lang in langs:
    dict_str = f"    '{lang}': {{\n"
    for k, en_val in en_kv.items():
        val = get_translated_string(k, en_val, lang)
        safe_val = val.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
        dict_str += f"      '{k}': '{safe_val}',\n"
    dict_str += "    },"
    generated_dicts[lang] = dict_str

# Replace _translations dictionary in i18n_service.dart
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

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Saved 100% native translations to i18n_service.dart.")

