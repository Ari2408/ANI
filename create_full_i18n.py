import re
import sys

# Load i18n_service.dart
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

print(f"Extracted {len(en_kv)} English keys.")

# Rule-based translator for the 6 languages
def translate_key(key, en_text, lang):
    # Preserve formatting tags like {time}, {title}, {count}, {name}, {date}, {score}
    placeholders = re.findall(r"\{[a-zA-Z0-9_]+\}", en_text)
    
    # Custom translations for key UI phrases per language
    # Assamese (as)
    if lang == 'as':
        if key == 'appName': return 'পূৰ্ব চেতনা'
        if key == 'tagline': return 'উত্তৰ-পূব আৰু তামিলনাডুৰ বাবে এআই জ্যে প্ৰজ্ঞামূলক সহকারী'
        if key == 'elderDashboard': return 'জ্যেষ্ঠ ডেশ্ববৰ্ড'
        if key == 'caretakerDashboard': return 'পৰিচৰ্যাকাৰী ডেশ্ববৰ্ড'
        if key == 'todayScheduleOverview': return 'আজিসমূহৰ কাৰ্যসূচীৰ পৰ্যালোচনা'
        if key == 'cognitiveExercisesTitle': return 'দৈনিক জ্ঞানীয় ব্যায়ামসমূহ'
        if key == 'memoryLane': return 'স্মৃতি পথ (Memory Lane)'
        if key == 'save': return 'সংৰক্ষণ কৰক'
        if key == 'saveBtn': return 'সংৰক্ষণ কৰক'
        if key == 'delete': return 'মচি পেলাওক'
        if key == 'deleteBtn': return 'মচি পেলাওক'
        if key == 'cancel': return 'বাতিল কৰক'
        if key == 'cancelBtn': return 'বাতিল কৰক'
        if key == 'add': return 'যোগ কৰক'
        if key == 'addBtn': return 'যোগ কৰক'
        if key == 'audio': return 'অডিঅ\''
        if key == 'video': return 'ভিডিঅ\''
        if key == 'photo': return 'ফটো'
        if key == 'mediaTypeAudio': return 'অডিঅ\''
        if key == 'mediaTypeVideo': return 'ভিডিঅ\''
        if key == 'mediaTypePhoto': return 'ফটো'
        if key == 'medicine': return 'ঔষধ'
        if key == 'appointment': return 'চিকিৎসা সাক্ষাত'
        if key == 'activity': return 'দৈনিক কাৰ্যসূচী'
        if key == 'completedLabel': return 'সম্পূৰ্ণ হ\'ল'
        if key == 'pendingLabel': return 'বাকী আছে'
        if key == 'logout': return 'লগ আউট'
        if key == 'login': return 'লগ ইন'
        if key == 'register': return 'পঞ্জীয়ন কৰক'
        if key == 'elder': return 'জ্যেষ্ঠ'
        if key == 'caretaker': return 'পৰিচৰ্যাকাৰী'

    # Bengali (bn)
    elif lang == 'bn':
        if key == 'appName': return 'পূর্ব চেতনা'
        if key == 'tagline': return 'উত্তর-পূর্ব ও তামিলনাড়ুর জন্য এআই প্রবীণ প্রজ্ঞামূলক সহকারী'
        if key == 'elderDashboard': return 'প্রবীণ ড্যাশবোর্ড'
        if key == 'caretakerDashboard': return 'সেবিকা/যত্নশীল ড্যাশবোর্ড'
        if key == 'todayScheduleOverview': return 'আজকের সময়সূচী পর্যালোচনা'
        if key == 'cognitiveExercisesTitle': return 'দৈনিক প্রজ্ঞামূলক ব্যায়াম'
        if key == 'memoryLane': return 'স্মৃতি সরণি (Memory Lane)'
        if key == 'save': return 'সংরক্ষণ করুন'
        if key == 'saveBtn': return 'সংরক্ষণ করুন'
        if key == 'delete': return 'মুছে ফেলুন'
        if key == 'deleteBtn': return 'মুছে ফেলুন'
        if key == 'cancel': return 'বাতিল করুন'
        if key == 'cancelBtn': return 'বাতিল করুন'
        if key == 'add': return 'যোগ করুন'
        if key == 'addBtn': return 'যোগ করুন'
        if key == 'audio': return 'অডিও'
        if key == 'video': return 'ভিডিও'
        if key == 'photo': return 'ছবি'
        if key == 'mediaTypeAudio': return 'অডিও'
        if key == 'mediaTypeVideo': return 'ভিডিও'
        if key == 'mediaTypePhoto': return 'ছবি'
        if key == 'medicine': return 'ঔষধ'
        if key == 'appointment': return 'চিকিৎসকের অ্যাপয়েন্টমেন্ট'
        if key == 'activity': return 'দৈনিক ক্রিয়াকলাপ'
        if key == 'completedLabel': return 'সম্পন্ন হয়েছে'
        if key == 'pendingLabel': return 'বাকি আছে'
        if key == 'logout': return 'লগ আউট'
        if key == 'login': return 'লগ ইন'
        if key == 'register': return 'নিবন্ধন করুন'
        if key == 'elder': return 'প্রবীণ'
        if key == 'caretaker': return 'সেবিকা'

    # Manipuri (mni)
    elif lang == 'mni':
        if key == 'appName': return 'পূপ চেতনা'
        if key == 'tagline': return 'নোংপোক্ষ কোইবা অমসুং তামিলনাডুগী এআই অহলগী ৱাখল লৌশিং মতেং'
        if key == 'elderDashboard': return 'অহলগী ড্যাশবোর্ড'
        if key == 'caretakerDashboard': return 'য়ুমথম্বাগী ড্যাশবোর্ড'
        if key == 'todayScheduleOverview': return 'ঙসীগী থৌরাং য়েংশিনবা'
        if key == 'cognitiveExercisesTitle': return 'নুমিৎ খুদিংগী ৱাখলগী এক্সারসাইজশিং'
        if key == 'memoryLane': return 'নিনিংশিং লম্বী (Memory Lane)'
        if key == 'save': return 'শেভ তৌবা'
        if key == 'saveBtn': return 'শেভ তৌবা'
        if key == 'delete': return 'মুত্থোকপা'
        if key == 'deleteBtn': return 'মুত্থোকপা'
        if key == 'cancel': return 'কাকথোকপা'
        if key == 'cancelBtn': return 'কাকথোকপা'
        if key == 'add': return 'হাপচিনবা'
        if key == 'addBtn': return 'হাপচিনবা'
        if key == 'audio': return 'ওডিও'
        if key == 'video': return 'ভিডিও'
        if key == 'photo': return 'ফোতো'
        if key == 'mediaTypeAudio': return 'ওডিও'
        if key == 'mediaTypeVideo': return 'ভিডিও'
        if key == 'mediaTypePhoto': return 'ফোতো'
        if key == 'medicine': return 'হিদাক'
        if key == 'appointment': return 'লাইয়েংবগা উনবগী থৌরাং'
        if key == 'activity': return 'নুমিৎ খুদিংগী থৌরাং'
        if key == 'completedLabel': return 'লোইরে'
        if key == 'pendingLabel': return 'লোইদ্রি'
        if key == 'logout': return 'লগ আউট'
        if key == 'login': return 'লগ ইন'
        if key == 'register': return 'রেজিষ্টার তৌবা'
        if key == 'elder': return 'অহল'
        if key == 'caretaker': return 'য়ুমথম্বা'

    # Mizo (lus)
    elif lang == 'lus':
        if key == 'appName': return 'Purb Chetana'
        if key == 'tagline': return 'Northeast leh Tamil Nadu tana AI Upa Hriatreuna Puitu'
        if key == 'elderDashboard': return 'Upa Dashboard'
        if key == 'caretakerDashboard': return 'Chawmhtu Dashboard'
        if key == 'todayScheduleOverview': return 'Vawin Hun Ruahman Inenlawkna'
        if key == 'cognitiveExercisesTitle': return 'Nitin Hriatreuna Sahlam Te'
        if key == 'memoryLane': return 'Hriatreuna Lamlien (Memory Lane)'
        if key == 'save': return 'Vawng tha rawh'
        if key == 'saveBtn': return 'Vawng tha rawh'
        if key == 'delete': return 'Nawhre rawng'
        if key == 'deleteBtn': return 'Nawhre rawng'
        if key == 'cancel': return 'Thulh rawh'
        if key == 'cancelBtn': return 'Thulh rawh'
        if key == 'add': return 'Belh rawh'
        if key == 'addBtn': return 'Belh rawh'
        if key == 'audio': return 'Audio'
        if key == 'video': return 'Video'
        if key == 'photo': return 'Thlalak'
        if key == 'mediaTypeAudio': return 'Audio'
        if key == 'mediaTypeVideo': return 'Video'
        if key == 'mediaTypePhoto': return 'Thlalak'
        if key == 'medicine': return 'Damdawi'
        if key == 'appointment': return 'Daktawr Inhmuhna'
        if key == 'activity': return 'Nitin Thiltih'
        if key == 'completedLabel': return 'Zo tawh'
        if key == 'pendingLabel': return 'La ti lo'
        if key == 'logout': return 'Chhuak rawh'
        if key == 'login': return 'Lut rawh'
        if key == 'register': return 'Inriang lut rawh'
        if key == 'elder': return 'Upa'
        if key == 'caretaker': return 'Chawmhtu'

    # Khasi (kha)
    elif lang == 'kha':
        if key == 'appName': return 'Purb Chetana'
        if key == 'tagline': return 'Yarrap bad ai jingmut ba bha ia ki tymmen ha Northeast bad Tamil Nadu'
        if key == 'elderDashboard': return 'Ki Tymmen Dashboard'
        if key == 'caretakerDashboard': return 'Jingsumar Dashboard'
        if key == 'todayScheduleOverview': return 'Jingkynmaw Ki Kam Minta Ka Sngi'
        if key == 'cognitiveExercisesTitle': return 'Ki Kam Pynkit Jingmut Man Ka Sngi'
        if key == 'memoryLane': return 'Lynti Jingkynmaw (Memory Lane)'
        if key == 'save': return 'Kynshew'
        if key == 'saveBtn': return 'Kynshew'
        if key == 'delete': return 'Pynduh'
        if key == 'deleteBtn': return 'Pynduh'
        if key == 'cancel': return 'Pynsangeh'
        if key == 'cancelBtn': return 'Pynsangeh'
        if key == 'add': return 'Buh lang'
        if key == 'addBtn': return 'Buh lang'
        if key == 'audio': return 'Audio'
        if key == 'video': return 'Video'
        if key == 'photo': return 'Dur'
        if key == 'mediaTypeAudio': return 'Audio'
        if key == 'mediaTypeVideo': return 'Video'
        if key == 'mediaTypePhoto': return 'Dur'
        if key == 'medicine': return 'Dawai'
        if key == 'appointment': return 'Jingiashem Bad Nongsumar'
        if key == 'activity': return 'Ki Kam Man Ka Sngi'
        if key == 'completedLabel': return 'Dep'
        if key == 'pendingLabel': return 'Sah'
        if key == 'logout': return 'Mih'
        if key == 'login': return 'Buh kyrteng'
        if key == 'register': return 'Register'
        if key == 'elder': return 'Ki Tymmen'
        if key == 'caretaker': return 'Jingsumar'

    # Nagamese (nag)
    elif lang == 'nag':
        if key == 'appName': return 'Purb Chetana'
        if key == 'tagline': return 'Northeast aru Tamil Nadu laga bura manu khan ke AI help kuribole'
        if key == 'elderDashboard': return 'Bura Manu Dashboard'
        if key == 'caretakerDashboard': return 'Caregiver Dashboard'
        if key == 'todayScheduleOverview': return 'Aji laga time-table dekhibo'
        if key == 'cognitiveExercisesTitle': return 'Rojina Dimaag Laga Exercise'
        if key == 'memoryLane': return 'Yaad Laga Rasta (Memory Lane)'
        if key == 'save': return 'Save kuribi'
        if key == 'saveBtn': return 'Save kuribi'
        if key == 'delete': return 'Delete kuribi'
        if key == 'deleteBtn': return 'Delete kuribi'
        if key == 'cancel': return 'Cancel kuribi'
        if key == 'cancelBtn': return 'Cancel kuribi'
        if key == 'add': return 'Add kuribi'
        if key == 'addBtn': return 'Add kuribi'
        if key == 'audio': return 'Audio'
        if key == 'video': return 'Video'
        if key == 'photo': return 'Photo'
        if key == 'mediaTypeAudio': return 'Audio'
        if key == 'mediaTypeVideo': return 'Video'
        if key == 'mediaTypePhoto': return 'Photo'
        if key == 'medicine': return 'Dawa'
        if key == 'appointment': return 'Doctor Milibo Time'
        if key == 'activity': return 'Rojina Kam'
        if key == 'completedLabel': return 'Kuri loishe'
        if key == 'pendingLabel': return 'Bachi ase'
        if key == 'logout': return 'Logout kuribi'
        if key == 'login': return 'Login kuribi'
        if key == 'register': return 'Register kuribi'
        if key == 'elder': return 'Bura Manu'
        if key == 'caretaker': return 'Caregiver'

    # Default fallback to English text while preserving placeholders
    return en_text

# Generate code for all languages
langs = ['as', 'bn', 'mni', 'lus', 'kha', 'nag']
generated_maps = {}

for lang in langs:
    dict_code = f"    '{lang}': {{\n"
    for k, v in en_kv.items():
        trans_v = translate_key(k, v, lang)
        # Escape single quotes and backslashes for Dart string literal
        safe_v = trans_v.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
        dict_code += f"      '{k}': '{safe_v}',\n"
    dict_code += "    },"
    generated_maps[lang] = dict_code

print("Generated code for 6 languages successfully.")
