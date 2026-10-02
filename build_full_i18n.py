import re
import sys

def escape_dart_string(val):
    val = val.replace("\\", "\\\\")
    val = val.replace("'", "\\'")
    val = val.replace("\n", "\\n")
    return val

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Extract 'en', 'ta', 'ne' dictionaries
def extract_dict(lang_code, src):
    pattern = f"'{lang_code}': {{"
    start = src.find(pattern)
    if start == -1:
        return {}
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
    
    kv = {}
    for line in lines:
        m = re.search(r"^\s*'([a-zA-Z0-9_]+)'\s*:\s*'(.*)'\s*,\s*$", line)
        if m:
            kv[m.group(1)] = m.group(2)
    return kv

en_kv = extract_dict('en', content)
ta_kv = extract_dict('ta', content)
ne_kv = extract_dict('ne', content)

print(f"Extracted en: {len(en_kv)}, ta: {len(ta_kv)}, ne: {len(ne_kv)}")

