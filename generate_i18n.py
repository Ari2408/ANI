import re
import json

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Extract English dictionary
start_en = content.find("'en': {")
end_en = content.find("},\n  };", start_en)
if end_en == -1: end_en = content.find("};", start_en)

en_lines = content[start_en:end_en].split('\n')
en_kv = {}
for line in en_lines:
    m = re.search(r"^\s*'([a-zA-Z0-9_]+)'\s*:\s*'(.*)'\s*,\s*$", line)
    if m:
        en_kv[m.group(1)] = m.group(2)

print(f"Loaded {len(en_kv)} English keys.")

