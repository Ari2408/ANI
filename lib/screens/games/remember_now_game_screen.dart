import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/ai_cognitive_engine.dart';
import '../../services/i18n_service.dart';
import '../../widgets/elder_card.dart';

class RoutineQuizOption {
  final String id;
  final String labelEn;
  final String labelTa;
  final IconData icon;
  final Color color;
  final bool isCorrect;

  RoutineQuizOption({
    required this.id,
    required this.labelEn,
    required this.labelTa,
    required this.icon,
    required this.color,
    required this.isCorrect,
  });
}

class RoutineQuizQuestion {
  final String id;
  final String timeDisplay;
  final String questionEn;
  final String questionTa;
  final List<RoutineQuizOption> options;

  RoutineQuizQuestion({
    required this.id,
    required this.timeDisplay,
    required this.questionEn,
    required this.questionTa,
    required this.options,
  });
}

class RememberNowGameScreen extends StatefulWidget {
  const RememberNowGameScreen({Key? key}) : super(key: key);

  @override
  State<RememberNowGameScreen> createState() => _RememberNowGameScreenState();
}

class _RememberNowGameScreenState extends State<RememberNowGameScreen> {
  final FlutterTts _tts = FlutterTts();
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedOptionId;
  bool _isAnswered = false;
  String _feedbackMessage = '';

  final List<RoutineQuizQuestion> _questions = [
    RoutineQuizQuestion(
      id: 'q_afternoon_meds',
      timeDisplay: '2:00 PM (Afternoon)',
      questionEn: 'It is 2:00 PM after lunch. What is it time to do now?',
      questionTa: 'மதிய உணவுக்குப் பின் மதியம் 2:00 மணிக்கு இப்போது என்ன செய்ய வேண்டும்?',
      options: [
        RoutineQuizOption(
          id: 'opt_meds',
          labelEn: 'Take Afternoon Medicine',
          labelTa: 'மதிய மருந்து சாப்பிட வேண்டும்',
          icon: Icons.medication,
          color: const Color(0xFFE11D48),
          isCorrect: true,
        ),
        RoutineQuizOption(
          id: 'opt_comb',
          labelEn: 'Comb Hair',
          labelTa: 'தலை வார வேண்டும்',
          icon: Icons.content_cut,
          color: const Color(0xFF64748B),
          isCorrect: false,
        ),
        RoutineQuizOption(
          id: 'opt_wash',
          labelEn: 'Wash Clothes',
          labelTa: 'துணி துவைக்க வேண்டும்',
          icon: Icons.dry_cleaning,
          color: const Color(0xFF0284C7),
          isCorrect: false,
        ),
      ],
    ),
    RoutineQuizQuestion(
      id: 'q_morning_hydration',
      timeDisplay: '11:00 AM (Mid-Morning)',
      questionEn: 'The mid-morning bell rang. What does your body need now?',
      questionTa: 'காலை 11:00 மணிக்கு உடலுக்கு இப்போது என்ன தேவை?',
      options: [
        RoutineQuizOption(
          id: 'opt_water',
          labelEn: 'Drink Glass of Water / Tea',
          labelTa: 'தண்ணீர் / தேநீர் குடிக்க வேண்டும்',
          icon: Icons.water_drop,
          color: const Color(0xFF0284C7),
          isCorrect: true,
        ),
        RoutineQuizOption(
          id: 'opt_lock',
          labelEn: 'Lock the Front Door',
          labelTa: 'கதவைப் பூட்ட வேண்டும்',
          icon: Icons.lock,
          color: const Color(0xFF64748B),
          isCorrect: false,
        ),
        RoutineQuizOption(
          id: 'opt_sleep',
          labelEn: 'Sleep for Night',
          labelTa: 'இரவு தூங்க வேண்டும்',
          icon: Icons.bed,
          color: const Color(0xFF475569),
          isCorrect: false,
        ),
      ],
    ),
    RoutineQuizQuestion(
      id: 'q_evening_stroll',
      timeDisplay: '5:30 PM (Sunset)',
      questionEn: 'The sun is setting over the hills. What is our evening routine?',
      questionTa: 'மாலை 5:30 மணிக்கு சூரியன் மறையும் நேரம். நமது மாலை நேர பழக்கம் என்ன?',
      options: [
        RoutineQuizOption(
          id: 'opt_walk',
          labelEn: 'Gentle Walk in Courtyard',
          labelTa: 'முற்றத்தில் மாலை நடைபயிற்சி',
          icon: Icons.directions_walk,
          color: const Color(0xFFD97706),
          isCorrect: true,
        ),
        RoutineQuizOption(
          id: 'opt_umbrella',
          labelEn: 'Open Umbrella Indoors',
          labelTa: 'வீட்டிற்குள் குடை பிடிப்பது',
          icon: Icons.umbrella,
          color: const Color(0xFF64748B),
          isCorrect: false,
        ),
        RoutineQuizOption(
          id: 'opt_brush',
          labelEn: 'Brush Teeth for Morning',
          labelTa: 'காலை பல் துலக்குவது',
          icon: Icons.auto_awesome,
          color: const Color(0xFF059669),
          isCorrect: false,
        ),
      ],
    ),
  ];

  void _speakQuestion() async {
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';
    final q = _questions[_currentIndex % _questions.length];
    final text = isTamil ? q.questionTa : q.questionEn;
    await _tts.setLanguage(isTamil ? 'ta-IN' : 'en-US');
    await _tts.speak(text);
  }

  void _onOptionTap(RoutineQuizOption option) {
    if (_isAnswered) return;

    final q = _questions[_currentIndex % _questions.length];
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';

    setState(() {
      _selectedOptionId = option.id;
      _isAnswered = true;
      if (option.isCorrect) {
        _score += 10;
        _feedbackMessage = isTamil
            ? 'சரியானது! ${q.timeDisplay} நேரத்தில் சரியாக நினைவுகூர்ந்தீர்கள்!'
            : 'Yes, exactly right! You correctly recalled your habit!';
      } else {
        _feedbackMessage = isTamil
            ? 'யோசித்து பாருங்கள்: மதிய உணவுக்குப்பின் மருந்து சாப்பிட வேண்டும்.'
            : 'Let\'s think together: after lunch it is time for medicine.';
      }
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        if (_currentIndex + 1 >= _questions.length) {
          _onSessionComplete();
        } else {
          setState(() {
            _currentIndex++;
            _selectedOptionId = null;
            _isAnswered = false;
            _feedbackMessage = '';
          });
        }
      }
    });
  }

  void _onSessionComplete() {
    final aiEngine = Provider.of<AiCognitiveEngine>(context, listen: false);
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';

    aiEngine.recordSessionResult(
      gameType: 'routine',
      timeSeconds: 20,
      mistakes: 0,
      accuracyPct: 100,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isTamil ? 'சிறப்பான நினைவாற்றல்!' : 'Excellent Scheduled Recall!',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
        ),
        content: Text(
          isTamil
              ? 'உங்கள் நாளாந்த ஆரோக்கிய பழக்கவழக்கங்களை மிகச் சரியாக நினைவுகூர்ந்தீர்கள்!'
              : 'You correctly recalled your scheduled health routines!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _selectedOptionId = null;
                _isAnswered = false;
                _feedbackMessage = '';
              });
            },
            child: Text(
              isTamil ? 'மீண்டும் விளையாடுக' : 'Play Again',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF23B39B)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = Provider.of<I18nService>(context);
    final isTamil = i18n.currentLang == 'ta';
    final q = _questions[_currentIndex % _questions.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'நினைவில் வை' : 'Remember Now'),
        backgroundColor: const Color(0xFF61C5B0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Bar
            ElderCard(
              backgroundColor: const Color(0xFFF3E8FF),
              border: Border.all(color: const Color(0xFF7E22CE), width: 1.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${isTamil ? "நேரம்" : "Clock"}: ${q.timeDisplay}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8)),
                  ),
                  Text(
                    '${isTamil ? "மதிப்பெண்" : "Score"}: $_score',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Question Card
            ElderCard(
              backgroundColor: const Color(0xFFFAFAFA),
              border: Border.all(color: const Color(0xFF7E22CE), width: 2),
              child: Column(
                children: [
                  Text(
                    isTamil ? q.questionTa : q.questionEn,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _speakQuestion,
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    label: Text(
                      isTamil ? 'கேள்வி கேட்க (Listen)' : 'Hear Question',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E22CE),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (_feedbackMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7E22CE)),
                ),
                child: Text(
                  _feedbackMessage,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8)),
                  textAlign: TextAlign.center,
                ),
              ),

            // Options List
            Expanded(
              child: ListView.builder(
                itemCount: q.options.length,
                itemBuilder: (ctx, idx) {
                  final option = q.options[idx];
                  final isSelected = _selectedOptionId == option.id;

                  Color bgCol = Colors.white;
                  Color borderCol = const Color(0xFFCDE4E2);

                  if (_isAnswered) {
                    if (option.isCorrect) {
                      bgCol = const Color(0xFFDCFCE7);
                      borderCol = const Color(0xFF16A34A);
                    } else if (isSelected) {
                      bgCol = const Color(0xFFFEE2E2);
                      borderCol = const Color(0xFFDC2626);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () => _onOptionTap(option),
                      child: ElderCard(
                        backgroundColor: bgCol,
                        border: Border.all(color: borderCol, width: isSelected ? 3 : 1.5),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: option.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(option.icon, size: 32, color: option.color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                isTamil ? option.labelTa : option.labelEn,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
