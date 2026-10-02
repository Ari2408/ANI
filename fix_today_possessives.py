import re

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix possessive 's on non-English words
replacements = {
    "'todayScheduleOverview': 'Today\\'s Schedule Overview'": {
        'en': "'todayScheduleOverview': 'Today\\'s Schedule Overview'",
        'ta': "'todayScheduleOverview': 'இன்றைய அட்டவணைப் பார்வை'",
        'ne': "'todayScheduleOverview': 'आजको समयसूची अवलोकन'",
        'as': "'todayScheduleOverview': 'আজিসমূহৰ কাৰ্যসূচীৰ পৰ্যালোচনা'",
        'bn': "'todayScheduleOverview': 'আজকের সময়সূচী পর্যালোচনা'",
        'mni': "'todayScheduleOverview': 'ঙসীগী থৌরাং য়েংশিনবা'",
        'lus': "'todayScheduleOverview': 'Vawin Hun Ruahman Inenlawkna'",
        'kha': "'todayScheduleOverview': 'Jingkynmaw Ki Kam Minta Ka Sngi'",
        'nag': "'todayScheduleOverview': 'Aji laga time-table dekhibo'",
    },
    "'todayReminders': 'Today\\'s Reminders'": {
        'en': "'todayReminders': 'Today\\'s Reminders'",
        'ta': "'todayReminders': 'இன்றைய நினைவூட்டல்கள்'",
        'ne': "'todayReminders': 'आजका सम्झौटोहरू'",
        'as': "'todayReminders': 'আজিকাকৰি সোঁৱৰণীসমূহ'",
        'bn': "'todayReminders': 'আজকের রিমাইন্ডার'",
        'mni': "'todayReminders': 'ঙসীগী নিনিংশিংৱা'",
        'lus': "'todayReminders': 'Vawin Hriattirna te'",
        'kha': "'todayReminders': 'Ki Jingpyntip Minta Ka Sngi'",
        'nag': "'todayReminders': 'Aji laga reminder khan'",
    },
    "'todayOverviewDesc': 'Overview of today\\'s health vitals and reminders'": {
        'en': "'todayOverviewDesc': 'Overview of today\\'s health vitals and reminders'",
        'ta': "'todayOverviewDesc': 'இன்றைய ஆரோக்கியம் மற்றும் நினைவூட்டல்களின் பார்வை'",
        'ne': "'todayOverviewDesc': 'आजको स्वास्थ्य र सम्झौटोहरूको अवलोकन'",
        'as': "'todayOverviewDesc': 'আজিৰ স্বাস্থ্য আৰু সোঁৱৰণীসমূহৰ পৰ্যালোচনা'",
        'bn': "'todayOverviewDesc': 'আজকের স্বাস্থ্য ও রিমাইন্ডারের পর্যালোচনা'",
        'mni': "'todayOverviewDesc': 'ঙসীগী হিদাক অমসুং নিনিংশিংৱাগী য়েংশিনবা'",
        'lus': "'todayOverviewDesc': 'Vawin chanchin kimchang leh hriattirna te'",
        'kha': "'todayOverviewDesc': 'Jingkynmaw ka um dih bad ki kam minta ka sngi'",
        'nag': "'todayOverviewDesc': 'Aji laga health aru reminder dekhibo'",
    }
}

# Remove any \'s appended to non-English words like আজ\'s, আজিসমূহৰ\'s, ঙসী\'s, Vawin\'s, Minta ka sngi\'s, Aji\'s, இன்று\'s
for non_en_word in ['இன்று', 'আজ', 'আজি', 'ঙসী', 'Vawin', 'Minta ka sngi', 'Aji']:
    content = content.replace(f"{non_en_word}\\'s", f"{non_en_word}")
    content = content.replace(f"{non_en_word}'s", f"{non_en_word}")

with open('/home/dinakar3108/Downloads/PR1/lib/services/i18n_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Cleaned up possessive 's and slashes near Today across all languages.")
