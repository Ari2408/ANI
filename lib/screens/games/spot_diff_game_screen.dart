import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../services/ai_cognitive_engine.dart';
import '../../services/i18n_service.dart';
import '../../widgets/elder_card.dart';

class SpotDiffSpot {
  final String id;
  final String labelEn;
  final String labelTa;
  final Offset position; // Normalized (0.0 to 1.0)
  final String hintEn;
  final String hintTa;

  SpotDiffSpot({
    required this.id,
    required this.labelEn,
    required this.labelTa,
    required this.position,
    required this.hintEn,
    required this.hintTa,
  });
}

class SpotDiffScene {
  final String id;
  final String titleEn;
  final String titleTa;
  final String descEn;
  final String descTa;
  final IconData icon;
  final List<SpotDiffSpot> spots;

  SpotDiffScene({
    required this.id,
    required this.titleEn,
    required this.titleTa,
    required this.descEn,
    required this.descTa,
    required this.icon,
    required this.spots,
  });
}

class SpotDiffGameScreen extends StatefulWidget {
  const SpotDiffGameScreen({Key? key}) : super(key: key);

  @override
  State<SpotDiffGameScreen> createState() => _SpotDiffGameScreenState();
}

class _SpotDiffGameScreenState extends State<SpotDiffGameScreen> {
  final FlutterTts _tts = FlutterTts();
  int _currentSceneIndex = 0;
  final Set<String> _foundSpotIds = {};
  String? _activeHintId;
  String _statusMessage = '';

  final List<SpotDiffScene> _scenes = [
    SpotDiffScene(
      id: 'tea_courtyard',
      titleEn: 'Assam Tea Courtyard',
      titleTa: 'தேயிலைத் தோட்டம்',
      descEn: 'Compare Picture A and B. Tap where you notice a difference!',
      descTa: 'படம் அ மற்றும் ஆ-வை ஒப்பிட்டு வித்தியாசங்களை கண்டறியவும்!',
      icon: Icons.wb_sunny,
      spots: [
        SpotDiffSpot(
          id: 'diff_bird',
          labelEn: 'Singing Bird',
          labelTa: 'பாடும் பறவை',
          position: const Offset(0.74, 0.24),
          hintEn: 'Look up in the tree at the singing bird!',
          hintTa: 'மரத்தில் உள்ள பாடும் பறவையை கவனியுங்கள்!',
        ),
        SpotDiffSpot(
          id: 'diff_steam',
          labelEn: 'Kettle Steam',
          labelTa: 'தேநீர் நீராவி',
          position: const Offset(0.27, 0.63),
          hintEn: 'Check the tea kettle on the table for rising steam.',
          hintTa: 'மேஜையில் உள்ள தேநீர் பாத்திரத்தின் நீராவியை பாருங்கள்.',
        ),
        SpotDiffSpot(
          id: 'diff_flower',
          labelEn: 'Porch Flower Bloom',
          labelTa: 'பூந்தொட்டி மலர்',
          position: const Offset(0.50, 0.82),
          hintEn: 'Notice the potted flower sitting near the front porch.',
          hintTa: 'முன்பக்க பூந்தொட்டியில் உள்ள மலரை பாருங்கள்.',
        ),
      ],
    ),
    SpotDiffScene(
      id: 'village_kitchen',
      titleEn: 'Village Kitchen & Tea Time',
      titleTa: 'கிராமத்து சமையலறை',
      descEn: 'Compare the hearth, hanging goods, chair, and cat.',
      descTa: 'அடுப்பு, தொங்கும் பொருட்கள் மற்றும் பூனையை கவனிக்கவும்.',
      icon: Icons.local_fire_department,
      spots: [
        SpotDiffSpot(
          id: 'diff_flame',
          labelEn: 'Stove Flame Color',
          labelTa: 'அடுப்பு ஜுவாலை',
          position: const Offset(0.24, 0.72),
          hintEn: 'Check the cooking fire under the tea pot.',
          hintTa: 'அடுப்பின் நெருப்பு ஜுவாலையை கவனியுங்கள்.',
        ),
        SpotDiffSpot(
          id: 'diff_gamusa',
          labelEn: 'Woven Cloth Pattern',
          labelTa: 'நெய்த துணி வடிவம்',
          position: const Offset(0.82, 0.66),
          hintEn: 'Inspect the handwoven cloth draped over the chair.',
          hintTa: 'நாற்காலியில் உள்ள நெய்த துணியை கவனியுங்கள்.',
        ),
        SpotDiffSpot(
          id: 'diff_cat',
          labelEn: 'Sleeping Cat Color',
          labelTa: 'தூங்கும் பூனை',
          position: const Offset(0.60, 0.84),
          hintEn: 'Notice the gentle sleeping cat resting on the rug.',
          hintTa: 'தரையில் தூங்கும் பூனையை பாருங்கள்.',
        ),
      ],
    ),
    SpotDiffScene(
      id: 'river_boat',
      titleEn: 'Brahmaputra River Boat',
      titleTa: 'ஆற்றுப் படகு',
      descEn: 'Examine the sailboat, jumping fish, and hilltop flag.',
      descTa: 'படகு, துள்ளும் மீன் மற்றும் மலைக் கொடியை கவனியுங்கள்.',
      icon: Icons.directions_boat,
      spots: [
        SpotDiffSpot(
          id: 'diff_sail',
          labelEn: 'Boat Sail Pattern',
          labelTa: 'படகுப் பாய்மரம்',
          position: const Offset(0.48, 0.44),
          hintEn: 'Look at the big cloth sail on the wooden boat.',
          hintTa: 'படகில் உள்ள பாய்மரத் துணியைப் பாருங்கள்.',
        ),
        SpotDiffSpot(
          id: 'diff_fish',
          labelEn: 'Jumping River Fish',
          labelTa: 'துள்ளும் மீன்',
          position: const Offset(0.78, 0.76),
          hintEn: 'Check the flowing water for a splashing fish.',
          hintTa: 'ஆற்று நீரில் துள்ளும் மீனை கவனியுங்கள்.',
        ),
        SpotDiffSpot(
          id: 'diff_flag',
          labelEn: 'Hilltop Flag',
          labelTa: 'மலை உச்சிக் கொடி',
          position: const Offset(0.86, 0.24),
          hintEn: 'Notice the distant hill peak on the upper right.',
          hintTa: 'வலது மேல் மூலையில் உள்ள மலைக் கொடியைப் பாருங்கள்.',
        ),
      ],
    ),
  ];

  void _onPictureTap(Offset localPosition, Size imageSize) {
    final scene = _scenes[_currentSceneIndex];
    final dxRatio = localPosition.dx / imageSize.width;
    final dyRatio = localPosition.dy / imageSize.height;

    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';

    SpotDiffSpot? hitSpot;
    for (final spot in scene.spots) {
      if (_foundSpotIds.contains(spot.id)) continue;
      final dist = (Offset(dxRatio, dyRatio) - spot.position).distance;
      if (dist <= 0.18) {
        hitSpot = spot;
        break;
      }
    }

    if (hitSpot != null) {
      setState(() {
        _foundSpotIds.add(hitSpot!.id);
        _activeHintId = null;
        _statusMessage = isTamil
            ? 'கண்டறியப்பட்டது: ${hitSpot.labelTa}!'
            : 'Found: ${hitSpot.labelEn}!';
      });

      if (_foundSpotIds.length >= scene.spots.length) {
        _onSceneComplete();
      }
    } else {
      setState(() {
        _statusMessage = isTamil
            ? 'தொடர்ந்து கவனியுங்கள்! இரு படங்களையும் ஒப்பிடுங்கள்.'
            : 'Keep looking! Compare Picture A and Picture B.';
      });
    }
  }

  void _showHint() async {
    final scene = _scenes[_currentSceneIndex];
    final remaining = scene.spots.where((s) => !_foundSpotIds.contains(s.id)).toList();
    if (remaining.isEmpty) return;

    final targetHint = remaining.first;
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';
    final hintText = isTamil ? targetHint.hintTa : targetHint.hintEn;

    setState(() {
      _activeHintId = targetHint.id;
      _statusMessage = hintText;
    });

    await _tts.setLanguage(isTamil ? 'ta-IN' : 'en-US');
    await _tts.speak(hintText);
  }

  void _onSceneComplete() {
    final aiEngine = Provider.of<AiCognitiveEngine>(context, listen: false);
    final i18n = Provider.of<I18nService>(context, listen: false);
    final isTamil = i18n.currentLang == 'ta';

    aiEngine.recordSessionResult(
      gameType: 'pattern',
      timeSeconds: 25,
      mistakes: 0,
      accuracyPct: 100,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isTamil ? 'கூர்மையான கவனம்!' : 'Spot On! All Differences Found!',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
        ),
        content: Text(
          isTamil
              ? 'இந்த காட்சிப்படத்தில் உள்ள அனைத்து வித்தியாசங்களையும் வெற்றிகரமாக கண்டறிந்தீர்கள்!'
              : 'You discovered all differences between Picture A and Picture B!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _foundSpotIds.clear();
                _activeHintId = null;
                _currentSceneIndex = (_currentSceneIndex + 1) % _scenes.length;
                _statusMessage = '';
              });
            },
            child: Text(
              isTamil ? 'அடுத்த காட்சிக்கு செல்க' : 'Next Scene',
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
    final scene = _scenes[_currentSceneIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'வித்தியாசம் பிடி!' : 'Spot It! Differences'),
        backgroundColor: const Color(0xFF61C5B0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Bar with Scene Tabs & Hint Button
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _scenes.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final sc = entry.value;
                        final isSelected = idx == _currentSceneIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            avatar: Icon(sc.icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF1B4D3E)),
                            label: Text(isTamil ? sc.titleTa : sc.titleEn),
                            selected: isSelected,
                            selectedColor: const Color(0xFF1B4D3E),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF1B4D3E),
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _currentSceneIndex = idx;
                                _foundSpotIds.clear();
                                _activeHintId = null;
                                _statusMessage = '';
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showHint,
                  icon: const Icon(Icons.help_outline, color: Colors.white, size: 18),
                  label: Text(isTamil ? 'உதவி' : 'Hint', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Banner
            ElderCard(
              backgroundColor: const Color(0xFFF0FDF4),
              border: Border.all(color: const Color(0xFF23B39B), width: 1.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${isTamil ? "கண்டறியப்பட்டவை" : "Found"}: ${_foundSpotIds.length} / ${scene.spots.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                  ),
                  Row(
                    children: scene.spots.map((s) {
                      final isFound = _foundSpotIds.contains(s.id);
                      return Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: isFound ? const Color(0xFF16A34A) : Colors.grey.shade300,
                          child: Icon(
                            isFound ? Icons.check : Icons.circle,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (_statusMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  textAlign: TextAlign.center,
                ),
              ),

            // Side-by-Side Canvas Panels
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildCanvasPanel(
                      context,
                      title: isTamil ? 'படம் அ (Picture A)' : 'Picture A',
                      isModified: false,
                      scene: scene,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCanvasPanel(
                      context,
                      title: isTamil ? 'படம் ஆ (Picture B)' : 'Picture B',
                      isModified: true,
                      scene: scene,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasPanel(
    BuildContext context, {
    required String title,
    required bool isModified,
    required SpotDiffScene scene,
  }) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final panelSize = Size(constraints.maxWidth, constraints.maxHeight - 32);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: GestureDetector(
                onTapUp: (details) => _onPictureTap(details.localPosition, panelSize),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF61C5B0), width: 2),
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: panelSize,
                        painter: SpotDiffPainter(
                          sceneId: scene.id,
                          isModified: isModified,
                          foundSpots: _foundSpotIds,
                        ),
                      ),
                      ...scene.spots.map((spot) {
                        final isFound = _foundSpotIds.contains(spot.id);
                        final isHinted = _activeHintId == spot.id;
                        if (!isFound && !isHinted) return const SizedBox.shrink();

                        return Positioned(
                          left: spot.position.dx * panelSize.width - 24,
                          top: spot.position.dy * panelSize.height - 24,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFound
                                  ? const Color(0xFF16A34A).withOpacity(0.3)
                                  : Colors.amber.withOpacity(0.4),
                              border: Border.all(
                                color: isFound ? const Color(0xFF16A34A) : Colors.amber,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              isFound ? Icons.check_circle : Icons.lightbulb,
                              color: isFound ? const Color(0xFF16A34A) : Colors.amber.shade900,
                              size: 28,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SpotDiffPainter extends CustomPainter {
  final String sceneId;
  final bool isModified;
  final Set<String> foundSpots;

  SpotDiffPainter({
    required this.sceneId,
    required this.isModified,
    required this.foundSpots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background Sky & Land
    paint.color = const Color(0xFFE0F2FE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.color = const Color(0xFFBBF7D0);
    final pathLand = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.3, size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pathLand, paint);

    if (sceneId == 'tea_courtyard') {
      // Sun or Cloud Difference
      if (!isModified) {
        paint.color = const Color(0xFFF59E0B);
        canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 18, paint);
      } else {
        paint.color = Colors.white;
        canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 16, paint);
        canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.18), 12, paint);
      }

      // Bird in Tree
      paint.color = isModified ? const Color(0xFF2563EB) : const Color(0xFFD97706);
      canvas.drawCircle(Offset(size.width * 0.74, size.height * 0.24), 10, paint);

      // Porch Flower
      paint.color = isModified ? const Color(0xFFEC4899) : const Color(0xFFF97316);
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.82), 12, paint);
    } else if (sceneId == 'village_kitchen') {
      // Hearth Flame
      paint.color = isModified ? const Color(0xFF3B82F6) : const Color(0xFFEA580C);
      canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.72), 16, paint);

      // Sleeping Cat
      paint.color = isModified ? const Color(0xFF94A3B8) : const Color(0xFFF97316);
      canvas.drawCircle(Offset(size.width * 0.60, size.height * 0.84), 14, paint);
    } else {
      // River Water
      paint.color = const Color(0xFF38BDF8);
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35), paint);

      // Sail Pattern
      paint.color = isModified ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.42, size.height * 0.36, 30, 40), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SpotDiffPainter oldDelegate) =>
      oldDelegate.sceneId != sceneId ||
      oldDelegate.isModified != isModified ||
      oldDelegate.foundSpots.length != foundSpots.length;
}
