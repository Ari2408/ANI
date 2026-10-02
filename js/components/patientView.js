/* ==========================================================================
   Patient View Component (Elderly Home Screen)
   ========================================================================== */

const patientView = {
  render(containerEl) {
    const chi = aiEngine.calculateCHI();
    const risk = aiEngine.getRiskAssessment();
    const hydration = appStorage.loadHydration();

    containerEl.innerHTML = `
      <div class="patient-home">
        <!-- Greeting Card -->
        <div class="elder-card" style="background: linear-gradient(135deg, var(--primary) 0%, var(--primary-light) 100%); color: #FFF;">
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px;">
            <span style="font-size: 14px; opacity: 0.9;">🗓️ ${new Date().toLocaleDateString('en-IN', { weekday: 'long', month: 'short', day: 'numeric' })}</span>
            <span class="risk-badge" style="background: ${risk.color}; font-size: 11px;">${risk.level.toUpperCase()}</span>
          </div>
          <h2 style="font-size: 22px; font-weight: 800; margin-bottom: 6px;">${i18n.t('welcomeMessage')}</h2>
          
          <div style="display: flex; align-items: center; justify-content: space-between; margin-top: 14px; background: rgba(255,255,255,0.15); padding: 12px; border-radius: 14px;">
            <div>
              <span style="font-size: 12px; opacity: 0.9;">${i18n.t('cognitiveHealthIndex')}</span>
              <div style="font-size: 28px; font-weight: 900;">${chi} <span style="font-size: 14px; font-weight: 500;">/ 100</span></div>
            </div>
            <button class="header-btn" onclick="speechEngine.speak(i18n.t('welcomeMessage'))" style="background: #FFF; color: var(--primary);">
              🔊
            </button>
          </div>
        </div>

        <!-- Today's News Headlines Section (Above Schedules) -->
        <div id="newsFeedContainer"></div>

        <!-- Today's Quick Actions & Schedules Preview -->
        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; margin-bottom: 16px;">
          <div class="elder-card" onclick="appRouter.navigate('games')" style="cursor: pointer; text-align: center; margin-bottom: 0; padding: 16px;">
            <div style="font-size: 36px; margin-bottom: 6px;">🧩</div>
            <h3 style="font-size: 16px; font-weight: 700; color: var(--primary-dark);">${i18n.t('games')}</h3>
            <p style="font-size: 12px; color: var(--text-muted);">${i18n.t('activeGamesSub')}</p>
          </div>

          <div class="elder-card" onclick="appRouter.navigate('schedule')" style="cursor: pointer; text-align: center; margin-bottom: 0; padding: 16px;">
            <div style="font-size: 36px; margin-bottom: 6px;">💊</div>
            <h3 style="font-size: 16px; font-weight: 700; color: var(--primary-dark);">${i18n.t('schedule')}</h3>
            <p style="font-size: 12px; color: var(--text-muted);">${hydration}/8 ${i18n.t('glasses')}</p>
          </div>
        </div>

        <!-- Featured Cognitive Game Card -->
        <div class="elder-card">
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px;">
            <h3 class="card-title" style="margin-bottom: 0;">🧠 ${i18n.t('dailyGames')}</h3>
            <span class="game-badge">${i18n.t('levelTag')} ${aiEngine.patientState.currentLevel}</span>
          </div>
          <p style="font-size: 14px; color: var(--text-muted); margin-bottom: 14px;">${i18n.t('memoryMatchDesc')}</p>
          
          <button class="btn-elder" onclick="appRouter.navigate('games'); setTimeout(() => visualMemoryGame.init(document.getElementById('gamePlayArea')), 100);">
            ▶️ ${i18n.t('memoryMatchTitle')}
          </button>
        </div>

        <!-- Quick Memory Lane Banner -->
        <div class="elder-card" onclick="appRouter.navigate('memoryLane')" style="cursor: pointer; background: #FFF8F0; border-color: var(--secondary);">
          <div style="display: flex; align-items: center; gap: 14px;">
            <div style="font-size: 36px;">📸</div>
            <div>
              <h3 style="font-size: 18px; color: var(--secondary); font-weight: 700;">${i18n.t('memoryLane')}</h3>
              <p style="font-size: 13px; color: var(--text-dark);">${i18n.t('memoryLaneSub')}</p>
            </div>
          </div>
        </div>
      </div>
    `;

    setTimeout(() => {
      const nfContainer = document.getElementById('newsFeedContainer');
      if (nfContainer && window.newsFeed) {
        newsFeed.init(nfContainer);
      }
    }, 50);
  }
};

window.patientView = patientView;
