/* ==========================================================================
   Main Mobile Application Router & Lifecycle Manager
   ========================================================================== */

const appRouter = {
  currentTab: 'home',

  init() {
    this.bindEvents();
    this.updateLanguageUI();
    this.navigate('home');

    // Register PWA Service Worker for offline functionality
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('sw.js').then(() => {
        console.log('ServiceWorker registered successfully.');
      }).catch(err => console.warn('ServiceWorker registration failed:', err));
    }

    // Monitor Online / Offline status
    window.addEventListener('online', () => this.updateSyncStatus(true));
    window.addEventListener('offline', () => this.updateSyncStatus(false));
    this.updateSyncStatus(navigator.onLine);
  },

  bindEvents() {
    // Language selection change
    document.addEventListener('languageChanged', () => {
      this.updateLanguageUI();
      this.navigate(this.currentTab);
    });
  },

  navigate(tabId) {
    this.currentTab = tabId;

    // Update active tab buttons
    document.querySelectorAll('.nav-tab').forEach(tab => {
      if (tab.dataset.tab === tabId) tab.classList.add('active');
      else tab.classList.remove('active');
    });

    // Update active views
    document.querySelectorAll('.app-view').forEach(view => {
      view.classList.remove('active');
    });

    if (tabId === 'home') {
      const v = document.getElementById('viewHome');
      if (v) { v.classList.add('active'); patientView.render(v); }
    } else if (tabId === 'games') {
      const v = document.getElementById('viewGames');
      if (v) { v.classList.add('active'); this.renderGamesHub(v); }
    } else if (tabId === 'schedule') {
      const v = document.getElementById('viewSchedule');
      if (v) { v.classList.add('active'); scheduleReminders.render(v); }
    } else if (tabId === 'memoryLane') {
      const v = document.getElementById('viewMemoryLane');
      if (v) { v.classList.add('active'); memoryLane.render(v); }
    } else if (tabId === 'caregiver') {
      const v = document.getElementById('viewCaregiver');
      if (v) { v.classList.add('active'); caregiverDashboard.render(v); }
    }
  },

  renderGamesHub(containerEl) {
    containerEl.innerHTML = `
      <div class="games-hub-view">
        <div class="elder-card" style="background: linear-gradient(135deg, var(--primary) 0%, var(--primary-light) 100%); color: #FFF; margin-bottom: 20px;">
          <h2 style="font-size: 22px; font-weight: 800; margin-bottom: 4px;">🧩 ${i18n.t('dailyGames')}</h2>
          <p style="font-size: 14px; opacity: 0.9;">${i18n.t('adaptiveDifficulty')} • ${i18n.t('levelTag')} ${aiEngine.patientState.currentLevel}</p>
        </div>

        <div id="gamePlayArea">
          <!-- SECTION 1: 4 COGNITIVE GAMES -->
          <div class="section-header" style="margin-bottom: 12px;">
            <h3 style="font-size: 20px; font-weight: 800; color: var(--primary-dark); margin-bottom: 2px;">
              ${i18n.t('gamesSection')}
            </h3>
            <p style="font-size: 13px; color: var(--text-muted);">
              ${i18n.t('gamesSectionSub')}
            </p>
          </div>

          <div class="games-hub-grid" style="margin-bottom: 28px;">
            <div class="game-card" onclick="visualMemoryGame.init(document.getElementById('gamePlayArea'))">
              <div class="game-icon-box">🧠</div>
              <div class="game-info">
                <h3>${i18n.t('memoryMatchTitle')}</h3>
                <p>${i18n.t('memoryMatchDesc')}</p>
                <span class="game-badge">${i18n.t('visualMemoryBadge')}</span>
              </div>
            </div>

            <div class="game-card" onclick="routineRecallGame.init(document.getElementById('gamePlayArea'))">
              <div class="game-icon-box">📅</div>
              <div class="game-info">
                <h3>${i18n.t('routineTitle')}</h3>
                <p>${i18n.t('routineDesc')}</p>
                <span class="game-badge">${i18n.t('seqMemoryBadge')}</span>
              </div>
            </div>

            <div class="game-card" onclick="patternSortingGame.init(document.getElementById('gamePlayArea'))">
              <div class="game-icon-box">🧵</div>
              <div class="game-info">
                <h3>${i18n.t('patternTitle')}</h3>
                <p>${i18n.t('patternDesc')}</p>
                <span class="game-badge">${i18n.t('attentionFocusBadge')}</span>
              </div>
            </div>

            <div class="game-card" onclick="wordAssociationGame.init(document.getElementById('gamePlayArea'))">
              <div class="game-icon-box">🔗</div>
              <div class="game-info">
                <h3>${i18n.t('wordAssocTitle')}</h3>
                <p>${i18n.t('wordAssocDesc')}</p>
                <span class="game-badge">${i18n.t('wordAssocBadge')}</span>
              </div>
            </div>
          </div>

          <!-- SECTION 2: GUIDED BREATHING -->
          <div class="section-header" style="margin-bottom: 12px; border-top: 2px dashed rgba(27,77,62,0.15); padding-top: 20px;">
            <h3 style="font-size: 20px; font-weight: 800; color: var(--primary-dark); margin-bottom: 2px;">
              ${i18n.t('guidedBreathingSection')}
            </h3>
            <p style="font-size: 13px; color: var(--text-muted);">
              ${i18n.t('guidedBreathingSectionSub')}
            </p>
          </div>

          <div class="games-hub-grid">
            <div class="game-card" onclick="mindfulNatureGame.init(document.getElementById('gamePlayArea'))">
              <div class="game-icon-box">🌿</div>
              <div class="game-info">
                <h3>${i18n.t('mindfulTitle')}</h3>
                <p>${i18n.t('mindfulDesc')}</p>
                <span class="game-badge" style="background: #E0F2FE; color: #0284C7;">${i18n.t('emotionalCalmBadge')}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  },

  updateLanguageUI() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.dataset.i18n;
      el.textContent = i18n.t(key);
    });

    const langBtn = document.getElementById('langSelectBtn');
    if (langBtn) {
      const cur = i18n.languages[i18n.currentLang];
      langBtn.textContent = cur ? cur.flag : '🌐';
    }
  },

  toggleContrast() {
    document.body.classList.toggle('high-contrast');
    audioSynth.playChime();
  },

  openLanguageModal() {
    const modal = document.getElementById('langModal');
    if (modal) modal.classList.add('active');
  },

  closeLanguageModal() {
    const modal = document.getElementById('langModal');
    if (modal) modal.classList.remove('active');
  },

  selectLang(code) {
    i18n.setLanguage(code);
    this.closeLanguageModal();
    audioSynth.playChime();
    speechEngine.speak(i18n.t('welcomeMessage'));
  },

  updateSyncStatus(isOnline) {
    const syncBar = document.getElementById('syncBar');
    const syncText = document.getElementById('syncText');
    if (syncBar && syncText) {
      if (isOnline) {
        syncBar.classList.remove('offline');
        syncText.textContent = i18n.t('onlineModeText');
      } else {
        syncBar.classList.add('offline');
        syncText.textContent = i18n.t('offlineModeText');
      }
    }
  }
};

window.appRouter = appRouter;

document.addEventListener('DOMContentLoaded', () => {
  speechEngine.init();
  appRouter.init();
});
