import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/i18n_service.dart';
import '../../widgets/elder_card.dart';

class WordAssociationGameScreen extends StatefulWidget {
  const WordAssociationGameScreen({Key? key}) : super(key: key);

  @override
  State<WordAssociationGameScreen> createState() => _WordAssociationGameScreenState();
}

class _WordAssociationGameScreenState extends State<WordAssociationGameScreen> {
  final List<Map<String, String>> _pairs = [
    {'item1': 'Cup', 'item2': 'Teapot', 'category': 'Kitchen'},
    {'item1': 'Glasses', 'item2': 'Book', 'category': 'Reading'},
    {'item1': 'Rain', 'item2': 'Umbrella', 'category': 'Weather'},
    {'item1': 'Flower', 'item2': 'Honey Bee', 'category': 'Nature'},
    {'item1': 'Key', 'item2': 'Lock', 'category': 'Home'},
    {'item1': 'Shoes', 'item2': 'Socks', 'category': 'Clothing'},
  ];

  int _currentIndex = 0;
  String? _selectedOption;
  int _score = 0;
  List<String> _shuffledOptions = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentQuestion();
  }

  void _loadCurrentQuestion() {
    final currentPair = _pairs[_currentIndex % _pairs.length];
    final target = currentPair['item2']!;

    final wrongOptions = _pairs
        .where((p) => p['item2'] != target)
        .map((p) => p['item2']!)
        .toList()
      ..shuffle();

    _shuffledOptions = [target, wrongOptions[0], wrongOptions[1]]..shuffle();
    _selectedOption = null;
  }

  void _checkAnswer(String selected) {
    setState(() {
      _selectedOption = selected;
    });

    final currentPair = _pairs[_currentIndex % _pairs.length];
    final isCorrect = selected == currentPair['item2'];
    final i18n = Provider.of<I18nService>(context, listen: false);

    if (isCorrect) {
      _score += 10;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(i18n.translate("greatAssociation") ?? 'Great Association! +10 Points'),
          backgroundColor: const Color(0xFF23B39B),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(i18n.translate("tryNextPair") ?? 'Not quite, keep practicing!'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _loadCurrentQuestion();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = Provider.of<I18nService>(context);
    final currentPair = _pairs[_currentIndex % _pairs.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.translate('wordAssocTitle') ?? 'Word & Object Association'),
        backgroundColor: const Color(0xFF61C5B0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Score Banner
            ElderCard(
              backgroundColor: const Color(0xFFE8F5E9),
              border: Border.all(color: const Color(0xFF23B39B), width: 1.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: $_score',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                  ),
                  Text(
                    'Pair ${_currentIndex + 1}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF23B39B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Prompt Card
            ElderCard(
              backgroundColor: const Color(0xFFFDF0E6),
              border: Border.all(color: const Color(0xFFE59866), width: 1.5),
              child: Column(
                children: [
                  const Text(
                    'What goes best with:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF5D4037)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE59866).withOpacity(0.5)),
                    ),
                    child: Text(
                      currentPair['item1']!,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Category: ${currentPair['category']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Options List
            Expanded(
              child: ListView.builder(
                itemCount: _shuffledOptions.length,
                itemBuilder: (context, index) {
                  final option = _shuffledOptions[index];
                  final isSelected = _selectedOption == option;
                  final isTarget = option == currentPair['item2'];

                  Color cardBg = Colors.white;
                  if (_selectedOption != null) {
                    if (isTarget) {
                      cardBg = const Color(0xFFC8E6C9);
                    } else if (isSelected) {
                      cardBg = const Color(0xFFFFCDD2);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: _selectedOption == null ? () => _checkAnswer(option) : null,
                      child: ElderCard(
                        backgroundColor: cardBg,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF23B39B) : Colors.grey.shade300,
                          width: 2,
                        ),
                        child: Center(
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                          ),
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
