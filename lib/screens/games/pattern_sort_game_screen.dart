import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/i18n_service.dart';
import '../../widgets/elder_card.dart';

class PatternSortGameScreen extends StatefulWidget {
  const PatternSortGameScreen({Key? key}) : super(key: key);

  @override
  State<PatternSortGameScreen> createState() => _PatternSortGameScreenState();
}

class _PatternSortGameScreenState extends State<PatternSortGameScreen> {
  final List<Map<String, dynamic>> _patterns = [
    {'id': 'p1', 'key': 'pattern1Name', 'icon': Icons.diamond},
    {'id': 'p2', 'key': 'pattern2Name', 'icon': Icons.local_florist},
    {'id': 'p3', 'key': 'pattern3Name', 'icon': Icons.change_history},
    {'id': 'p4', 'key': 'pattern4Name', 'icon': Icons.star},
  ];

  late Map<String, dynamic> _targetPattern;

  @override
  void initState() {
    super.initState();
    _nextTarget();
  }

  void _nextTarget() {
    setState(() {
      _targetPattern = (_patterns..shuffle()).first;
    });
  }

  void _onSelect(Map<String, dynamic> pattern) {
    final i18n = Provider.of<I18nService>(context, listen: false);
    if (pattern['id'] == _targetPattern['id']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.translate("perfectPatternMatch"))),
      );
      _nextTarget();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.translate('notAMatch'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = Provider.of<I18nService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.translate('loomPatternRecog')),
        backgroundColor: const Color(0xFF61C5B0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElderCard(
              backgroundColor: const Color(0xFFFDF0E6),
              border: Border.all(color: const Color(0xFF23B39B), width: 1.5),
              child: Column(
                children: [
                  Text(i18n.translate("matchTargetMotif"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF23B39B))),
                  const SizedBox(height: 12),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(_targetPattern['icon'] as IconData, size: 48, color: const Color(0xFF1B4D3E)),
                  ),
                  const SizedBox(height: 8),
                  Text(i18n.translate(_targetPattern['key'] as String? ?? 'patternSortTitle'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _patterns.length,
                itemBuilder: (ctx, idx) {
                  final p = _patterns[idx];
                  return GestureDetector(
                    onTap: () => _onSelect(p),
                    child: ElderCard(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(p['icon'] as IconData, size: 42, color: const Color(0xFF1B4D3E)),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(i18n.translate(p['key'] as String? ?? 'patternSortTitle'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
