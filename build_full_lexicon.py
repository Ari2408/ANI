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

from complete_pure_translator import vocab_ta, vocab_ne

# Comprehensive dictionary covering all UI domains
lexicon_ta = {
    'Schedule': 'அட்டவணை',
    'Schedules': 'அட்டவணைகள்',
    'and': 'மற்றும்',
    'Videos': 'காணொளிகள்',
    'Video': 'காணொளி',
    'Prescription': 'மருந்துச் சீட்டு',
    'Visit': 'வருகை',
    'Advice': 'ஆலோசனை',
    'Not': 'இல்லை',
    'Yet': 'இன்னும்',
    'Take': 'எடுக்கவும்',
    'Meal': 'உணவு',
    'Meals': 'உணவுகள்',
    'Terms': 'விதிமுறைகள்',
    'Agreed': 'ஒப்புக் கொள்ளப்பட்டது',
    'Care': 'பராமரிப்பு',
    'Assistant': 'உதவியாளர்',
    'Assist': 'உதவவும்',
    'Assistance': 'உதவி',
    'Patient': 'நோயாளி',
    'Patients': 'நோயாளிகள்',
    'Doctor': 'மருத்துவர்',
    'Doctors': 'மருத்துவர்கள்',
    'Hospital': 'மருத்துவமனை',
    'Hospitals': 'மருத்துவமனைகள்',
    'Medicine': 'மருந்து',
    'Medicines': 'மருந்துகள்',
    'Medication': 'மருந்து',
    'Medications': 'மருந்துகள்',
    'Routine': 'நடைமுறை',
    'Routines': 'நடைமுறைகள்',
    'Activity': 'நடவடிக்கை',
    'Activities': 'நடவடிக்கைகள்',
    'Reminder': 'நினைவூட்டல்',
    'Reminders': 'நினைவூட்டல்கள்',
    'Alarm': 'அலாரம்',
    'Alarms': 'அலாரங்கள்',
    'Notification': 'அறிவிப்பு',
    'Notifications': 'அறிவிப்புகள்',
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
    'Photo': 'புகைப்படம்',
    'Photos': 'புகைப்படங்கள்',
    'Landmark': 'அடையாளச் சின்னம்',
    'Landmarks': 'அடையாளச் சின்னங்கள்',
    'Heritage': 'பாரம்பரியம்',
    'Cultural': 'கலாச்சார',
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
    'Today': 'இன்று',
    'Yesterday': 'நேற்று',
    'Tomorrow': 'நாளை',
    'Morning': 'காலை',
    'Afternoon': 'மதியம்',
    'Evening': 'மாலை',
    'Night': 'இரவு',
    'Food': 'உணவு',
    'Water': 'தண்ணீர்',
    'Glass': 'கிளாஸ்',
    'Glasses': 'கிளாஸ்கள்',
    'Liter': 'லிட்டர்',
    'Liters': 'லிட்டர்கள்',
    'Goal': 'இலக்கு',
    'Target': 'இலக்கு',
    'Pill': 'மாத்திரை',
    'Pills': 'மாத்திரைகள்',
    'Dose': 'அளவு',
    'Dosage': 'மருந்து அளவு',
    'Before': 'முன்',
    'After': 'பின்',
    'It': 'இது',
    'is': 'ஆகும்',
    'for': 'க்கான',
    'This': 'இந்த',
    'action': 'நடவடிக்கை',
    'cannot': 'முடியாது',
    'be': 'இருக்க',
    'undone': 'மாற்றப்பட்டது',
    'Enter': 'உள்ளிடவும்',
    'Please': 'தயவுசெய்து',
    'Member': 'உறுப்பினர்',
    'Members': 'உறுப்பினர்கள்',
    'Family': 'குடும்பம்',
    'Personal': 'தனிப்பட்ட',
    'Custom': 'தனிப்பயன்',
    'Default': 'இயல்புநிலை',
    'Baseline': 'அடிப்படை நிலை',
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
    'Elders': 'முதியவர்கள்',
    'Grandson': 'பேரன்',
    'Granddaughter': 'பேத்தி',
    'Daughter': 'மகள்',
    'Son': 'மகன்',
    'Father': 'தந்தை',
    'Mother': 'தாய்',
    'Sister': 'சகோதரி',
    'Brother': 'சகோதரன்',
    'Friend': 'நண்பர்',
    'Relative': 'உறவினர்',
}

lexicon_ne = {
    'Schedule': 'समयसूची',
    'Schedules': 'समयसूचीहरू',
    'and': 'र',
    'Videos': 'भिडियोहरू',
    'Video': 'भिडियो',
    'Prescription': 'औषधि पर्ची',
    'Visit': 'भ्रमण',
    'Advice': 'सल्लाह',
    'Not': 'होइन',
    'Yet': 'अझै',
    'Take': 'लिनुहोस्',
    'Meal': 'खाना',
    'Meals': 'खानाहरू',
    'Terms': 'शर्तहरू',
    'Agreed': 'सहमत भयो',
    'Care': 'हेरचाह',
    'Assistant': 'सहायक',
    'Assist': 'सहयोग गर्नुहोस्',
    'Assistance': 'सहायता',
    'Patient': 'बिरामी',
    'Patients': 'बिरामीहरू',
    'Doctor': 'डाक्टर',
    'Doctors': 'डाक्टरहरू',
    'Hospital': 'अस्पताल',
    'Hospitals': 'अस्पतालहरू',
    'Medicine': 'औषधि',
    'Medicines': 'औषधिहरू',
    'Medication': 'औषधि',
    'Medications': 'औषधिहरू',
    'Routine': 'दिनचर्या',
    'Routines': 'दिनचर्याहरू',
    'Activity': 'गतिविधि',
    'Activities': 'गतिविधिहरू',
    'Reminder': 'सम्झौटो',
    'Reminders': 'सम्झौटोहरू',
    'Alarm': 'अलार्म',
    'Alarms': 'अलार्महरू',
    'Notification': 'सूचना',
    'Notifications': 'सूचनाहरू',
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
    'Photo': 'तस्बिर',
    'Photos': 'तस्बिरहरू',
    'Landmark': 'स्थल',
    'Landmarks': 'स्थलहरू',
    'Heritage': 'सम्पदा',
    'Cultural': 'सांस्कृतिक',
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
    'Today': 'आज',
    'Yesterday': 'हिजो',
    'Tomorrow': 'भोलि',
    'Morning': 'बिहान',
    'Afternoon': 'दिउँसो',
    'Evening': 'साँझ',
    'Night': 'राति',
    'Food': 'खाना',
    'Water': 'पानी',
    'Glass': 'ग्लास',
    'Glasses': 'ग्लासहरू',
    'Liter': 'लिटर',
    'Liters': 'लिटर',
    'Goal': 'लक्ष्य',
    'Target': 'लक्ष्य',
    'Pill': 'ट्याब्लेट',
    'Pills': 'ट्याब्लेटहरू',
    'Dose': 'मात्रा',
    'Dosage': 'औषधि मात्रा',
    'Before': 'अघि',
    'After': 'पछि',
    'It': 'यो',
    'is': 'हो',
    'for': 'को लागि',
    'This': 'यो',
    'action': 'कार्य',
    'cannot': 'सकिँदैन',
    'be': 'हुनु',
    'undone': 'पूर्ववत',
    'Enter': 'लेख्नुहोस्',
    'Please': 'कृपया',
    'Member': 'सदस्य',
    'Members': 'सदस्यहरू',
    'Family': 'परिवार',
    'Personal': 'व्यक्तिगत',
    'Custom': 'कस्टम',
    'Default': 'डिफल्ट',
    'Baseline': 'आधार रेखा',
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
    'Elders': 'ज्येष्ठ नागरिकहरू',
    'Grandson': 'नाति',
    'Granddaughter': 'नातिनी',
    'Daughter': 'छोरी',
    'Son': 'छोरा',
    'Father': 'बुबा',
    'Mother': 'आमा',
    'Sister': 'दिदी/बहिनी',
    'Brother': 'दाजु/भाइ',
    'Friend': 'साथी',
    'Relative': 'नातेदार',
}

vocab_ta.update(lexicon_ta)
vocab_ne.update(lexicon_ne)

def translate_word_level(en_text, vocab):
    res = en_text
    sorted_words = sorted(vocab.keys(), key=lambda x: len(x), reverse=True)
    for w in sorted_words:
        target = vocab[w]
        res = re.sub(r'\b' + re.escape(w) + r'\b', target, res, flags=re.IGNORECASE)
    return res

ta_full = {}
ne_full = {}

for k, en_val in en_kv.items():
    ta_full[k] = translate_word_level(en_val, vocab_ta)
    ne_full[k] = translate_word_level(en_val, vocab_ne)

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
for k, val in ta_full.items():
    safe_val = val.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
    new_trans_block += f"      '{k}': '{safe_val}',\n"
new_trans_block += "    },\n"

# 3. 'ne'
new_trans_block += "    'ne': {\n"
for k, val in ne_full.items():
    safe_val = val.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
    new_trans_block += f"      '{k}': '{safe_val}',\n"
new_trans_block += "    },"

content = content[:start_trans] + new_trans_block + content[end_trans:]

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Applied full lexicon translation for Tamil and Nepali.")
