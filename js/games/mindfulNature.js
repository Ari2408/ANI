/* ==========================================================================
   Mindful Nature & Soundscape Room (Emotional Well-being)
   ========================================================================== */

const mindfulNatureGame = {
  container: null,
  activeSound: null,

  init(containerEl) {
    this.container = containerEl;
    this.render();
    speechEngine.speak(i18n.t('mindfulTitle'));
  },

  render() {
    if (!this.container) return;

    this.container.innerHTML = `
      <div class="game-play-area nature-room">
        <div class="nature-image-holder">
          <img src="assets/images/living_root_bridge.jpg" alt="Living Root Bridge" id="natureImg"/>
        </div>

        <h3 style="font-size: 22px; color: var(--primary-dark); margin-bottom: 4px;">🌿 ${i18n.t('mindfulTitle')}</h3>
        <p style="font-size: 15px; color: var(--text-muted); mb-3">${i18n.t('mindfulDesc')}</p>

        <div class="breathing-circle" id="breathCircle">
          <span>Breathe In...</span>
        </div>

        <div class="sound-controls">
          <button class="sound-btn ${this.activeSound === 'flute' ? 'active' : ''}" onclick="mindfulNatureGame.toggleSound('flute')">
            🪈 Bamboo Flute
          </button>
          <button class="sound-btn ${this.activeSound === 'rain' ? 'active' : ''}" onclick="mindfulNatureGame.toggleSound('rain')">
            🌧️ Rain in Sohra
          </button>
          <button class="sound-btn ${this.activeSound === 'river' ? 'active' : ''}" onclick="mindfulNatureGame.toggleSound('river')">
            🏞️ River Stream
          </button>
        </div>
      </div>
    `;

    this.startBreathingGuide();
  },

  startBreathingGuide() {
    const circle = document.getElementById('breathCircle');
    if (!circle) return;

    let inOut = true;
    setInterval(() => {
      if (circle) {
        circle.querySelector('span').textContent = inOut ? 'Breathe In...' : 'Breathe Out...';
        inOut = !inOut;
      }
    }, 4000);
  },

  toggleSound(type) {
    this.activeSound = this.activeSound === type ? null : type;
    this.render();

    if (this.activeSound === 'flute') {
      audioSynth.playFluteTone(440);
      setTimeout(() => audioSynth.playFluteTone(523.25), 800);
      setTimeout(() => audioSynth.playFluteTone(659.25), 1600);
    } else if (this.activeSound === 'rain' || this.activeSound === 'river') {
      audioSynth.playChime();
    }
  }
};

window.mindfulNatureGame = mindfulNatureGame;
