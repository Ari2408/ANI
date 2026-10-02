import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NewsItem {
  final String title;
  final String description;
  final String source;
  final String category;
  final String publishedAt;
  final String url;
  final String imageUrl;
  final String lang;

  NewsItem({
    required this.title,
    required this.description,
    required this.source,
    required this.category,
    required this.publishedAt,
    required this.url,
    this.imageUrl = '',
    this.lang = 'en',
  });
}

class NewsService extends ChangeNotifier {
  List<NewsItem> _tamilNews = [];
  List<NewsItem> _englishNews = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;

  NewsService() {
    fetchNews();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<NewsItem> getNewsForLang(String langCode) {
    final list = (langCode == 'ta') ? _tamilNews : _englishNews;
    if (list.isEmpty) {
      return (langCode == 'ta') ? _getFallbackTamilNews() : _getFallbackEnglishNews();
    }
    return list;
  }

  List<NewsItem> getFilteredNewsForLang(String langCode) {
    final list = getNewsForLang(langCode);
    if (_selectedCategory == 'All') return list;
    return list.where((item) => item.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
  }

  Future<void> fetchNews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<NewsItem> fetchedTamil = [];
      final List<NewsItem> fetchedEnglish = [];

      // 1. Fetch Tamil News from Daily Thanthi RSS
      try {
        final urlTa = Uri.parse('https://api.rss2json.com/v1/api.json?rss_url=https://news.google.com/rss/search?q=Daily+Thanthi+Tamil+Nadu&hl=ta&gl=IN&ceid=IN:ta');
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 4);
        final reqTa = await client.getUrl(urlTa);
        reqTa.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
        final resTa = await reqTa.close();

        if (resTa.statusCode == 200) {
          final bodyText = await resTa.transform(utf8.decoder).join();
          final data = jsonDecode(bodyText);
          if (data['items'] != null && data['items'] is List) {
            for (var item in (data['items'] as List).take(10)) {
              fetchedTamil.add(NewsItem(
                title: item['title'] ?? 'தினத்தந்தி செய்திகள்',
                description: item['description'] ?? item['content'] ?? 'முழு செய்தி விவரங்களை அறிய தட்டவும்.',
                source: 'தினத்தந்தி (Daily Thanthi)',
                category: _inferTamilCategory(item['title'] ?? ''),
                publishedAt: item['pubDate'] ?? 'இன்று',
                url: item['link'] ?? 'https://www.dailythanthi.com',
                lang: 'ta',
              ));
            }
          }
        }
      } catch (e) {
        print('Tamil news fetch notice: $e');
      }

      // 2. Fetch English News
      try {
        final urlEn = Uri.parse('https://saurav.tech/NewsAPI/top-headlines/category/general/in.json');
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 4);
        final reqEn = await client.getUrl(urlEn);
        reqEn.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
        final resEn = await reqEn.close();

        if (resEn.statusCode == 200) {
          final bodyText = await resEn.transform(utf8.decoder).join();
          final data = jsonDecode(bodyText);
          if (data['articles'] != null && data['articles'] is List) {
            for (var item in (data['articles'] as List).take(10)) {
              fetchedEnglish.add(NewsItem(
                title: item['title'] ?? 'Today Headline News',
                description: item['description'] ?? item['content'] ?? 'Tap to read full article details.',
                source: item['source'] is Map ? (item['source']['name'] ?? 'Daily Thanthi Express') : 'Daily Thanthi Express',
                category: _inferEnglishCategory(item['title'] ?? ''),
                publishedAt: item['publishedAt'] ?? 'Today',
                url: item['url'] ?? 'https://www.dailythanthi.com',
                lang: 'en',
              ));
            }
          }
        }
      } catch (e) {
        print('English news fetch notice: $e');
      }

      _tamilNews = fetchedTamil.isNotEmpty ? fetchedTamil : _getFallbackTamilNews();
      _englishNews = fetchedEnglish.isNotEmpty ? fetchedEnglish : _getFallbackEnglishNews();
    } catch (e) {
      _tamilNews = _getFallbackTamilNews();
      _englishNews = _getFallbackEnglishNews();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _inferTamilCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('ஆரோக்கியம்') || lower.contains('மருத்துவர்') || lower.contains('உடல்நலம்') || lower.contains('health')) {
      return 'ஆரோக்கியம்';
    } else if (lower.contains('ஆன்மிகம்') || lower.contains('கோவில்') || lower.contains('பூஜை')) {
      return 'ஆன்மிகம்';
    } else if (lower.contains('தொழில்நுட்பம்') || lower.contains('ஏ.ஐ') || lower.contains('tech')) {
      return 'தொழில்நுட்பம்';
    }
    return 'தமிழ்நாடு';
  }

  String _inferEnglishCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('health') || lower.contains('doctor') || lower.contains('hospital') || lower.contains('wellness') || lower.contains('dementia')) {
      return 'Health';
    } else if (lower.contains('tamil') || lower.contains('chennai') || lower.contains('madurai') || lower.contains('tanjore') || lower.contains('coimbatore') || lower.contains('ooty') || lower.contains('kaveri')) {
      return 'Tamil Nadu';
    } else if (lower.contains('tech') || lower.contains('ai') || lower.contains('mobile') || lower.contains('digital')) {
      return 'Tech';
    }
    return 'India';
  }

  List<NewsItem> _getFallbackTamilNews() {
    return [
      NewsItem(
        title: 'சென்னை: நீர் பாதுகாப்பு மற்றும் வளர்ச்சித் திட்டங்கள் - அறிவியல்பூர்வ தீர்வு காண முதலமைச்சர் அழைப்பு',
        description: 'தமிழ்நாடு அரசு சார்பில் நீர் மேலாண்மை மற்றும் சென்னை மாநகராட்சி வளர்ச்சித் திட்ட பணிகளுக்கான புதிய அறிவிப்புகள் வெளியீடு.',
        source: 'தினத்தந்தி (Daily Thanthi)',
        category: 'தமிழ்நாடு',
        publishedAt: '10 நிமிடங்களுக்கு முன்',
        url: 'https://www.dailythanthi.com/news/tamilnadu',
        lang: 'ta',
      ),
      NewsItem(
        title: 'மனிதன் நீண்ட ஆயுளுடனும் ஆரோக்கியத்துடனும் வாழ்வதற்கு பின்பற்ற வேண்டிய எளிய பழக்கங்கள்',
        description: 'முதியவர்கள் தினமும் 2.5 லிட்டர் தண்ணீர் அருந்துதல், காலை நேர நடைபயிற்சி மற்றும் மனப்பயிற்சி விளையாட்டுகள் செய்வது ஆரோக்கியத்தை மேம்படுத்தும்.',
        source: 'தினத்தந்தி - ஆரோக்கியம்',
        category: 'ஆரோக்கியம்',
        publishedAt: '25 நிமிடங்களுக்கு முன்',
        url: 'https://www.dailythanthi.com/news/health',
        lang: 'ta',
      ),
      NewsItem(
        title: 'குணசீலம் பிரசன்ன வெங்கடாஜலபதி கோவில் பிரம்மோற்சவ தேரோட்டம் கோலாகலம்',
        description: 'திருச்சி குணசீலம் பெருமாள் கோவிலில் நடைபெற்ற வருடாந்திர பிரம்மோற்சவ தேரோட்டத்தில் திரளான பக்தர்கள் பங்கேற்று சுவாமி தரிசனம் செய்தனர்.',
        source: 'தினத்தந்தி - ஆன்மிகம்',
        category: 'ஆன்மிகம்',
        publishedAt: '45 நிமிடங்களுக்கு முன்',
        url: 'https://www.dailythanthi.com/devotional',
        lang: 'ta',
      ),
      NewsItem(
        title: '72-வது தேசிய திரைப்பட விருது விழா: ஜனாதிபதியிடம் விருது பெற்ற சிறந்த தமிழ் கலைஞர்கள்',
        description: 'டெல்லியில் நடைபெற்ற விழாவில் திரையுலக சாதனையாளர்களுக்கு ஜனாதிபதி திரௌபதி முர்மு தேசிய விருதுகளை வழங்கி கௌரவித்தார்.',
        source: 'தினத்தந்தி - சினிமா',
        category: 'சினிமா',
        publishedAt: '1 மணி நேரத்திற்கு முன்',
        url: 'https://www.dailythanthi.com/cinema',
        lang: 'ta',
      ),
      NewsItem(
        title: 'ஏ.ஐ. (செயற்கை நுண்ணறிவு) மற்றும் டிஜிட்டல் தொழில் நுட்ப பயிற்சி - சென்னையில் சிறப்பு ஏற்பாடு',
        description: 'முதியோர் பயன்பாடு மற்றும் டிஜிட்டல் விழிப்புணர்வுக்காக ஏ.ஐ. தொழில்நுட்ப பயிற்சி சென்னையில் 3 நாட்கள் நடைபெறுகிறது.',
        source: 'தினத்தந்தி - டெக்',
        category: 'தொழில்நுட்பம்',
        publishedAt: '2 மணி நேரத்திற்கு முன்',
        url: 'https://www.dailythanthi.com',
        lang: 'ta',
      ),
    ];
  }

  List<NewsItem> _getFallbackEnglishNews() {
    return [
      NewsItem(
        title: 'Chennai Water Management & City Infrastructure Projects Announced by Chief Minister',
        description: 'Government of Tamil Nadu releases new framework for sustainable water conservation and Chennai municipal development.',
        source: 'Daily Thanthi Express',
        category: 'Tamil Nadu',
        publishedAt: '10 mins ago',
        url: 'https://www.dailythanthi.com',
        lang: 'en',
      ),
      NewsItem(
        title: 'Simple Daily Habits Recommended for Senior Longevity and Cognitive Health',
        description: 'Health specialists emphasize 2.5 Liters of daily hydration, morning walks along Marina Beach, and daily brain game exercises.',
        source: 'Daily Thanthi - Health',
        category: 'Health',
        publishedAt: '25 mins ago',
        url: 'https://www.dailythanthi.com',
        lang: 'en',
      ),
      NewsItem(
        title: 'Gunaseelam Prasanna Venkatachalapathy Temple Annual Chariot Festival Celebrated Grandly',
        description: 'Devotees gather in large numbers at Trichy Gunaseelam Temple to witness the annual chariot procession and offer prayers.',
        source: 'Daily Thanthi - Devotional',
        category: 'Spirituality',
        publishedAt: '45 mins ago',
        url: 'https://www.dailythanthi.com',
        lang: 'en',
      ),
      NewsItem(
        title: '72nd National Film Awards: Outstanding Tamil Artists Honored by President of India',
        description: 'President Droupadi Murmu confers National Film Awards to acclaimed Tamil cinema creators and artists in New Delhi.',
        source: 'Daily Thanthi - Cinema',
        category: 'Cinema',
        publishedAt: '1 hour ago',
        url: 'https://www.dailythanthi.com',
        lang: 'en',
      ),
      NewsItem(
        title: 'AI Technology & Digital Literacy Workshop for Seniors Organized in Chennai',
        description: 'A 3-day special training program on AI tools and digital accessibility for elder citizens commences in Chennai.',
        source: 'Daily Thanthi - Tech',
        category: 'Tech',
        publishedAt: '2 hours ago',
        url: 'https://www.dailythanthi.com',
        lang: 'en',
      ),
    ];
  }
}
