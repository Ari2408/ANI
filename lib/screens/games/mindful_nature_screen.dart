import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../services/i18n_service.dart';
import '../../widgets/elder_card.dart';

class PhaseConfig {
  final String nameKey;
  final String defaultName;
  final IconData iconData;
  final String voiceInstruction;
  final int durationSeconds;
  final double targetScale; // 1.0 = base, 1.45 = expanded
  final Color primaryColor;

  PhaseConfig({
    required this.nameKey,
    required this.defaultName,
    required this.iconData,
    required this.voiceInstruction,
    required this.durationSeconds,
    required this.targetScale,
    required this.primaryColor,
  });
}

class RegulationConfig {
  final String title;
  final String subtitle;
  final String badge;
  final List<PhaseConfig> phases;

  RegulationConfig({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.phases,
  });
}

class MindfulNatureScreen extends StatefulWidget {
  const MindfulNatureScreen({Key? key}) : super(key: key);

  @override
  State<MindfulNatureScreen> createState() => _MindfulNatureScreenState();
}

class _MindfulNatureScreenState extends State<MindfulNatureScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  
  final FlutterTts _tts = FlutterTts();
  Timer? _timer;
  
  bool _isActive = false;
  bool _isVoiceEnabled = true;
  int _selectedRegulationIndex = 0;
  int _currentPhaseIndex = 0;
  int _phaseSecondsRemaining = 4;
  int _completedCycles = 0;
  String _sound = 'flute';

  late List<RegulationConfig> _regulations;

  @override
  void initState() {
    super.initState();
    
    _initTTS();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _setupRegulations();
    _resetPhaseState();
  }

  void _initTTS() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.42); // Slow, calm rate for breathing guidance
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
    } catch (e) {
      debugPrint('TTS setup error in MindfulNatureScreen: $e');
    }
  }

  void _setupRegulations() {
    _regulations = [
      // Regulation 1: Box Breathing (4-4-4-4)
      RegulationConfig(
        title: 'Box Breathing (4-4-4-4)',
        subtitle: 'Equal 4s phases for deep focus, stress relief & nervous system calm.',
        badge: 'Focus & Calm',
        phases: [
          PhaseConfig(
            nameKey: 'breatheIn',
            defaultName: 'BREATHE IN',
            iconData: Icons.air,
            voiceInstruction: 'Breathe in slowly through your nose...',
            durationSeconds: 4,
            targetScale: 1.45,
            primaryColor: const Color(0xFF26B0A8),
          ),
          PhaseConfig(
            nameKey: 'holdBreath',
            defaultName: 'HOLD BREATH',
            iconData: Icons.pause_circle_outline,
            voiceInstruction: 'Hold your breath calmly...',
            durationSeconds: 4,
            targetScale: 1.45,
            primaryColor: const Color(0xFF3F51B5),
          ),
          PhaseConfig(
            nameKey: 'breatheOut',
            defaultName: 'BREATHE OUT',
            iconData: Icons.air,
            voiceInstruction: 'Breathe out gently through your mouth...',
            durationSeconds: 4,
            targetScale: 1.0,
            primaryColor: const Color(0xFF009688),
          ),
          PhaseConfig(
            nameKey: 'pauseRelax',
            defaultName: 'PAUSE & RELAX',
            iconData: Icons.spa,
            voiceInstruction: 'Pause and relax...',
            durationSeconds: 4,
            targetScale: 1.0,
            primaryColor: const Color(0xFF673AB7),
          ),
        ],
      ),

      // Regulation 2: 4-7-8 Relaxing Breath
      RegulationConfig(
        title: '4-7-8 Relaxing Exercise',
        subtitle: '4s Inhale, 7s Hold, 8s Exhale for deep relaxation & anxiety reduction.',
        badge: 'Deep Sleep & Relax',
        phases: [
          PhaseConfig(
            nameKey: 'breatheIn',
            defaultName: 'BREATHE IN',
            iconData: Icons.air,
            voiceInstruction: 'Breathe in deeply through your nose...',
            durationSeconds: 4,
            targetScale: 1.45,
            primaryColor: const Color(0xFF00A896),
          ),
          PhaseConfig(
            nameKey: 'holdBreath',
            defaultName: 'HOLD BREATH',
            iconData: Icons.pause_circle_outline,
            voiceInstruction: 'Hold your breath quietly...',
            durationSeconds: 7,
            targetScale: 1.45,
            primaryColor: const Color(0xFF4A148C),
          ),
          PhaseConfig(
            nameKey: 'breatheOut',
            defaultName: 'BREATHE OUT',
            iconData: Icons.air,
            voiceInstruction: 'Exhale completely with a woosh sound...',
            durationSeconds: 8,
            targetScale: 1.0,
            primaryColor: const Color(0xFF0288D1),
          ),
        ],
      ),

      // Regulation 3: Equal Pace (4-4)
      RegulationConfig(
        title: 'Equal Pace (4-4)',
        subtitle: 'Simple rhythm exercise to equalize heartbeat & mental focus.',
        badge: 'Daily Balance',
        phases: [
          PhaseConfig(
            nameKey: 'breatheIn',
            defaultName: 'BREATHE IN',
            iconData: Icons.air,
            voiceInstruction: 'Breathe in slowly...',
            durationSeconds: 4,
            targetScale: 1.45,
            primaryColor: const Color(0xFF26A69A),
          ),
          PhaseConfig(
            nameKey: 'breatheOut',
            defaultName: 'BREATHE OUT',
            iconData: Icons.air,
            voiceInstruction: 'Breathe out slowly...',
            durationSeconds: 4,
            targetScale: 1.0,
            primaryColor: const Color(0xFF42A5F5),
          ),
        ],
      ),
    ];
  }

  PhaseConfig get _currentPhase {
    final reg = _regulations[_selectedRegulationIndex];
    return reg.phases[_currentPhaseIndex % reg.phases.length];
  }

  void _resetPhaseState() {
    _timer?.cancel();
    _isActive = false;
    _currentPhaseIndex = 0;
    _completedCycles = 0;
    final phase = _currentPhase;
    _phaseSecondsRemaining = phase.durationSeconds;
    _animController.duration = Duration(seconds: phase.durationSeconds);
    _animController.value = 0.0;
  }

  void _toggleExercise() {
    if (_isActive) {
      _pauseExercise();
    } else {
      _startExercise();
    }
  }

  void _startExercise() {
    setState(() {
      _isActive = true;
    });
    _triggerPhaseVoice();
    _startAnimationForCurrentPhase();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_phaseSecondsRemaining > 1) {
          _phaseSecondsRemaining--;
        } else {
          _advanceToNextPhase();
        }
      });
    });
  }

  void _pauseExercise() {
    _timer?.cancel();
    _animController.stop();
    _stopVoice();
    setState(() {
      _isActive = false;
    });
  }

  void _advanceToNextPhase() {
    final reg = _regulations[_selectedRegulationIndex];
    int nextIndex = (_currentPhaseIndex + 1) % reg.phases.length;
    
    if (nextIndex == 0) {
      _completedCycles++;
    }

    _currentPhaseIndex = nextIndex;
    final nextPhase = _currentPhase;
    _phaseSecondsRemaining = nextPhase.durationSeconds;

    _triggerPhaseVoice();
    _startAnimationForCurrentPhase();
  }

  void _startAnimationForCurrentPhase() {
    final phase = _currentPhase;
    _animController.duration = Duration(seconds: phase.durationSeconds);

    if (phase.targetScale > 1.1) {
      // Inhale phase: expand
      _animController.forward(from: _animController.value);
    } else if (phase.targetScale == 1.0 && _scaleAnim.value > 1.1) {
      // Exhale phase: shrink
      _animController.reverse(from: _animController.value);
    }
  }

  void _triggerPhaseVoice() async {
    if (!_isVoiceEnabled) return;
    try {
      await _tts.stop();
      await _tts.speak(_currentPhase.voiceInstruction);
    } catch (e) {
      debugPrint('Error speaking breathing prompt: $e');
    }
  }

  void _stopVoice() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    _stopVoice();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = Provider.of<I18nService>(context);
    final reg = _regulations[_selectedRegulationIndex];
    final phase = _currentPhase;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F6),
      appBar: AppBar(
        title: Text(i18n.translate('mindfulSoundscape')),
        backgroundColor: const Color(0xFF61C5B0),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Image Card
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/living_root_bridge.jpg',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 160,
                  color: const Color(0xFF61C5B0),
                  alignment: Alignment.center,
                  child: Text(
                    i18n.translate("cherrapunjiStream"),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Regulation Mode Selector Card
            ElderCard(
              backgroundColor: Colors.white,
              border: Border.all(color: const Color(0xFF23B39B).withOpacity(0.3), width: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Regulation Exercise',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF23B39B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          reg.badge,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_regulations.length, (idx) {
                        final isSelected = _selectedRegulationIndex == idx;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              _regulations[idx].title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF1B2824),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF23B39B),
                            backgroundColor: const Color(0xFFE0F2F1),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedRegulationIndex = idx;
                                  _resetPhaseState();
                                });
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reg.subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Main Interactive Animated Breathing Circle Card
            ElderCard(
              backgroundColor: Colors.white,
              border: Border.all(color: phase.primaryColor.withOpacity(0.5), width: 2),
              child: Column(
                children: [
                  // Voice Toggle & Cycle Counter Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isVoiceEnabled = !_isVoiceEnabled;
                          });
                          if (_isVoiceEnabled && _isActive) {
                            _triggerPhaseVoice();
                          } else {
                            _stopVoice();
                          }
                        },
                        icon: Icon(
                          _isVoiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _isVoiceEnabled ? 'Voice Guidance ON' : 'Voice Guidance Muted',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isVoiceEnabled ? const Color(0xFF23B39B) : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Text(
                          'Cycles: $_completedCycles',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF795548)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Animated Pulsing Breathing Ring
                  AnimatedBuilder(
                    animation: _scaleAnim,
                    builder: (ctx, child) {
                      return Transform.scale(
                        scale: _isActive ? _scaleAnim.value : 1.0,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                phase.primaryColor,
                                phase.primaryColor.withOpacity(0.6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: phase.primaryColor.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(phase.iconData, size: 34, color: Colors.white),
                              const SizedBox(height: 4),
                              Text(
                                phase.defaultName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_phaseSecondsRemaining}s',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Voice Prompt Instruction Text Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: phase.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: phase.primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Spoken Voice Instruction:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: phase.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"${phase.voiceInstruction}"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: phase.primaryColor.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Controls Row: Start / Pause & Reset
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleExercise,
                          icon: Icon(_isActive ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 24),
                          label: Text(
                            _isActive ? 'PAUSE EXERCISE' : 'START BREATHING',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isActive ? Colors.orange.shade700 : const Color(0xFF23B39B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _resetPhaseState();
                          });
                          _stopVoice();
                        },
                        icon: const Icon(Icons.refresh_rounded, color: Colors.grey, size: 28),
                        tooltip: 'Reset Exercise',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Soundscape Audio Selector Card
            Row(
              children: [
                Expanded(child: _soundBtn('flute', i18n.translate("bambooFlute"))),
                const SizedBox(width: 6),
                Expanded(child: _soundBtn('rain', i18n.translate("rainInSohra"))),
                const SizedBox(width: 6),
                Expanded(child: _soundBtn('river', i18n.translate("brahmaputra"))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _soundBtn(String type, String label) {
    final isActive = _sound == type;
    return ElevatedButton(
      onPressed: () => setState(() => _sound = type),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF61C5B0) : Colors.white,
        foregroundColor: isActive ? Colors.white : const Color(0xFF61C5B0),
        side: const BorderSide(color: Color(0xFF61C5B0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
