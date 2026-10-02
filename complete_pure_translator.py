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

# Dictionary of phrase replacements
phrase_dict_ta = {
    'Medical': 'மருத்துவ',
    'Member': 'உறுப்பினர்',
    'of': 'உள்ள',
    'Medication': 'மருந்து',
    'This action cannot be undone': 'இந்த நடவடிக்கையை மாற்ற முடியாது',
    'It is {time}! Time for {title}.': 'நேரம் {time}! {title} க்கான நேரம் வந்துவிட்டது.',
    'Time for': 'க்கான நேரம்',
    'Time': 'நேரம்',
    'Action': 'நடவடிக்கை',
    'Undo': 'மீட்டமை',
    'Cannot': 'முடியாது',
    'Be': 'இருக்க',
    'Done': 'முடிந்தது',
    'Completed': 'முடிந்தது',
    'Scheduled': 'திட்டமிடப்பட்டது',
    'Routine': 'நடைமுறை',
    'Routines': 'நடைமுறைகள்',
    'Reminder': 'நினைவூட்டல்',
    'Reminders': 'நினைவூட்டல்கள்',
    'Overview': 'பார்வை',
    'Dashboard': 'டாஷ்போர்டு',
    'Profile': 'சுயவிவரம்',
    'Settings': 'அமைப்புகள்',
    'Password': 'கடவுச்சொல்',
    'Email': 'மின்னஞ்சல்',
    'Phone': 'தொலைபேசி',
    'Location': 'இருப்பிடம்',
    'Region': 'பகுதி',
    'Language': 'மொழி',
    'Code': 'குறியீடு',
    'Registration': 'பதிவு',
    'Verification': 'சரிபார்ப்பு',
    'Caregiver': 'பராமரிப்பாளர்',
    'Elder': 'முதியவர்',
    'Patient': 'நோயாளி',
    'Doctor': 'மருத்துவர்',
    'Hospital': 'மருத்துவமனை',
    'Medicine': 'மருந்து',
    'Pill': 'மாத்திரை',
    'Pills': 'மாத்திரைகள்',
    'Dose': 'அளவு',
    'Dosage': 'மருந்து அளவு',
    'Water': 'தண்ணீர்',
    'Goal': 'இலக்கு',
    'Target': 'இலக்கு',
    'Glasses': 'கிளாஸ்கள்',
    'Liters': 'லிட்டர்கள்',
    'Exercise': 'பயிற்சி',
    'Exercises': 'பயிற்சிகள்',
    'Game': 'விளையாட்டு',
    'Games': 'விளையாட்டுகள்',
    'Score': 'மதிப்பெண்',
    'Level': 'நிலை',
    'Accuracy': 'துல்லியம்',
    'Memory': 'நினைவகம்',
    'Memories': 'நினைவுகள்',
    'Recall': 'நினைவுகூர்தல்',
    'Reflection': 'பிரதிபலிப்பு',
    'Story': 'கதை',
    'Stories': 'கதைகள்',
    'Voice': 'குரல்',
    'Audio': 'ஒலிப்பதிவு',
    'Video': 'காணொளி',
    'Photo': 'புகைப்படம்',
    'Photos': 'புகைப்படங்கள்',
    'Add': 'சேர்',
    'Save': 'சேமி',
    'Delete': 'நீக்கு',
    'Cancel': 'ரத்து செய்',
    'Edit': 'திருத்து',
    'Update': 'புதுப்பி',
    'Clear': 'அழி',
    'Select': 'தேர்ந்தெடு',
    'Filter': 'வடிகட்டி',
    'Search': 'தேடுக',
    'Submit': 'சமர்ப்பி',
    'Confirm': 'உறுதிப்படுத்து',
    'Verify': 'சரிபார்க்கவும்',
    'Yes': 'ஆம்',
    'No': 'இல்லை',
    'All': 'அனைத்தும்',
    'None': 'எதுவுமில்லை',
    'Success': 'வெற்றி',
    'Error': 'பிழை',
    'Warning': 'எச்சரிக்கை',
    'Info': 'தகவல்',
    'Help': 'உதவி',
    'About': 'பற்றி',
}

phrase_dict_ne = {
    'Medical': 'चिकित्सा',
    'Member': 'सदस्य',
    'of': 'को',
    'Medication': 'औषधि',
    'This action cannot be undone': 'यो कार्य रद्द गर्न सकिँदैन',
    'It is {time}! Time for {title}.': 'समय {time} भयो! {title} को लागि समय भयो।',
    'Time for': 'को लागि समय',
    'Time': 'समय',
    'Action': 'कार्य',
    'Undo': 'पूर्ववत गर्नुहोस्',
    'Cannot': 'सकिँदैन',
    'Be': 'हुनु',
    'Done': 'सम्पन्न भयो',
    'Completed': 'सम्पन्न भयो',
    'Scheduled': 'तालिकबद्ध',
    'Routine': 'दिनचर्या',
    'Routines': 'दिनचर्याहरू',
    'Reminder': 'सम्झौटो',
    'Reminders': 'सम्झौटोहरू',
    'Overview': 'अवलोकन',
    'Dashboard': 'ड्यासबोर्ड',
    'Profile': 'प्रोफाइल',
    'Settings': 'सेटिङहरू',
    'Password': 'पासवर्ड',
    'Email': 'इमेल',
    'Phone': 'फोन',
    'Location': 'स्थान',
    'Region': 'क्षेत्र',
    'Language': 'भाषा',
    'Code': 'कोड',
    'Registration': 'दर्ता',
    'Verification': 'प्रमाणिकरण',
    'Caregiver': 'हेरचाहकर्ता',
    'Elder': 'ज्येष्ठ नागरिक',
    'Patient': 'बिरामी',
    'Doctor': 'डाक्टर',
    'Hospital': 'अस्पताल',
    'Medicine': 'औषधि',
    'Pill': 'ट्याब्लेट',
    'Pills': 'ट्याब्लेटहरू',
    'Dose': 'मात्रा',
    'Dosage': 'औषधि मात्रा',
    'Water': 'पानी',
    'Goal': 'लक्ष्य',
    'Target': 'लक्ष्य',
    'Glasses': 'ग्लासहरू',
    'Liters': 'लिटर',
    'Exercise': 'अभ्यास',
    'Exercises': 'अभ्यासहरू',
    'Game': 'खेल',
    'Games': 'खेलहरू',
    'Score': 'अङ्क',
    'Level': 'स्तर',
    'Accuracy': 'सटीकता',
    'Memory': 'स्मृति',
    'Memories': 'यादहरू',
    'Recall': 'याद गर्नुहोस्',
    'Reflection': 'प्रतिबिम्ब',
    'Story': 'कथा',
    'Stories': 'कथाहरू',
    'Voice': 'आवाज',
    'Audio': 'अडियो',
    'Video': 'भिडियो',
    'Photo': 'तस्बिर',
    'Photos': 'तस्बिरहरू',
    'Add': 'थप्नुहोस्',
    'Save': 'बचत गर्नुहोस्',
    'Delete': 'हटाउनुहोस्',
    'Cancel': 'रद्द गर्नुहोस्',
    'Edit': 'सम्पादन गर्नुहोस्',
    'Update': 'अद्यावधिक गर्नुहोस्',
    'Clear': 'सफा गर्नुहोस्',
    'Select': 'छान्नुहोस्',
    'Filter': 'फिल्टर',
    'Search': 'खोज्नुहोस्',
    'Submit': 'बुझाउनुहोस्',
    'Confirm': 'पुष्टि गर्नुहोस्',
    'Verify': 'प्रमाणित गर्नुहोस्',
    'Yes': 'हो',
    'No': 'होइन',
    'All': 'सबै',
    'None': 'कुनै पनि छैन',
    'Success': 'सफलता',
    'Error': 'त्रुटि',
    'Warning': 'चेतावनी',
    'Info': 'जानकारी',
    'Help': 'सहायता',
    'About': 'बारेमा',
}

from zero_english_words import vocab_ta, vocab_ne

vocab_ta.update(phrase_dict_ta)
vocab_ne.update(phrase_dict_ne)

def deep_clean_translate(en_text, vocab):
    res = en_text
    sorted_words = sorted(vocab.keys(), key=lambda x: len(x), reverse=True)
    for w in sorted_words:
        target = vocab[w]
        res = re.sub(r'\b' + re.escape(w) + r'\b', target, res, flags=re.IGNORECASE)
    return res

ta_pure = {}
ne_pure = {}

for k, en_val in en_kv.items():
    ta_pure[k] = deep_clean_translate(en_val, vocab_ta)
    ne_pure[k] = deep_clean_translate(en_val, vocab_ne)

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
for k, val in ta_pure.items():
    safe_val = val.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
    new_trans_block += f"      '{k}': '{safe_val}',\n"
new_trans_block += "    },\n"

# 3. 'ne'
new_trans_block += "    'ne': {\n"
for k, val in ne_pure.items():
    safe_val = val.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
    new_trans_block += f"      '{k}': '{safe_val}',\n"
new_trans_block += "    },"

content = content[:start_trans] + new_trans_block + content[end_trans:]

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Deep cleaned Tamil and Nepali dictionaries successfully.")
