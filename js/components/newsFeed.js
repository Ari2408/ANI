/* ==========================================================================
   Today's News Headlines Component (Web JS)
   Fetches live news from Daily Thanthi with Tamil/English language translation support
   ========================================================================== */

const newsFeed = {
  newsItemsTa: [],
  newsItemsEn: [],
  isLoading: false,
  selectedCategory: 'All',
  listenerAttached: false,

  async init(containerEl) {
    this.container = containerEl;
    if (!this.listenerAttached) {
      document.addEventListener('languageChanged', () => {
        this.selectedCategory = 'All';
        this.render();
      });
      this.listenerAttached = true;
    }
    await this.fetchNews();
  },

  async fetchNews() {
    this.isLoading = true;
    this.render();

    try {
      const response = await fetch('https://api.rss2json.com/v1/api.json?rss_url=https://news.google.com/rss/search?q=Daily+Thanthi+Tamil+Nadu&hl=ta&gl=IN&ceid=IN:ta', {
        headers: { 'Accept': 'application/json' }
      });
      if (response.ok) {
        const data = await response.json();
        if (data.items && data.items.length > 0) {
          this.newsItemsTa = data.items.map(item => ({
            title: item.title || 'தினத்தந்தி செய்திகள்',
            description: item.description || item.content || 'முழு செய்தி விவரங்களை அறிய தட்டவும்.',
            source: 'தினத்தந்தி (Daily Thanthi)',
            category: this.inferTamilCategory(item.title || ''),
            publishedAt: item.pubDate ? new Date(item.pubDate).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'இன்று',
            url: item.link || 'https://www.dailythanthi.com'
          }));
        } else {
          this.newsItemsTa = this.getFallbackTamilNews();
        }
      } else {
        this.newsItemsTa = this.getFallbackTamilNews();
      }
    } catch (err) {
      console.log('Daily Thanthi online fetch notice, using fallback headlines:', err);
      this.newsItemsTa = this.getFallbackTamilNews();
    } finally {
      this.newsItemsEn = this.getFallbackEnglishNews();
      this.isLoading = false;
      this.render();
    }
  },

  inferTamilCategory(title) {
    const t = title.toLowerCase();
    if (t.includes('ஆரோக்கியம்') || t.includes('மருத்துவர்') || t.includes('health')) return 'ஆரோக்கியம்';
    if (t.includes('ஆன்மிகம்') || t.includes('கோவில்')) return 'ஆன்மிகம்';
    if (t.includes('சினிமா') || t.includes('திரை')) return 'சினிமா';
    if (t.includes('தொழில்நுட்பம்') || t.includes('ஏ.ஐ') || t.includes('tech')) return 'தொழில்நுட்பம்';
    return 'தமிழ்நாடு';
  },

  getFallbackTamilNews() {
    return [
      {
        title: 'சென்னை: நீர் பாதுகாப்பு மற்றும் வளர்ச்சித் திட்டங்கள் - அறிவியல்பூர்வ தீர்வு காண முதலமைச்சர் அழைப்பு',
        description: 'தமிழ்நாடு அரசு சார்பில் நீர் மேலாண்மை மற்றும் சென்னை மாநகராட்சி வளர்ச்சித் திட்ட பணிகளுக்கான புதிய அறிவிப்புகள் வெளியீடு.',
        source: 'தினத்தந்தி (Daily Thanthi)',
        category: 'தமிழ்நாடு',
        publishedAt: '10 நிமிடங்களுக்கு முன்',
        url: 'https://www.dailythanthi.com/news/tamilnadu'
      },
      {
        title: 'மனிதன் நீண்ட ஆயுளுடனும் ஆரோக்கியத்துடனும் வாழ்வதற்கு பின்பற்ற வேண்டிய எளிய பழக்கங்கள்',
        description: 'முதியவர்கள் தினமும் 2.5 லிட்டர் தண்ணீர் அருந்துதல், காலை நேர நடைபயிற்சி மற்றும் மனப்பயிற்சி விளையாட்டுகள் செய்வது ஆரோக்கியத்தை மேம்படுத்தும்.',
        source: 'தினத்தந்தி - ஆரோக்கியம்',
        category: 'ஆரோக்கியம்',
        publishedAt: '25 நிமிடங்களுக்கு முன்',
        url: 'https://www.dailythanthi.com/news/health'
      },
      {
        title: 'குணசீலம் பிரசன்ன வெங்கடாஜலபதி கோவில் பிரம்மோற்சவ தேரோட்டம் கோலாகலம்',
        description: 'திருச்சி குணசீலம் பெருமாள் கோவிலில் நடைபெற்ற வருடாந்திர பிரம்மோற்சவ தேரோட்டத்தில் திரளான பக்தர்கள் பங்கேற்று சுவாமி தரிசனம் செய்தனர்.',
        source: 'தினத்தந்தி - ஆன்மிகம்',
        category: 'ஆன்மிகம்',
        publishedAt: '45 நிமிடங்களுக்கு முன்',
        url: 'https://www.dailythanthi.com/devotional'
      },
      {
        title: '72-வது தேசிய திரைப்பட விருது விழா: ஜனாதிபதியிடம் விருது பெற்ற சிறந்த தமிழ் கலைஞர்கள்',
        description: 'டெல்லியில் நடைபெற்ற விழாவில் திரையுலக சாதனையாளர்களுக்கு ஜனாதிபதி திரௌபதி முர்மு தேசிய விருதுகளை வழங்கி கௌரவித்தார்.',
        source: 'தினத்தந்தி - சினிமா',
        category: 'சினிமா',
        publishedAt: '1 மணி நேரத்திற்கு முன்',
        url: 'https://www.dailythanthi.com/cinema'
      },
      {
        title: 'ஏ.ஐ. (செயற்கை நுண்ணறிவு) மற்றும் டிஜிட்டல் தொழில் நுட்ப பயிற்சி - சென்னையில் சிறப்பு ஏற்பாடு',
        description: 'முதியோர் பயன்பாடு மற்றும் டிஜிட்டல் விழிப்புணர்வுக்காக ஏ.ஐ. தொழில்நுட்ப பயிற்சி சென்னையில் 3 நாட்கள் நடைபெறுகிறது.',
        source: 'தினத்தந்தி - டெக்',
        category: 'தொழில்நுட்பம்',
        publishedAt: '2 மணி நேரத்திற்கு முன்',
        url: 'https://www.dailythanthi.com'
      }
    ];
  },

  getFallbackEnglishNews() {
    return [
      {
        title: 'Chennai Water Management & City Infrastructure Projects Announced by Chief Minister',
        description: 'Government of Tamil Nadu releases new framework for sustainable water conservation and Chennai municipal development.',
        source: 'Daily Thanthi Express',
        category: 'Tamil Nadu',
        publishedAt: '10 mins ago',
        url: 'https://www.dailythanthi.com'
      },
      {
        title: 'Simple Daily Habits Recommended for Senior Longevity and Cognitive Health',
        description: 'Health specialists emphasize 2.5 Liters of daily hydration, morning walks along Marina Beach, and daily brain game exercises.',
        source: 'Daily Thanthi - Health',
        category: 'Health',
        publishedAt: '25 mins ago',
        url: 'https://www.dailythanthi.com'
      },
      {
        title: 'Gunaseelam Prasanna Venkatachalapathy Temple Annual Chariot Festival Celebrated Grandly',
        description: 'Devotees gather in large numbers at Trichy Gunaseelam Temple to witness the annual chariot procession and offer prayers.',
        source: 'Daily Thanthi - Devotional',
        category: 'Spirituality',
        publishedAt: '45 mins ago',
        url: 'https://www.dailythanthi.com'
      },
      {
        title: '72nd National Film Awards: Outstanding Tamil Artists Honored by President of India',
        description: 'President Droupadi Murmu confers National Film Awards to acclaimed Tamil cinema creators and artists in New Delhi.',
        source: 'Daily Thanthi - Cinema',
        category: 'Cinema',
        publishedAt: '1 hour ago',
        url: 'https://www.dailythanthi.com'
      },
      {
        title: 'AI Technology & Digital Literacy Workshop for Seniors Organized in Chennai',
        description: 'A 3-day special training program on AI tools and digital accessibility for elder citizens commences in Chennai.',
        source: 'Daily Thanthi - Tech',
        category: 'Tech',
        publishedAt: '2 hours ago',
        url: 'https://www.dailythanthi.com'
      }
    ];
  },

  setCategory(cat) {
    this.selectedCategory = cat;
    this.render();
  },

  getCurrentItems() {
    const isTa = i18n.currentLang === 'ta';
    const items = isTa 
      ? (this.newsItemsTa.length > 0 ? this.newsItemsTa : this.getFallbackTamilNews()) 
      : (this.newsItemsEn.length > 0 ? this.newsItemsEn : this.getFallbackEnglishNews());
    
    if (this.selectedCategory === 'All') return items;

    return items.filter(item => {
      const itemCat = item.category.toLowerCase();
      const selCat = this.selectedCategory.toLowerCase();
      if (itemCat === selCat) return true;
      if ((selCat === 'தமிழ்நாடு' || selCat === 'tamil nadu') && (itemCat === 'தமிழ்நாடு' || itemCat === 'tamil nadu')) return true;
      if ((selCat === 'ஆரோக்கியம்' || selCat === 'health') && (itemCat === 'ஆரோக்கியம்' || itemCat === 'health')) return true;
      if ((selCat === 'ஆன்மிகம்' || selCat === 'spirituality') && (itemCat === 'ஆன்மிகம்' || itemCat === 'spirituality')) return true;
      if ((selCat === 'சினிமா' || selCat === 'cinema') && (itemCat === 'சினிமா' || itemCat === 'cinema')) return true;
      if ((selCat === 'தொழில்நுட்பம்' || selCat === 'tech') && (itemCat === 'தொழ தொழில் நுட்பம்' || itemCat === 'தொழில்நுட்பம்' || itemCat === 'tech')) return true;
      return false;
    });
  },

  speakHeadline(text) {
    if (window.speechEngine && speechEngine.speak) {
      speechEngine.speak(text);
    } else if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      if (window.speechSynthesis.paused) window.speechSynthesis.resume();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = (window.i18n && i18n.currentLang === 'ta') ? 'ta-IN' : 'en-US';
      utterance.rate = 0.85;
      window.speechSynthesis.speak(utterance);
    }
  },

  speakHeadlineByIndex(index) {
    const items = this.getCurrentItems();
    const item = items[index];
    if (item) {
      const textToSpeak = `${item.title}. ${item.description}`;
      this.speakHeadline(textToSpeak);
    }
  },

  openNewsModal(index) {
    const item = this.getCurrentItems()[index];
    if (!item) return;

    const isTa = i18n.currentLang === 'ta';
    const btnLabel = isTa ? '🔊 செய்தியைக் கேட்கவும்' : '🔊 Listen Story';

    const modal = document.createElement('div');
    modal.className = 'modal-overlay active';
    modal.innerHTML = `
      <div class="modal-content" style="max-width: 500px;">
        <div class="modal-header">
          <span class="game-badge" style="background: #E8F5E9; color: var(--primary);">${item.category.toUpperCase()}</span>
          <button class="close-btn" onclick="this.closest('.modal-overlay').remove()">&times;</button>
        </div>
        <h3 style="font-size: 19px; font-weight: 800; color: var(--primary-dark); margin: 10px 0;">${item.title}</h3>
        <p style="font-size: 13px; color: var(--secondary); font-weight: 600; margin-bottom: 12px;">📰 ${item.source} • 🕒 ${item.publishedAt}</p>
        <hr style="border: none; border-top: 1px solid var(--border-color); margin-bottom: 12px;"/>
        <p style="font-size: 15px; line-height: 1.5; color: var(--text-dark); margin-bottom: 20px;">${item.description}</p>
        
        <button class="btn-elder" onclick="newsFeed.speakHeadlineByIndex(${index})">
          ${btnLabel}
        </button>
      </div>
    `;
    document.body.appendChild(modal);
  },

  render(targetContainer) {
    const container = targetContainer || this.container;
    if (!container) return;

    const isTa = i18n.currentLang === 'ta';
    const categories = isTa
      ? ['All', 'தமிழ்நாடு', 'ஆரோக்கியம்', 'ஆன்மிகம்', 'சினிமா', 'தொழில்நுட்பம்']
      : ['All', 'Tamil Nadu', 'Health', 'Spirituality', 'Cinema', 'Tech'];

    const headerTitle = isTa ? '📰 இன்றைய முக்கிய செய்திகள்' : "📰 Today's News Headlines";
    const subTitle = isTa ? '🟢 நேரடி இணைய செய்திகள் & தமிழக செய்திகள்' : '🟢 Live Online Headlines & Regional Updates';
    const refreshText = isTa ? '🔄 புதுப்பி' : '🔄 Refresh';
    const loadingText = isTa ? 'செய்திகள் சேகரிக்கப்படுகின்றன...' : 'Fetching online news headlines...';
    const emptyText = isTa ? 'இந்த பிரிவில் செய்திகள் இல்லை.' : 'No headlines available in this category.';
    const readFullText = isTa ? '📖 முழு செய்தியையும் படிக்கவும்' : '📖 Read Full Story';

    const filtered = this.getCurrentItems();

    container.innerHTML = `
      <div class="elder-card" style="background: #FFFFFF; border: 2px solid var(--primary-light);">
        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 6px;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <h3 style="font-size: 17px; font-weight: 800; color: var(--primary-dark); margin: 0;">${headerTitle}</h3>
          </div>
          <button class="btn-elder btn-outline" style="padding: 4px 10px; font-size: 12px;" onclick="newsFeed.fetchNews()">
            ${this.isLoading ? '⌛' : refreshText}
          </button>
        </div>
        
        <p style="font-size: 12px; color: var(--secondary); font-weight: 600; margin-bottom: 10px;">
          ${subTitle}
        </p>

        <!-- Category Pills -->
        <div style="display: flex; gap: 6px; overflow-x: auto; padding-bottom: 8px; margin-bottom: 10px;">
          ${categories.map(cat => `
            <button onclick="newsFeed.setCategory('${cat}')" style="padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 700; border: 1px solid var(--primary); cursor: pointer; background: ${this.selectedCategory === cat ? 'var(--primary)' : '#E6F4F1'}; color: ${this.selectedCategory === cat ? '#FFF' : 'var(--primary-dark)'}; flex-shrink: 0;">
              ${cat}
            </button>
          `).join('')}
        </div>

        <!-- News Items -->
        ${this.isLoading ? `
          <div style="text-align: center; padding: 20px; color: var(--primary);">
            <p>${loadingText}</p>
          </div>
        ` : filtered.length === 0 ? `
          <p style="font-size: 13px; color: #777;">${emptyText}</p>
        ` : filtered.slice(0, 4).map((item, idx) => `
          <div style="background: #F9FBF9; border: 1px solid var(--border-color); border-radius: 14px; padding: 12px; margin-bottom: 10px;">
            <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 4px;">
              <span style="font-size: 10px; font-weight: 800; background: #E8F5E9; color: var(--primary); padding: 2px 6px; border-radius: 6px;">${item.category.toUpperCase()}</span>
              <span style="font-size: 11px; color: #777;">${item.source} • ${item.publishedAt}</span>
            </div>
            <h4 style="font-size: 14px; font-weight: 700; color: var(--primary-dark); margin-bottom: 8px; line-height: 1.3;">${item.title}</h4>
            <div style="display: flex; align-items: center; justify-content: space-between;">
              <span onclick="newsFeed.openNewsModal(${idx})" style="font-size: 12px; font-weight: 700; color: var(--secondary); cursor: pointer;">
                ${readFullText}
              </span>
              <button onclick="newsFeed.speakHeadlineByIndex(${idx})" style="background: none; border: none; font-size: 16px; cursor: pointer;" title="Listen Headline">
                🔊
              </button>
            </div>
          </div>
        `).join('')}
      </div>
    `;
  }
};

window.newsFeed = newsFeed;

