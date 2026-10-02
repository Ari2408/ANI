import re

# 1. Update AnimatedSplashIntroScreen
splash_path = '/home/dinakar3108/Downloads/PR1/lib/screens/animated_splash_intro_screen.dart'
with open(splash_path, 'r', encoding='utf-8') as f:
    splash_code = f.read()

# Replace _features definition
old_features = """  final List<Map<String, String>> _features = [
    {
      'icon': '🧠',
      'titleKeyEn': 'AI Cognitive Brain Games',
      'titleKeyTa': 'முறையான மூளை திறன் விளையாட்டு',
      'descKeyEn': 'Adaptive memory, pattern matching & attention exercises',
      'descKeyTa': 'நினைவாற்றல் மற்றும் கவனத்தை மேம்படுத்தும் பயிற்சிகள்',
    },
    {
      'icon': '📸',
      'titleKeyEn': 'Nostalgic Memory Lane',
      'titleKeyTa': 'பொக்கிஷமான குடும்ப நினைவுகள்',
      'descKeyEn': 'Cultural landmarks, personal photos, videos & voice notes',
      'descKeyTa': 'புகைப்படங்கள், வீடியோக்கள் மற்றும் அன்பான குரல் கதைகள்',
    },
    {
      'icon': '⏰',
      'titleKeyEn': 'Voice Reminders & Caregiver Support',
      'titleKeyTa': 'அன்பான குரல் நினைவூட்டல்கள்',
      'descKeyEn': 'Multilingual medication, hydration & schedule alarms',
      'descKeyTa': 'மருந்து மற்றும் நீரேற்ற நேரடி குரல் அறிவிப்புகள்',
    },
  ];"""

new_features = """  final List<Map<String, String>> _features = [
    {
      'icon': '🧠',
      'titleKey': 'cognitiveBrainGamesTitle',
      'descKey': 'cognitiveBrainGamesDesc',
    },
    {
      'icon': '📸',
      'titleKey': 'nostalgicMemoryLaneTitle',
      'descKey': 'nostalgicMemoryLaneDesc',
    },
    {
      'icon': '⏰',
      'titleKey': 'voiceRemindersSupportTitle',
      'descKey': 'voiceRemindersSupportDesc',
    },
  ];"""

splash_code = splash_code.replace(old_features, new_features)

# Replace tagline, feature title, feature desc, button label, isTa check
splash_code = splash_code.replace("final isTa = i18n.currentLang == 'ta';", "")
splash_code = splash_code.replace(
    "isTa ? '✨ AI முதியோர் உதவி தளம்' : '✨ AI Cognitive Elderly Platform'",
    "'✨ ' + i18n.translate('platformTagline')"
)
splash_code = splash_code.replace(
    "isTa ? feature['titleKeyTa']! : feature['titleKeyEn']!",
    "i18n.translate(feature['titleKey']!)"
)
splash_code = splash_code.replace(
    "isTa ? feature['descKeyTa']! : feature['descKeyEn']!",
    "i18n.translate(feature['descKey']!)"
)
splash_code = splash_code.replace(
    "label: isTa ? 'தொடங்குவோம் 🚀' : 'Get Started 🚀',",
    "label: '${i18n.translate('getStarted')} 🚀',"
)
splash_code = splash_code.replace(
    "fontFamily: isTa ? 'Noto Serif Tamil' : 'Comic Relief',",
    "fontFamily: i18n.currentLang == 'ta' ? 'Noto Serif Tamil' : (['as', 'bn', 'mni', 'ne'].contains(i18n.currentLang) ? null : 'Comic Relief'),"
)

with open(splash_path, 'w', encoding='utf-8') as f:
    f.write(splash_code)
print("Updated AnimatedSplashIntroScreen successfully.")

# 2. Update AiCognitiveEngine
engine_path = '/home/dinakar3108/Downloads/PR1/lib/services/ai_cognitive_engine.dart'
with open(engine_path, 'r', encoding='utf-8') as f:
    engine_code = f.read()

# Replace _chiHistory initial date
engine_code = engine_code.replace("'date': 'Day 1'", "'date': 'dayLabel'")
engine_code = engine_code.replace("'date': 'Today'", "'date': 'todayLabel'")

# Remove defaultTitle and defaultSubtitle from _dailyExercises
old_daily = """  final List<Map<String, dynamic>> _dailyExercises = [
    {
      'id': 'ex_visual_game',
      'titleKey': 'visualMemoryMatchTitle',
      'defaultTitle': 'Visual Memory Matching',
      'subtitleKey': 'visualMemoryMatchDesc',
      'defaultSubtitle': 'Match card pairs to test & sharpen visual memory',
      'type': 'game', // 'game' or 'memory'
      'icon': '🧩',
      'isCompleted': false,
    },
    {
      'id': 'ex_family_memory',
      'titleKey': 'familyMemoryRecallTitle',
      'defaultTitle': 'Family Memory Recall',
      'subtitleKey': 'familyMemoryRecallDesc',
      'defaultSubtitle': 'Reflect & recall personal family photos & memory notes',
      'type': 'memory', // 'game' or 'memory'
      'icon': '📸',
      'isCompleted': false,
    },
    {
      'id': 'ex_pattern_game',
      'titleKey': 'patternSortTitle',
      'defaultTitle': 'Pattern & Sequence Sorting',
      'subtitleKey': 'patternSortDesc',
      'defaultSubtitle': 'Arrange pattern sequences to improve attention & focus',
      'type': 'game',
      'icon': '🎯',
      'isCompleted': false,
    },
    {
      'id': 'ex_voice_memory',
      'titleKey': 'voiceStoryReflectionTitle',
      'defaultTitle': 'Voice & Story Reflection',
      'subtitleKey': 'voiceStoryReflectionDesc',
      'defaultSubtitle': 'Listen to caretaker voice memories & reflect on stories',
      'type': 'memory',
      'icon': '🎙️',
      'isCompleted': false,
    },
  ];"""

new_daily = """  final List<Map<String, dynamic>> _dailyExercises = [
    {
      'id': 'ex_visual_game',
      'titleKey': 'visualMemoryMatchTitle',
      'subtitleKey': 'visualMemoryMatchDesc',
      'type': 'game', // 'game' or 'memory'
      'icon': '🧩',
      'isCompleted': false,
    },
    {
      'id': 'ex_family_memory',
      'titleKey': 'familyMemoryRecallTitle',
      'subtitleKey': 'familyMemoryRecallDesc',
      'type': 'memory', // 'game' or 'memory'
      'icon': '📸',
      'isCompleted': false,
    },
    {
      'id': 'ex_pattern_game',
      'titleKey': 'patternSortTitle',
      'subtitleKey': 'patternSortDesc',
      'type': 'game',
      'icon': '🎯',
      'isCompleted': false,
    },
    {
      'id': 'ex_voice_memory',
      'titleKey': 'voiceStoryReflectionTitle',
      'subtitleKey': 'voiceStoryReflectionDesc',
      'type': 'memory',
      'icon': '🎙️',
      'isCompleted': false,
    },
  ];"""

engine_code = engine_code.replace(old_daily, new_daily)

with open(engine_path, 'w', encoding='utf-8') as f:
    f.write(engine_code)
print("Updated AiCognitiveEngine successfully.")

# 3. Update main.dart title & updateI1n -> updateI18n
main_path = '/home/dinakar3108/Downloads/PR1/lib/main.dart'
with open(main_path, 'r', encoding='utf-8') as f:
    main_code = f.read()

main_code = main_code.replace("title: 'Purb Chetana - AI Cognitive & Memory Assistant',", "title: '${i18n.translate(\"appName\")} - ${i18n.translate(\"tagline\")}',")
main_code = main_code.replace("schedule?.updateI1n(i18n);", "schedule?.updateI18n(i18n);")

with open(main_path, 'w', encoding='utf-8') as f:
    f.write(main_code)
print("Updated main.dart successfully.")

# 4. Update schedule_service.dart & main_navigation_screen.dart updateI1n -> updateI18n
sched_path = '/home/dinakar3108/Downloads/PR1/lib/services/schedule_service.dart'
with open(sched_path, 'r', encoding='utf-8') as f:
    sched_code = f.read()
sched_code = sched_code.replace("void updateI1n(", "void updateI18n(")
with open(sched_path, 'w', encoding='utf-8') as f:
    f.write(sched_code)

nav_path = '/home/dinakar3108/Downloads/PR1/lib/screens/main_navigation_screen.dart'
with open(nav_path, 'r', encoding='utf-8') as f:
    nav_code = f.read()
nav_code = nav_code.replace("schedule.updateI1n(i18n);", "schedule.updateI18n(i18n);")
with open(nav_path, 'w', encoding='utf-8') as f:
    f.write(nav_code)

print("Updated updateI1n -> updateI18n across services and screens successfully.")

