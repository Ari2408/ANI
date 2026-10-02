import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/news_service.dart';
import '../services/i18n_service.dart';
import '../services/notification_service.dart';
import 'elder_card.dart';

class NewsHeadlinesCard extends StatefulWidget {
  const NewsHeadlinesCard({Key? key}) : super(key: key);

  @override
  State<NewsHeadlinesCard> createState() => _NewsHeadlinesCardState();
}

class _NewsHeadlinesCardState extends State<NewsHeadlinesCard> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsInit = false;

  Future<void> _initTts() async {
    if (_isTtsInit) return;
    try {
      _flutterTts.setErrorHandler((msg) {
        debugPrint('News TTS Error: $msg');
      });
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isTtsInit = true;
    } catch (e) {
      debugPrint('News TTS init error: $e');
    }
  }

  Future<void> _speakHeadline(String text, String langCode) async {
    try {
      await _initTts();
      await _flutterTts.stop();
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      final loc = langCode == 'ta' ? 'ta-IN' : 'en-IN';
      try {
        await _flutterTts.setLanguage(loc);
      } catch (_) {}

      try {
        final List<dynamic>? voices = await _flutterTts.getVoices;
        if (voices != null && voices.isNotEmpty) {
          for (var v in voices) {
            if (v is Map) {
              final locale = (v['locale'] ?? '').toString().toLowerCase();
              final name = (v['name'] ?? '').toString().toLowerCase();
              if (locale.contains(langCode) || (langCode == 'ta' && (locale.contains('ta') || name.contains('ta')))) {
                await _flutterTts.setVoice({"name": v['name'].toString(), "locale": v['locale'].toString()});
                break;
              }
            }
          }
        }
      } catch (_) {}

      final speakResult = await _flutterTts.speak(text);
      if (speakResult != 1) {
        await NotificationService.speakText(text, lang: langCode);
      }
    } catch (e) {
      debugPrint('TTS Speech error: $e');
      try {
        await NotificationService.speakText(text, lang: langCode);
      } catch (_) {}
    }
  }

  void _showNewsDetailsModal(BuildContext context, NewsItem item, I18nService i18n) {
    final isTamil = i18n.currentLang == 'ta';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23B39B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(item.source, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF23B39B))),
                  const SizedBox(width: 12),
                  Text(item.publishedAt, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: const TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF1B2824)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4D3E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        _speakHeadline('${item.title}. ${item.description}', i18n.currentLang);
                      },
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                      label: Text(
                        isTamil ? 'செய்தியைக் கேட்கவும்' : 'Listen News',
                        style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsService = Provider.of<NewsService>(context);
    final i18n = Provider.of<I18nService>(context);

    final isTamil = i18n.currentLang == 'ta';
    final categories = isTamil
        ? ['All', 'தமிழ்நாடு', 'ஆரோக்கியம்', 'ஆன்மிகம்', 'சினிமா', 'தொழில்நுட்பம்']
        : ['All', 'Tamil Nadu', 'Health', 'Spirituality', 'Cinema', 'Tech'];

    final newsList = newsService.getFilteredNewsForLang(i18n.currentLang);

    return ElderCard(
      backgroundColor: Colors.white,
      border: Border.all(color: const Color(0xFF61C5B0).withOpacity(0.5), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.newspaper, size: 22, color: Color(0xFF23B39B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        i18n.translate('todayNewsHeadlines') ?? (isTamil ? 'இன்றைய முக்கிய செய்திகள்' : "Today's News Headlines"),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: newsService.isLoading ? null : () => newsService.fetchNews(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF23B39B).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      newsService.isLoading
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B4D3E)),
                            )
                          : const Icon(Icons.refresh, size: 14, color: Color(0xFF1B4D3E)),
                      const SizedBox(width: 4),
                      Text(
                        i18n.translate('refreshBtn') ?? (isTamil ? 'புதுப்பி' : 'Refresh'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                i18n.translate('fetchOnlineNewsSub') ?? (isTamil ? 'நேரடி இணைய செய்திகள் & தமிழக செய்திகள்' : 'Online Live News & Regional Daily Highlights'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5D4037)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = newsService.selectedCategory.toLowerCase() == cat.toLowerCase() ||
                    (newsService.selectedCategory == 'All' && cat == 'All');
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1B4D3E),
                    backgroundColor: const Color(0xFFE6F4F1),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF1B2824),
                    ),
                    onSelected: (selected) {
                      if (selected) newsService.setCategory(cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // News Item List
          if (newsService.isLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF23B39B)),
              ),
            ),
          ] else if (newsList.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                isTamil ? 'இந்த பிரிவில் செய்திகள் இல்லை.' : 'No news headlines available for this category.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ] else ...[
            ...newsList.take(4).map((item) {

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF61C5B0).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF23B39B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.category.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('• ${item.source}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                        const Spacer(),
                        Text(item.publishedAt, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _showNewsDetailsModal(context, item, i18n),
                          child: Text(
                            i18n.translate('readFullStory') ?? 'Read Full Story',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF23B39B)),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.volume_up, size: 18, color: Color(0xFF1B4D3E)),
                          onPressed: () => _speakHeadline('${item.title}. ${item.description}', i18n.currentLang),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
