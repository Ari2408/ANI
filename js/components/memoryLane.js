/* ==========================================================================
   Memory Lane Component (Nostalgia Scrapbook & Voice Photo Album)
   ========================================================================== */

const memoryLane = {
  render(containerEl) {
    const photos = appStorage.loadMemoryLane();

    containerEl.innerHTML = `
      <div class="memory-lane-view">
        <div class="elder-card" style="background: #FFF8F0; border-color: var(--secondary);">
          <h3 class="card-title" style="color: var(--secondary);">📸 ${i18n.t('memoryLane')}</h3>
          <p style="font-size: 14px; color: var(--text-muted);">${i18n.t('exploreMemories')}</p>
        </div>

        <div style="display: flex; flex-direction: column; gap: 16px;">
          ${photos.map(p => `
            <div class="elder-card" style="padding: 0; overflow: hidden;">
              <div style="width: 100%; height: 180px; overflow: hidden; position: relative;">
                <img src="${p.image}" alt="${p.title}" style="width: 100%; height: 100%; object-fit: cover;"/>
                <span style="position: absolute; bottom: 10px; right: 10px; background: rgba(0,0,0,0.7); color: #FFF; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 700;">${p.year}</span>
              </div>
              <div style="padding: 16px;">
                <h4 style="font-size: 18px; font-weight: 700; color: var(--primary-dark); margin-bottom: 4px;">${p.title}</h4>
                <p style="font-size: 14px; color: var(--text-muted); margin-bottom: 12px;">${p.note}</p>

                <div style="display: flex; gap: 10px;">
                  <button class="btn-elder btn-outline" onclick="speechEngine.speak('${p.title}. ${p.note}')" style="min-height: 44px; font-size: 14px;">
                    ${i18n.t('readStory')}
                  </button>
                  <button class="btn-elder btn-secondary" onclick="memoryLane.recordVoiceNote('${p.id}')" style="min-height: 44px; font-size: 14px;">
                    ${i18n.t('voiceNote')}
                  </button>
                </div>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  },

  recordVoiceNote(photoId) {
    speechEngine.speak("Listening for your story voice note. Speak now.");
    alert("🎙️ Recording Voice Note... Speak a memory about this photo.");
  }
};

window.memoryLane = memoryLane;
