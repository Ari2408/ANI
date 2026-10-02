import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_cognitive_engine.dart';
import '../../services/i18n_service.dart';
import '../../widgets/elder_card.dart';

class VisualMemoryGameScreen extends StatefulWidget {
  const VisualMemoryGameScreen({Key? key}) : super(key: key);

  @override
  State<VisualMemoryGameScreen> createState() => _VisualMemoryGameScreenState();
}

class _VisualMemoryGameScreenState extends State<VisualMemoryGameScreen> {
  late List<Map<String, dynamic>> _cards;
  List<int> _flippedIndices = [];
  int _matchedPairs = 0;
  int _totalPairs = 3;
  int _moves = 0;

  final List<Map<String, dynamic>> _catalog = [
    {'id': 'jaapi', 'key': 'assamJaapi', 'name': 'Assam Jaapi', 'icon': Icons.agriculture},
    {'id': 'tanjore', 'key': 'tanjoreArt', 'name': 'Tanjore Art', 'icon': Icons.palette},
    {'id': 'rhino', 'key': 'kazirangaRhino', 'name': 'Kaziranga Rhino', 'icon': Icons.pets},
    {'id': 'rootbridge', 'key': 'rootBridge', 'name': 'Root Bridge', 'icon': Icons.nature},
    {'id': 'dhol', 'key': 'bihuDhol', 'name': 'Bihu Dhol', 'icon': Icons.music_note},
    {'id': 'tea', 'key': 'assamTea', 'name': 'Assam Tea Leaf', 'icon': Icons.eco},
  ];

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    final aiEngine = Provider.of<AiCognitiveEngine>(context, listen: false);
    _totalPairs = aiEngine.currentLevel == 1 ? 3 : (aiEngine.currentLevel == 2 ? 4 : 6);
    _matchedPairs = 0;
    _moves = 0;
    _flippedIndices.clear();

    final selected = _catalog.take(_totalPairs).toList();
    final deck = [...selected, ...selected]..shuffle();

    _cards = deck.map((item) => {
      ...item,
      'isFlipped': false,
      'isMatched': false,
    }).toList();

    setState(() {});
  }

  void _onCardTap(int index) {
    if (_flippedIndices.length >= 2 || _cards[index]['isFlipped'] || _cards[index]['isMatched']) return;

    setState(() {
      _cards[index]['isFlipped'] = true;
      _flippedIndices.add(index);
    });

    if (_flippedIndices.length == 2) {
      _moves++;
      _checkMatch();
    }
  }

  void _checkMatch() {
    final idx1 = _flippedIndices[0];
    final idx2 = _flippedIndices[1];

    if (_cards[idx1]['id'] == _cards[idx2]['id']) {
      setState(() {
        _cards[idx1]['isMatched'] = true;
        _cards[idx2]['isMatched'] = true;
        _matchedPairs++;
        _flippedIndices.clear();
      });

      if (_matchedPairs == _totalPairs) {
        _onGameComplete();
      }
    } else {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() {
            _cards[idx1]['isFlipped'] = false;
            _cards[idx2]['isFlipped'] = false;
            _flippedIndices.clear();
          });
        }
      });
    }
  }

  void _onGameComplete() {
    final aiEngine = Provider.of<AiCognitiveEngine>(context, listen: false);
    final i18n = Provider.of<I18nService>(context, listen: false);
    final accuracy = ((_totalPairs / _moves) * 100).roundToDouble();
    
    aiEngine.recordSessionResult(
      gameType: 'memory',
      timeSeconds: 25,
      mistakes: _moves - _totalPairs,
      accuracyPct: accuracy,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(i18n.translate("memoryChallengeComplete")),
        content: Text(i18n.translate('memoryWinDialogContent').replaceAll('{pairs}', '$_matchedPairs').replaceAll('{moves}', '$_moves').replaceAll('{chi}', '${aiEngine.cognitiveHealthIndex}')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetGame();
            },
            child: Text(i18n.translate('playAgain'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = Provider.of<I18nService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.translate('visualMemory')),
        backgroundColor: const Color(0xFF61C5B0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElderCard(
              border: Border.all(color: const Color(0xFFCDE4E2), width: 1.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: Text(
                      '${i18n.translate("pairs")}: $_matchedPairs / $_totalPairs',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF61C5B0)),
                      softWrap: true, overflow: TextOverflow.visible,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${i18n.translate("moves")}: $_moves',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                      softWrap: true, overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  final isRevealed = card['isFlipped'] || card['isMatched'];

                  return GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: ElderCard(
                      backgroundColor: card['isMatched']
                          ? const Color(0xFFE8F5E9)
                          : (card['isFlipped'] ? const Color(0xFFE0F2FE) : const Color(0xFF61C5B0)),
                      child: Center(
                        child: isRevealed
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(card['icon'] as IconData, size: 36, color: const Color(0xFF1B4D3E)),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      i18n.translate(card['key'] as String),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              )
                            : const Icon(Icons.psychology, size: 36, color: Colors.white),
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
