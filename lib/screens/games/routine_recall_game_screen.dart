import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/i18n_service.dart';
import '../../services/ai_cognitive_engine.dart';
import '../../widgets/elder_card.dart';
import '../../widgets/elder_button.dart';

class RoutineActivityItem {
  final String id;
  final String titleEn;
  final String titleTa;
  final String timeSlot;
  final IconData icon;
  final Color themeColor;
  final int correctIndex;

  RoutineActivityItem({
    required this.id,
    required this.titleEn,
    required this.titleTa,
    required this.timeSlot,
    required this.icon,
    required this.themeColor,
    required this.correctIndex,
  });
}

class RoutineRecallGameScreen extends StatefulWidget {
  const RoutineRecallGameScreen({Key? key}) : super(key: key);

  @override
  State<RoutineRecallGameScreen> createState() => _RoutineRecallGameScreenState();
}

class _RoutineRecallGameScreenState extends State<RoutineRecallGameScreen> {
  final FlutterTts _tts = FlutterTts();
  late List<RoutineActivityItem> _userOrderedItems;
  bool _isSuccess = false;
  int _mistakesCount = 0;
  String _feedbackMessage = '';

  final List<RoutineActivityItem> _masterCatalog = [
    RoutineActivityItem(
      id: 'act_wake',
      titleEn: '1. Waking Up in Morning',
      titleTa: '1. காலை விழித்தெழுதல்',
      timeSlot: 'Morning',
      icon: Icons.wb_sunny,
      themeColor: const Color(0xFFD97706),
      correctIndex: 0,
    ),
    RoutineActivityItem(
      id: 'act_brush',
      titleEn: '2. Brushing Teeth & Washing Face',
      titleTa: '2. பல் துலக்கி முகம் கழுவுதல்',
      timeSlot: 'Morning',
      icon: Icons.auto_awesome,
      themeColor: const Color(0xFF0284C7),
      correctIndex: 1,
    ),
    RoutineActivityItem(
      id: 'act_tea',
      titleEn: '3. Morning Tea / Red Tea',
      titleTa: '3. காலை தேநீர் அருந்துதல்',
      timeSlot: 'Morning',
      icon: Icons.coffee,
      themeColor: const Color(0xFF92400E),
      correctIndex: 2,
    ),
    RoutineActivityItem(
      id: 'act_prayer',
      titleEn: '4. Bath & Morning Prayer / Worship',
      titleTa: '4. குளித்து இறை வழிபாடு செய்தல்',
      timeSlot: 'Morning',
      icon: Icons.notifications_active,
      themeColor: const Color(0xFF7E22CE),
      correctIndex: 3,
    ),
    RoutineActivityItem(
      id: 'act_lunch',
      titleEn: '5. Midday Rice & Curry Lunch',
      titleTa: '5. மதிய உணவு சாப்பிடுதல்',
      timeSlot: 'Afternoon',
      icon: Icons.restaurant,
      themeColor: const Color(0xFF059669),
      correctIndex: 4,
    ),
    RoutineActivityItem(
      id: 'act_meds',
      titleEn: '6. Taking Afternoon Medicine',
      titleTa: '6. மதிய மருந்து சாப்பிடுதல்',
      timeSlot: 'Afternoon',
      icon: Icons.medication,
      themeColor: const Color(0xFFE11D48),
      correctIndex: 5,
    ),
    RoutineActivityItem(
      id: 'act_nap',
      titleEn: '7. Short Afternoon Rest / Nap',
      titleTa: '7. மதிய குட்டி ஓய்வு எடுத்தல்',
      timeSlot: 'Afternoon',
      icon: Icons.chair,
      themeColor: const Color(0xFF475569),
      correctIndex: 6,
    ),
    RoutineActivityItem(
      id: 'act_courtyard',
      titleEn: '8. Evening Family Courtyard Time',
      titleTa: '8. மாலை குடும்பத்தினருடன் பேசுதல்',
      timeSlot: 'Evening',
      icon: Icons.people,
      themeColor: const Color(0xFF0891B2),
      correctIndex: 7,
    ),
    RoutineActivityItem(
      id: 'act_dinner',
      titleEn: '9. Night Dinner with Family',
      titleTa: '9. இரவு உணவு சாப்பிடுதல்',
      timeSlot: 'Night',
      icon: Icons.rice_bowl,
      themeColor: const Color(0xFFD97706),
      correctIndex: 8,
    ),
    RoutineActivityItem(
      id: 'act_sleep',
      titleEn: '10. Going to Sleep in Bed',
      titleTa: '10. இரவு தூங்கச் செல்லுதல்',
      timeSlot: 'Night',
      icon: Icons.bedtime,
      themeColor: const Color(0xFF1E3A8A),
      correctIndex: 9,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    final shuffled = List<RoutineActivityItem>.from(_masterCatalog)..shuffle();
    setState(() {
      _userOrderedItems = shuffled;
      _isSuccess = false;
      _mistakesCount = 0;
      _feedbackMessage = '';
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _userOrderedItems.removeAt(oldIndex);
      _userOrderedItems.insert(newIndex, item);
      _feedbackMessage = '';
    });
  }

  void _moveItemUp(int index) {
    if (index > 0) {
      _onReorder(index, index - 1);
    }
  }

  void _moveItemDown(int index) {
    if (index < _userOrderedItems.length - 1) {
      _onReorder(index, index + 2);
    }
  }

  void _speakInstruction() async {
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';
    final text = isTamil
        ? 'காலை முதல் இரவு வரை உங்கள் 10 நாளாந்த பழக்கங்களை இழுத்து சரியான வரிசையில் அமைக்கவும்.'
        : 'Drag and arrange your 10 daily activities in order from morning to night.';
    await _tts.setLanguage(isTamil ? 'ta-IN' : 'en-US');
    await _tts.speak(text);
  }

  void _checkSequence() {
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';
    final aiEngine = Provider.of<AiCognitiveEngine>(context, listen: false);

    int outOfOrderCount = 0;
    for (int i = 0; i < _userOrderedItems.length; i++) {
      if (_userOrderedItems[i].correctIndex != i) {
        outOfOrderCount++;
      }
    }

    if (outOfOrderCount == 0) {
      setState(() {
        _isSuccess = true;
        _feedbackMessage = isTamil
            ? 'அற்புதம்! உங்கள் 10 நாளாந்த செயல்பாடுகளின் வரிசை மிகச்சரியாக உள்ளது!'
            : 'Splendid! All 10 daily activities are in perfect order!';
      });

      aiEngine.recordSessionResult(
        gameType: 'routine',
        timeSeconds: 40,
        mistakes: _mistakesCount,
        accuracyPct: 100,
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isTamil ? 'அற்புதமான நாளாந்த ஒழுங்கு!' : 'Perfect Daily Flow!',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
          ),
          content: Text(
            isTamil
                ? 'காலை முதல் இரவு வரை 10 செயல்பாடுகளையும் சரியாக வரிசைப்படுத்தினீர்கள்!'
                : 'You successfully arranged all 10 daily routines from morning to night!',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetGame();
              },
              child: Text(
                isTamil ? 'மீண்டும் வரிசைப்படுத்து' : 'Reorder Again',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF23B39B)),
              ),
            )
          ],
        ),
      );
    } else {
      setState(() {
        _mistakesCount++;
        _feedbackMessage = isTamil
            ? '$outOfOrderCount செயல்பாடுகள் மாறுபட்டுள்ளன. இழுத்து சரிசெய்யவும்.'
            : '$outOfOrderCount activities are out of order. Drag items to adjust.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = Provider.of<I18nService>(context);
    final isTamil = i18n.currentLang == 'ta';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'என் நாள் (சுய பழக்கவரிசை)' : 'My Day (10 Routines Drag)'),
        backgroundColor: const Color(0xFF61C5B0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: isTamil ? 'மீட்டமை' : 'Shuffle Cards',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Instruction Card
            ElderCard(
              backgroundColor: const Color(0xFFFDF0E6),
              border: Border.all(color: const Color(0xFFE59866), width: 1.5),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTamil ? '10 பழக்கங்களை இழுத்து அமைக்கவும்:' : 'Drag & arrange 10 activities:',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Color(0xFFD97706)),
                        onPressed: _speakInstruction,
                        tooltip: isTamil ? 'ஒலி கேட்க' : 'Hear Instructions',
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isTamil
                        ? 'வலதுபுற கைபிடியை பிடித்து இழுத்து அல்லது அம்புக்குறிகளை தொட்டு வரிசைப்படுத்துங்கள்'
                        : 'Hold & drag handle on the right or tap arrows to reorder from morning to night.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF78350F)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (_feedbackMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _isSuccess ? const Color(0xFF16A34A) : const Color(0xFFF59E0B)),
                ),
                child: Text(
                  _feedbackMessage,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _isSuccess ? const Color(0xFF15803D) : const Color(0xFF92400E),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Drag-and-Drop Reorderable List of 10 Options
            Expanded(
              child: Theme(
                data: ThemeData(canvasColor: Colors.transparent),
                child: ReorderableListView.builder(
                  onReorder: _onReorder,
                  itemCount: _userOrderedItems.length,
                  itemBuilder: (ctx, idx) {
                    final item = _userOrderedItems[idx];
                    final isCorrectPos = item.correctIndex == idx;

                    return Container(
                      key: ValueKey(item.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ElderCard(
                        backgroundColor: isCorrectPos ? const Color(0xFFF0FDF4) : Colors.white,
                        border: Border.all(
                          color: isCorrectPos ? const Color(0xFF23B39B) : const Color(0xFFCDE4E2),
                          width: isCorrectPos ? 2 : 1,
                        ),
                        child: Row(
                          children: [
                            // Step Badge Number
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: item.themeColor,
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Icon
                            Icon(item.icon, size: 28, color: item.themeColor),
                            const SizedBox(width: 10),

                            // Text Label & Time Slot
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTamil ? item.titleTa : item.titleEn,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.timeSlot,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: item.themeColor),
                                  ),
                                ],
                              ),
                            ),

                            // Touch Arrows for easy tap-reordering
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (idx > 0)
                                  IconButton(
                                    icon: const Icon(Icons.arrow_upward, size: 20, color: Color(0xFF0284C7)),
                                    onPressed: () => _moveItemUp(idx),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                const SizedBox(width: 4),
                                if (idx < _userOrderedItems.length - 1)
                                  IconButton(
                                    icon: const Icon(Icons.arrow_downward, size: 20, color: Color(0xFF0284C7)),
                                    onPressed: () => _moveItemDown(idx),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                const SizedBox(width: 8),

                                // Drag handle
                                const Icon(Icons.drag_handle, color: Colors.grey, size: 28),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Check Sequence Action Button
            ElderButton(
              label: isTamil ? 'வரிசையை சரிபார் (Check Order)' : 'Check 10-Step Order',
              onPressed: _checkSequence,
              backgroundColor: const Color(0xFF23B39B),
            ),
          ],
        ),
      ),
    );
  }
}
