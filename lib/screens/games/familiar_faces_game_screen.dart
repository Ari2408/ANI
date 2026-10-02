import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/ai_cognitive_engine.dart';
import '../../services/i18n_service.dart';
import '../../widgets/elder_card.dart';
import '../../widgets/elder_button.dart';

class FamiliarFaceCardItem {
  final String id;
  final String nameEn;
  final String nameTa;
  final String relationshipEn;
  final String relationshipTa;
  final IconData icon;
  final Color cardColor;
  final String? imageUrl;

  FamiliarFaceCardItem({
    required this.id,
    required this.nameEn,
    required this.nameTa,
    required this.relationshipEn,
    required this.relationshipTa,
    required this.icon,
    required this.cardColor,
    this.imageUrl,
  });
}

class FamiliarFacesGameScreen extends StatefulWidget {
  const FamiliarFacesGameScreen({Key? key}) : super(key: key);

  @override
  State<FamiliarFacesGameScreen> createState() => _FamiliarFacesGameScreenState();
}

class _FamiliarFacesGameScreenState extends State<FamiliarFacesGameScreen> {
  final FlutterTts _tts = FlutterTts();
  int _currentIndex = 0;
  int _score = 0;
  int _wrongAttempts = 0;
  String? _selectedCardId;
  bool _isAnswered = false;
  String _feedbackMessage = '';

  final List<FamiliarFaceCardItem> _catalog = [
    FamiliarFaceCardItem(
      id: 'son_bikram',
      nameEn: 'Son - Bikram',
      nameTa: 'மகன் - பிக்ரம்',
      relationshipEn: 'Son',
      relationshipTa: 'மகன்',
      icon: Icons.face,
      cardColor: const Color(0xFF0284C7),
    ),
    FamiliarFaceCardItem(
      id: 'daughter_mary',
      nameEn: 'Daughter - Mary',
      nameTa: 'மகள் - மேரி',
      relationshipEn: 'Daughter',
      relationshipTa: 'மகள்',
      icon: Icons.face_3,
      cardColor: const Color(0xFFEC4899),
    ),
    FamiliarFaceCardItem(
      id: 'grandson_rohit',
      nameEn: 'Grandson - Rohit',
      nameTa: 'பேரன் - ரோஹித்',
      relationshipEn: 'Grandson',
      relationshipTa: 'பேரன்',
      icon: Icons.child_care,
      cardColor: const Color(0xFF8B5CF6),
    ),
    FamiliarFaceCardItem(
      id: 'obj_lalsaah',
      nameEn: 'Local Red Tea',
      nameTa: 'பாரம்பரிய தேநீர்',
      relationshipEn: 'Morning Tea',
      relationshipTa: 'காலை தேநீர்',
      icon: Icons.coffee,
      cardColor: const Color(0xFFD97706),
    ),
    FamiliarFaceCardItem(
      id: 'obj_bamboo_basket',
      nameEn: 'Traditional Bamboo Basket',
      nameTa: 'மூங்கில் கூடை',
      relationshipEn: 'Craft Basket',
      relationshipTa: 'கைவினைப் பொருள்',
      icon: Icons.shopping_bag,
      cardColor: const Color(0xFF059669),
    ),
    FamiliarFaceCardItem(
      id: 'obj_tamul_paan',
      nameEn: 'Betel Nut & Leaf',
      nameTa: 'வெற்றிலை பாக்கு',
      relationshipEn: 'Household Item',
      relationshipTa: 'வீட்டுப் பொருள்',
      icon: Icons.eco,
      cardColor: const Color(0xFF16A34A),
    ),
    FamiliarFaceCardItem(
      id: 'obj_brass_kettle',
      nameEn: 'Traditional Tea Kettle',
      nameTa: 'பித்தளை தேநீர் பாத்திரம்',
      relationshipEn: 'Kitchen Item',
      relationshipTa: 'சமையலறை பொருள்',
      icon: Icons.local_fire_department,
      cardColor: const Color(0xFFE11D48),
    ),
  ];

  late List<FamiliarFaceCardItem> _sessionTargets;
  late List<FamiliarFaceCardItem> _currentOptions;

  @override
  void initState() {
    super.initState();
    _sessionTargets = List.from(_catalog)..shuffle();
    _loadQuestion();
  }

  void _loadQuestion() {
    if (_currentIndex >= _sessionTargets.length) {
      _onSessionComplete();
      return;
    }
    final target = _sessionTargets[_currentIndex];
    final distractorList = _catalog.where((item) => item.id != target.id).toList()..shuffle();
    _currentOptions = [target, distractorList[0], distractorList[1]]..shuffle();

    setState(() {
      _selectedCardId = null;
      _isAnswered = false;
      _feedbackMessage = '';
    });
  }

  void _speakName() async {
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';
    final target = _sessionTargets[_currentIndex % _sessionTargets.length];
    final name = isTamil ? target.nameTa : target.nameEn;
    await _tts.setLanguage(isTamil ? 'ta-IN' : 'en-US');
    await _tts.speak(name);
  }

  void _onOptionTap(FamiliarFaceCardItem option) {
    if (_isAnswered) return;

    final target = _sessionTargets[_currentIndex];
    final isCorrect = option.id == target.id;
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';

    setState(() {
      _selectedCardId = option.id;
      _isAnswered = true;
      if (isCorrect) {
        _score += 10;
        _feedbackMessage = isTamil
            ? 'அற்புதம்! இது ${option.nameTa} ஆகும்!'
            : 'Splendid! That is ${option.nameEn}!';
      } else {
        _wrongAttempts++;
        _feedbackMessage = isTamil
            ? 'இது ${option.nameTa} ஆகும். மீண்டும் கவனியுங்கள்!'
            : 'That is ${option.nameEn}. Look closely for ${target.nameEn}!';
      }
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _loadQuestion();
        });
      }
    });
  }

  void _onSessionComplete() {
    final aiEngine = Provider.of<AiCognitiveEngine>(context, listen: false);
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';

    aiEngine.recordSessionResult(
      gameType: 'memory',
      timeSeconds: 30,
      mistakes: _wrongAttempts,
      accuracyPct: (_score / (_catalog.length * 10)) * 100,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isTamil ? 'அற்புதமான நினைவாற்றல்!' : 'Wonderful Recognition!',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
        ),
        content: Text(
          isTamil
              ? 'அனைத்து முகங்கள் மற்றும் பொருட்களை வெற்றிகரமாக கண்டறிந்தீர்கள்!'
              : 'You successfully matched all the names with their photo cards!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _wrongAttempts = 0;
                _sessionTargets.shuffle();
                _loadQuestion();
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
    final target = _sessionTargets[_currentIndex % _sessionTargets.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'சினாக்கி முகங்கள்' : 'Familiar Faces'),
        backgroundColor: const Color(0xFF61C5B0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Status Bar
            ElderCard(
              backgroundColor: const Color(0xFFFFFBEB),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${isTamil ? "வினா" : "Question"} ${_currentIndex + 1} / ${_sessionTargets.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                  ),
                  Text(
                    '${isTamil ? "மதிப்பெண்" : "Score"}: $_score',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Prompt Card
            ElderCard(
              backgroundColor: const Color(0xFFF0FDF4),
              border: Border.all(color: const Color(0xFF23B39B), width: 2),
              child: Column(
                children: [
                  Text(
                    isTamil ? 'இந்த பெயரை குறிக்கும் படத்தை தேர்ந்தெடுக்கவும்:' : 'Tap the picture that matches this name:',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTamil ? target.nameTa : target.nameEn,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTamil ? target.relationshipTa : target.relationshipEn,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF047857)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _speakName,
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    label: Text(
                      isTamil ? 'ஒலி கேட்க (Listen)' : 'Listen Name',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
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
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0284C7)),
                ),
                child: Text(
                  _feedbackMessage,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  textAlign: TextAlign.center,
                ),
              ),

            // Choice Cards Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _currentOptions.length,
                itemBuilder: (ctx, idx) {
                  final option = _currentOptions[idx];
                  final isSelected = _selectedCardId == option.id;
                  final isTarget = option.id == target.id;

                  Color borderCol = const Color(0xFFCDE4E2);
                  Color bgCol = Colors.white;

                  if (_isAnswered) {
                    if (isTarget) {
                      bgCol = const Color(0xFFDCFCE7);
                      borderCol = const Color(0xFF16A34A);
                    } else if (isSelected) {
                      bgCol = const Color(0xFFFEE2E2);
                      borderCol = const Color(0xFFDC2626);
                    }
                  }

                  return GestureDetector(
                    onTap: () => _onOptionTap(option),
                    child: ElderCard(
                      backgroundColor: bgCol,
                      border: Border.all(color: borderCol, width: isSelected ? 3 : 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(option.icon, size: 40, color: option.cardColor),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isTamil ? option.nameTa : option.nameEn,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                            ),
                          ),
                        ],
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
