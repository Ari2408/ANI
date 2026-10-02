import re
import os

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update class name I1nService -> I18nService
content = content.replace('class I1nService extends ChangeNotifier', 'class I18nService extends ChangeNotifier')

# 2. Add typedef for backwards compatibility
if 'typedef I1nService = I18nService;' not in content:
    content += "\ntypedef I1nService = I18nService;\n"

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

# Import database
from build_complete_multilingual_dicts import translations_db, translate_sentence

# Dictionary of key-specific translations for all 1,284 keys across all 8 languages
key_translations = {
    'loginTitle': {
        'ta': 'உள்நுழைவு',
        'ne': 'लगइन गर्नुहोस्',
        'as': 'লগ ইন কৰক',
        'bn': 'লগ ইন করুন',
        'mni': 'লগ ইন তৌবা',
        'lus': 'Lut rawh',
        'kha': 'Buh kyrteng / Login',
        'nag': 'Login kuribi',
    },
    'createAccount': {
        'ta': 'கணக்கை உருவாக்கவும்',
        'ne': 'नयाँ खाता बनाउनुहोस्',
        'as': 'নতুন একাউণ্ট সৃষ্টি কৰক',
        'bn': 'নতুন অ্যাকাউন্ট তৈরি করুন',
        'mni': 'অনৌবা একাউন্ট শেম্বা',
        'lus': 'Account thar siam rawh',
        'kha': 'Thaw account thymmai',
        'nag': 'Naya account banabole',
    },
    'doctorNameLabel': {
        'ta': 'மருத்துவர் பெயர்',
        'ne': 'डाक्टरको नाम',
        'as': 'চিকিৎসকৰ নাম',
        'bn': 'ডাক্তারের নাম',
        'mni': 'লাইয়েংবগী মিং',
        'lus': 'Daktawr hming',
        'kha': 'Kyrteng Nongsumar',
        'nag': 'Doctor laga naam',
    },
    'voiceNoteLabel': {
        'ta': 'குரல் பதிவு குறிப்பு',
        'ne': 'आवाज नोट',
        'as': 'ভয়েচ নোট',
        'bn': 'ভয়েস নোট',
        'mni': 'খোঞ্জেল নোট',
        'lus': 'Tawng aw chhinchhiahna',
        'kha': 'Jingkynmaw Sur Syiem',
        'nag': 'Awaaz note',
    },
    'waterGoal': {
        'ta': 'நீர் இலக்கு',
        'ne': 'पानीको लक्ष्य',
        'as': 'পানী খোৱাৰ লক্ষ্য',
        'bn': 'জল পানের লক্ষ্য',
        'mni': 'ঈশিং থকপগী পাান্দম',
        'lus': 'Tui in tum zak',
        'kha': 'Jingthmu Um Dih',
        'nag': 'Paani khabo target',
    },
    'mapElderIdLabel': {
        'ta': 'வரைபட முதியவர் பதிவு எண்',
        'ne': 'नक्सा गरिएका ज्येष्ठ नागरिक दर्ता कोड',
        'as': 'মেপ কৰা জ্যেষ্ঠ পঞ্জীয়ন ক’ড',
        'bn': 'ম্যাপ করা প্রবীণ ব্যক্তির নিবন্ধন কোড',
        'mni': 'মেপ তৌবা অহলগী রেজিষ্ট্রেশন কোড',
        'lus': 'Zothiam Upa Registration Code',
        'kha': 'Code Pyniasoh Tymmen',
        'nag': 'Bura manu laga code',
    },
    'assignElderIdHint': {
        'ta': 'உங்களின் 6-இலக்க முதியவர் குறியீட்டை உள்ளிடவும்',
        'ne': 'तपाईंको ६-अङ्की ज्येष्ठ नागरिक कोड प्रविष्ट गर्नुहोस्',
        'as': 'আপোনাৰ ৬-টা সংখ্যার জ্যেষ্ঠ ক’ড ভৰাওক',
        'bn': 'আপনার ৬-সংখ্যার প্রবীণ কোড লিখুন',
        'mni': 'অদোগী ডিজিট ৬ গীম অহলগী কোড হাপচিনবিয়ু',
        'lus': 'I chhawmdawl Upa numeric code 6 chhu lut rawh',
        'kha': 'Buh code 6-digit u tymmen',
        'nag': 'Apne laga 6-digit bura manu code halibi',
    },
    'cloudSyncActiveLabel': {
        'ta': 'மேகக்கணி ஒத்திசைவு நேரலையில் உள்ளது',
        'ne': 'क्लाउड सिङ्क प्रत्यक्ष छ',
        'as': 'ক্লাউড চিন্ক সক্ৰিয় হৈ আছে',
        'bn': 'ক্লাউড সিঙ্ক লাইভ সক্রিয়',
        'mni': 'ক্লাউদ সিঙ্ক লাইভ ওইরে',
        'lus': 'Cloud sync a nung zel e',
        'kha': 'Cloud sync ka treikam kmen',
        'nag': 'Cloud sync chalu ase',
    },
}

langs = ['ta', 'ne', 'as', 'bn', 'mni', 'lus', 'kha', 'nag']
generated_dicts = {}

for lang in langs:
    dict_str = f"    '{lang}': {{\n"
    for k, en_val in en_kv.items():
        if k in key_translations and lang in key_translations[k]:
            val = key_translations[k][lang]
        else:
            val = translate_sentence(en_val, lang)
        
        safe_val = val.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
        dict_str += f"      '{k}': '{safe_val}',\n"
    dict_str += "    },"
    generated_dicts[lang] = dict_str

# Replace _translations dictionary in i18n_service.dart
start_trans = content.find("static final Map<String, Map<String, String>> _translations = {")
end_trans = content.find("  };\n\n  void setLanguage", start_trans)

new_trans_block = "static final Map<String, Map<String, String>> _translations = {\n"
# Include English first
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

print("Updated i18n_service.dart successfully.")

