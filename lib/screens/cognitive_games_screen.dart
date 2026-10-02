import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/i18n_service.dart';
import '../services/ai_cognitive_engine.dart';
import '../widgets/elder_card.dart';
import 'games/routine_recall_game_screen.dart';
import 'games/familiar_faces_game_screen.dart';
import 'games/spot_diff_game_screen.dart';
import 'games/remember_now_game_screen.dart';
import 'games/word_association_game_screen.dart';
import 'games/mindful_nature_screen.dart';

class CognitiveGamesScreen extends StatelessWidget {
  const CognitiveGamesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final i18n = Provider.of<I18nService>(context);
    final aiEngine = Provider.of<AiCognitiveEngine>(context);
    final isTamil = i18n.currentLang == 'ta';

    final myDayTitle = isTamil ? 'என் நாள் (சுய பழக்கவரிசை)' : 'My Day (Daily Flow)';
    final myDayDesc = isTamil
        ? 'காலைத் தேநீர், வழிபாடு, மதிய உணவு மற்றும் ஓய்வை வரிசைப்படுத்துங்கள்'
        : 'What comes next? Put morning tea, prayer, lunch, and rest in order.';
    final myDayBadge = isTamil ? 'நாளாந்த ஒழுங்கு' : 'Routine Flow';

    final familiarTitle = isTamil ? 'சினாக்கி முகங்கள் (அடையாளம்)' : 'Familiar Faces (Name & Photo)';
    final familiarDesc = isTamil
        ? 'பெயரைக் கேட்டு அல்லது படித்து சரியான குடும்பப் புகைப்படத்தைத் தேர்ந்தெடுக்கவும்'
        : 'Read or listen to the name, then tap the matching photo of your loved one.';
    final familiarBadge = isTamil ? 'குடும்ப முகங்கள்' : 'Face Recognition';

    final spotDiffTitle = isTamil ? 'வித்தியாசம் பிடி! (கூர்ந்த கவனிப்பு)' : 'Spot It! (Visual Difference)';
    final spotDiffDesc = isTamil
        ? 'இரு காட்சிப் படங்களை ஒப்பிட்டு வித்தியாசமான இடத்தைத் தொடுங்கள்'
        : 'Display two similar scenes side by side. Tap where you notice a difference!';
    final spotDiffBadge = isTamil ? 'கூர்ந்த கவனிப்பு' : 'Keen Eye';

    final rememberNowTitle = isTamil ? 'நினைவில் வை (ஆரோக்கிய கடிகாரம்)' : 'Remember Now (Routine Clock)';
    final rememberNowDesc = isTamil
        ? 'நேரத்திற்கு ஏற்ற மருந்து மற்றும் ஆரோக்கிய பழக்கங்களை நினைவுகூருங்கள்'
        : 'What is next on your clock? Quick picture answers for medicines & water.';
    final rememberNowBadge = isTamil ? 'நினைவூட்டல் வினா' : 'Routine Quiz';

    final mindfulTitleText = isTamil
        ? 'மன அமைதி மற்றும் மூச்சுப் பயிற்சி'
        : (i18n.translate('mindfulTitle') != 'mindfulTitle' ? i18n.translate('mindfulTitle') : 'Mindful Breathing');
    final mindfulDescText = isTamil
        ? 'மன அமைதிக்கான மூச்சுப் பயிற்சி மற்றும் இயற்கை ஒலிகள்'
        : (i18n.translate('mindfulDesc') != 'mindfulDesc' ? i18n.translate('mindfulDesc') : 'Calming breathing exercises & nature soundscapes for relaxation');
    final emotionalBadgeText = isTamil ? 'மன அமைதி' : 'Guided Breathing';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI Cognitive Banner
        ElderCard(
          backgroundColor: const Color(0xFF61C5B0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                i18n.translate("dailyGames"),
                style: const TextStyle(color: Color(0xFF1B2824), fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${i18n.translate("aiLevel")} ${aiEngine.currentLevel} • ${i18n.translate("personalizedExercises")}',
                style: const TextStyle(color: Color(0xFF1B2824), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // SECTION 1: COGNITIVE GAMES (4 Primary Interactive Games)
        _buildSectionHeader(
          isTamil ? 'பிரிவு 1: நினைவாற்றல் விளையாட்டுகள் (4 பயிற்சிகள்)' : 'Section 1: Cognitive Games (4 Games)',
          isTamil ? 'நாளாந்த வரிசைமுறை, முகங்கள் அடையாளம், கவனிப்பு மற்றும் வழக்கமான நினைவூட்டல்கள்' : '4 interactive exercises for daily flow, faces, visual observation & routine recall',
          badgeText: isTamil ? '4 விளையாட்டுகள்' : '4 GAMES',
          badgeColor: const Color(0xFF1B4D3E),
        ),

        // Game 1: My Day (Daily Flow Sequencer)
        _buildGameTile(
          context,
          iconData: Icons.wb_sunny,
          title: myDayTitle,
          desc: myDayDesc,
          badge: myDayBadge,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutineRecallGameScreen())),
        ),

        // Game 2: Familiar Faces (Name & Face Matching)
        _buildGameTile(
          context,
          iconData: Icons.face,
          title: familiarTitle,
          desc: familiarDesc,
          badge: familiarBadge,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamiliarFacesGameScreen())),
        ),

        // Game 3: Spot It! (Side-by-Side Visual Observation)
        _buildGameTile(
          context,
          iconData: Icons.visibility,
          title: spotDiffTitle,
          desc: spotDiffDesc,
          badge: spotDiffBadge,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpotDiffGameScreen())),
        ),

        // Game 4: Remember Now (Routine Clock Quiz)
        _buildGameTile(
          context,
          iconData: Icons.alarm,
          title: rememberNowTitle,
          desc: rememberNowDesc,
          badge: rememberNowBadge,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RememberNowGameScreen())),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(color: Color(0xFF23B39B), thickness: 1.5, height: 24),
        ),

        // SECTION 2: GUIDED BREATHING
        _buildSectionHeader(
          isTamil ? 'பிரிவு 2: வழிகாட்டப்பட்ட மூச்சுப் பயிற்சி' : 'Section 2: Guided Breathing',
          isTamil ? 'மன அமைதிக்கான மூச்சுப் பயிற்சி மற்றும் இயற்கை ஒலிகள்' : 'Calming breathing exercises & nature soundscapes for relaxation',
          badgeText: isTamil ? 'மூச்சுப் பயிற்சி' : 'BREATHING',
          badgeColor: const Color(0xFF0284C7),
        ),

        // Guided Breathing Module
        _buildGameTile(
          context,
          iconData: Icons.spa,
          title: mindfulTitleText,
          desc: mindfulDescText,
          badge: emotionalBadgeText,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MindfulNatureScreen())),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, {String? badgeText, Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2824),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor ?? const Color(0xFF1B4D3E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D4037),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile(
    BuildContext context, {
    required IconData iconData,
    required String title,
    required String desc,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: ElderCard(
          border: Border.all(color: const Color(0xFF61C5B0).withOpacity(0.4), width: 1.5),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF98DACB).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF23B39B).withOpacity(0.4)),
                ),
                alignment: Alignment.center,
                child: Icon(iconData, size: 32, color: const Color(0xFF1B4D3E)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2824))),
                    const SizedBox(height: 2),
                    Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF1B2824))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF23B39B), borderRadius: BorderRadius.circular(12)),
                      child: Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
