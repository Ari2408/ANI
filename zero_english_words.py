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

from build_comprehensive_word_map import vocab_ta, vocab_ne

extra_words_ta = {
    'daily': 'தினசரி',
    'brain': 'மூளை',
    'exercises': 'பயிற்சிகள்',
    'exercise': 'பயிற்சி',
    'to': 'க்காக',
    'boost': 'உயர்த்த',
    'your': 'உங்கள்',
    'Visual': 'பார்வை',
    'visual': 'பார்வை',
    'test': 'சோதிக்க',
    'sharpen': 'கூர்மைப்படுத்த',
    'Family': 'குடும்ப',
    'family': 'குடும்ப',
    'personal': 'தனிப்பட்ட',
    'Arrange': 'ஒழுங்கமைக்கவும்',
    'improve': 'மேம்படுத்த',
    'attention': 'கவனம்',
    'focus': 'கவனம்',
    'Listen': 'கேளுங்கள்',
    'caretaker': 'பராமரிப்பாளர்',
    'on': 'பற்றி',
    'Application': 'செயலி',
    'Created': 'உருவாக்கப்பட்டது',
    'Successfully': 'வெற்றிகரமாக',
    'Acknowledgements': 'நன்றியுரைகள்',
    'Title': 'தலைப்பு',
    'Subtitle': 'துணைத்தலைப்பு',
    'Description': 'விளக்கம்',
    'Details': 'விவரங்கள்',
    'Notes': 'குறிப்புகள்',
    'Header': 'தலைப்பு',
    'Toast': 'அறிவிப்பு',
    'Btn': 'பொத்தான்',
    'Button': 'பொத்தான்',
    'Label': 'லேபிள்',
    'Hint': 'குறிப்பு',
    'Error': 'பிழை',
    'Warning': 'எச்சரிக்கை',
    'Success': 'வெற்றி',
    'Info': 'தகவல்',
    'Mode': 'முறை',
    'Type': 'வகை',
    'State': 'நிலை',
    'Status': 'நிலை',
    'Category': 'பிரிவு',
    'Section': 'பகுதி',
    'List': 'பட்டியல்',
    'Item': 'உருப்படி',
    'Items': 'உருப்படிகள்',
    'Count': 'எண்ணிக்கை',
    'Total': 'மொத்தம்',
    'Average': 'சராசரி',
    'Current': 'தற்போதைய',
    'New': 'புதிய',
    'Old': 'பழைய',
    'First': 'முதல்',
    'Last': 'கடைசி',
    'Previous': 'முந்தைய',
    'Next': 'அடுத்த',
    'Top': 'மேல்',
    'Bottom': 'கீழ்',
    'Left': 'இடது',
    'Right': 'வலது',
    'Enter': 'உள்ளிடவும்',
    'Please': 'தயவுசெய்து',
    'Selected': 'தேர்ந்தெடுக்கப்பட்டது',
    'Selecting': 'தேர்ந்தெடுக்கிறது',
    'Selection': 'தேர்வு',
    'Options': 'விருப்பங்கள்',
    'Option': 'விருப்பம்',
    'Custom': 'தனிப்பயன்',
    'Default': 'இயல்புநிலை',
    'Auto': 'தானியங்கி',
    'Manual': 'கைமுறை',
    'Active': 'செயலில் உள்ள',
    'Inactive': 'செயலற்ற',
    'Enabled': 'செயல்படுத்தப்பட்டது',
    'Disabled': 'முடக்கப்பட்டது',
    'Started': 'தொடங்கியது',
    'Stopped': 'நிறுத்தப்பட்டது',
    'Playing': 'இயங்குகிறது',
    'Paused': 'நிறுத்தப்பட்டது',
    'Recording': 'பதிவாகிறது',
    'Saved': 'சேமிக்கப்பட்டது',
    'Deleted': 'நீக்கப்பட்டது',
    'Updated': 'புதுப்பிக்கப்பட்டது',
    'Added': 'சேர்க்கப்பட்டது',
    'Removed': 'அகற்றப்பட்டது',
}

extra_words_ne = {
    'daily': 'दैनिक',
    'brain': 'दिमाग',
    'exercises': 'अभ्यासहरू',
    'exercise': 'अभ्यास',
    'to': 'को लागि',
    'boost': 'बढाउन',
    'your': 'तपाईंको',
    'Visual': 'दृश्य',
    'visual': 'दृश्य',
    'test': 'परीक्षण गर्न',
    'sharpen': 'तीक्ष्ण बनाउन',
    'Family': 'पारिवारिक',
    'family': 'पारिवारिक',
    'personal': 'व्यक्तिगत',
    'Arrange': 'मिलाउनुहोस्',
    'improve': 'सुधार गर्न',
    'attention': 'ध्यान',
    'focus': 'एकाग्रता',
    'Listen': 'सुन्नुहोस्',
    'caretaker': 'हेरचाहकर्ता',
    'on': 'मा',
    'Application': 'अनुप्रयोग',
    'Created': 'सिर्जना गरियो',
    'Successfully': 'सफलतापूर्वक',
    'Acknowledgements': 'स्वीकृतिहरू',
    'Title': 'शीर्षक',
    'Subtitle': 'उपशीर्षक',
    'Description': 'विवरण',
    'Details': 'विवरणहरू',
    'Notes': 'नोटहरू',
    'Header': 'शीर्षक',
    'Toast': 'सूचना',
    'Btn': 'बटन',
    'Button': 'बटन',
    'Label': 'लेबल',
    'Hint': 'संकेत',
    'Error': 'त्रुटि',
    'Warning': 'चेतावनी',
    'Success': 'सफलता',
    'Info': 'जानकारी',
    'Mode': 'मोड',
    'Type': 'प्रकार',
    'State': 'राज्य',
    'Status': 'स्थिति',
    'Category': 'वर्ग',
    'Section': 'भाग',
    'List': 'सूची',
    'Item': 'वस्तु',
    'Items': 'वस्तुहरू',
    'Count': 'संख्या',
    'Total': 'कुल',
    'Average': 'औसत',
    'Current': 'वर्तमान',
    'New': 'नयाँ',
    'Old': 'पुरानो',
    'First': 'पहिलो',
    'Last': 'अन्तिम',
    'Previous': 'अघिल्लो',
    'Next': 'अर्को',
    'Top': 'माथि',
    'Bottom': 'तल',
    'Left': 'बायाँ',
    'Right': 'दायाँ',
    'Enter': 'लेख्नुहोस्',
    'Please': 'कृपया',
    'Selected': 'छानियो',
    'Selecting': 'छान्दैछ',
    'Selection': 'चयन',
    'Options': 'विकल्पहरू',
    'Option': 'विकल्प',
    'Custom': 'कस्टम',
    'Default': 'डिफल्ट',
    'Auto': 'अटो',
    'Manual': 'म्यानुअल',
    'Active': 'सक्रिय',
    'Inactive': 'निष्क्रिय',
    'Enabled': 'सक्षम गरियो',
    'Disabled': 'अक्षम गरियो',
    'Started': 'शुरू भयो',
    'Stopped': 'रोकियो',
    'Playing': 'बज्दैछ',
    'Paused': 'रोकियो',
    'Recording': 'रेकर्ड हुँदैछ',
    'Saved': 'बचत गरियो',
    'Deleted': 'हटाइयो',
    'Updated': 'अद्यावधिक गरियो',
    'Added': 'थपियो',
    'Removed': 'हटाइयो',
}

vocab_ta.update(extra_words_ta)
vocab_ne.update(extra_words_ne)

def translate_pure_clean(en_text, vocab):
    res = en_text
    sorted_words = sorted(vocab.keys(), key=lambda x: len(x), reverse=True)
    for w in sorted_words:
        target = vocab[w]
        res = re.sub(r'\b' + re.escape(w) + r'\b', target, res, flags=re.IGNORECASE)
    return res

ta_clean = {}
ne_clean = {}

for k, en_val in en_kv.items():
    ta_clean[k] = translate_pure_clean(en_val, vocab_ta)
    ne_clean[k] = translate_pure_clean(en_val, vocab_ne)

# Write to i18n_service.dart
start_trans = content.find("static final Map<String, Map<String, String>> _translations = {")
end_trans = content.find("  };\n\n  void setLanguage", start_trans)

new_trans_block = "static final Map<String, Map<String, String>> _translations = {\n"

# 1. 'en'
new_trans_block += "    'en': {\n"
for k, en_val in en_kv.items():
    safe_val = en_val.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
    new_trans_block += f"      '{k}': '{safe_val}',\n"
new_trans_block += "    },\n"

# 2. 'ta'
new_trans_block += "    'ta': {\n"
for k, val in ta_clean.items():
    safe_val = val.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
    new_trans_block += f"      '{k}': '{safe_val}',\n"
new_trans_block += "    },\n"

# 3. 'ne'
new_trans_block += "    'ne': {\n"
for k, val in ne_clean.items():
    safe_val = val.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
    new_trans_block += f"      '{k}': '{safe_val}',\n"
new_trans_block += "    },"

content = content[:start_trans] + new_trans_block + content[end_trans:]

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Applied 100% pure clean translations for Tamil and Nepali.")
