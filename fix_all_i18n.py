import re
import json

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Extract English dictionary
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

