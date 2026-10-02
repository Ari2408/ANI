import re

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

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

# Collect every unique English word across all values
all_words = set()
for v in en_kv.values():
    clean_v = re.sub(r'\{[a-zA-Z0-9_]+\}', '', v)
    words = re.findall(r'\b[a-zA-Z]+\b', clean_v)
    for w in words:
        if w.upper() not in ['CHI', 'SOS', 'PIN', 'OTP', 'AI', 'ID', 'TTS', 'QR', 'P2P', 'NER', 'SMS']:
            all_words.add(w)

print(f"Total unique English words to map: {len(all_words)}")

