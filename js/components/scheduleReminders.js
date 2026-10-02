/* ==========================================================================
   Schedule & Reminders Component (Medicine, Hydration, Doctor Appointments)
   ========================================================================== */

const scheduleReminders = {
  render(containerEl) {
    const reminders = appStorage.loadReminders();
    const hydration = appStorage.loadHydration();

    containerEl.innerHTML = `
      <div class="schedule-view">
        <!-- Hydration Water Gauge Card -->
        <div class="elder-card" style="background: linear-gradient(135deg, #E3F2FD 0%, #BBDEFB 100%); border-color: #90CAF9;">
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
            <h3 class="card-title" style="color: #0D47A1; margin-bottom: 0;">💧 ${i18n.t('hydrationGoal')}</h3>
            <span style="font-size: 18px; font-weight: 800; color: #0D47A1;">${hydration} / 8 ${i18n.t('glasses')}</span>
          </div>

          <!-- Touch Water Drop Progress -->
          <div style="display: flex; justify-content: space-around; margin: 12px 0;">
            ${[1, 2, 3, 4, 5, 6, 7, 8].map(num => `
              <div onclick="scheduleReminders.tapWater(${num})" style="cursor: pointer; font-size: 26px; transition: transform 0.2s; ${num <= hydration ? 'opacity: 1; transform: scale(1.1);' : 'opacity: 0.3;'}">
                💧
              </div>
            `).join('')}
          </div>

          <button class="btn-elder" onclick="scheduleReminders.addWater()" style="background: #1976D2;">
            ${i18n.t('logWaterBtn')}
          </button>
        </div>

        <!-- Medicine Reminders -->
        <div class="elder-card">
          <h3 class="card-title">💊 ${i18n.t('todayReminders')}</h3>

          <div style="display: flex; flex-direction: column; gap: 12px;">
            ${reminders.map(r => `
              <div style="display: flex; align-items: center; justify-content: space-between; padding: 12px; background: #F9FAF8; border-radius: 14px; border: 1px solid var(--border-color);">
                <div style="display: flex; align-items: center; gap: 12px;">
                  <div style="font-size: 28px;">${r.type === 'medicine' ? '💊' : '🩺'}</div>
                  <div>
                    <h4 style="font-size: 16px; font-weight: 700; color: var(--primary-dark);">${r.title}</h4>
                    <p style="font-size: 12px; color: var(--text-muted);">${r.time} • ${r.dosage || r.location}</p>
                  </div>
                </div>

                <button class="btn-elder ${r.completed ? 'btn-outline' : ''}" onclick="scheduleReminders.toggleReminder('${r.id}')" style="min-height: 44px; width: auto; padding: 8px 14px; font-size: 14px;">
                  ${r.completed ? i18n.t('taken') : i18n.t('takeNow')}
                </button>
              </div>
            `).join('')}
          </div>
        </div>
      </div>
    `;
  },

  tapWater(num) {
    audioSynth.playChime();
    appStorage.saveHydration(num);
    this.render(document.getElementById('viewSchedule'));
  },

  addWater() {
    let current = appStorage.loadHydration();
    if (current < 8) current++;
    audioSynth.playChime();
    speechEngine.speak("Great hydration!");
    appStorage.saveHydration(current);
    this.render(document.getElementById('viewSchedule'));
  },

  toggleReminder(id) {
    const reminders = appStorage.loadReminders();
    const item = reminders.find(r => r.id === id);
    if (item) {
      item.completed = !item.completed;
      appStorage.saveReminders(reminders);
      if (item.completed) {
        audioSynth.playChime();
        speechEngine.speak("Medicine marked as taken.");
      }
      this.render(document.getElementById('viewSchedule'));
    }
  }
};

window.scheduleReminders = scheduleReminders;
