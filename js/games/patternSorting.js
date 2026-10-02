/* ==========================================================================
   Loom Pattern & Craft Recognition Game (Attention & Focus)
   ========================================================================== */

const patternSortingGame = {
  container: null,
  currentTarget: null,
  options: [],

  patterns: [
    { id: 'p1', name: 'Assam Muga Silk Diamond Motif', icon: '🔹', svgShape: '<rect x="15" y="15" width="30" height="30" transform="rotate(45 30 30)" fill="#D4AF37"/>' },
    { id: 'p2', name: 'Tanjore Lotus Craft', icon: '🪷', svgShape: '<circle cx="30" cy="30" r="20" fill="#E07A38"/><circle cx="30" cy="30" r="10" fill="#FFF"/>' },
    { id: 'p3', name: 'Naga Tribal Weave Triangle', icon: '🔺', svgShape: '<polygon points="30,10 10,50 50,50" fill="#C85A17"/>' },
    { id: 'p4', name: 'Meitei Silk Star Motif', icon: '⭐', svgShape: '<polygon points="30,5 38,20 55,22 42,35 46,52 30,43 14,52 18,35 5,22 22,20" fill="#1B4D3E"/>' }
  ],

  init(containerEl) {
    this.container = containerEl;
    this.nextQuestion();
  },

  nextQuestion() {
    const targetIdx = Math.floor(Math.random() * this.patterns.length);
    this.currentTarget = this.patterns[targetIdx];
    this.options = [...this.patterns].sort(() => Math.random() - 0.5);
    this.render();
    speechEngine.speak(i18n.t('patternTitle'));
  },

  render() {
    if (!this.container) return;

    this.container.innerHTML = `
      <div class="game-play-area">
        <div class="pattern-target-box">
          <h4>🧵 ${i18n.t('patternTitle')}</h4>
          <p style="margin-bottom: 12px;">Find the exact matching weave pattern below:</p>
          <div style="background: #FFF; width: 90px; height: 90px; border-radius: 50%; margin: 0 auto; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 10px rgba(0,0,0,0.1);">
            <svg width="60" height="60" viewBox="0 0 60 60">
              ${this.currentTarget.svgShape}
            </svg>
          </div>
          <p style="margin-top: 8px; font-weight: 700; color: var(--primary-dark);">${this.currentTarget.name}</p>
        </div>

        <div class="pattern-options-grid">
          ${this.options.map(opt => `
            <div class="pattern-option-card" onclick="patternSortingGame.selectOption('${opt.id}')">
              <svg width="50" height="50" viewBox="0 0 60 60">
                ${opt.svgShape}
              </svg>
              <p style="font-size: 13px; font-weight: 700; margin-top: 6px;">${opt.name}</p>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  },

  selectOption(id) {
    if (id === this.currentTarget.id) {
      audioSynth.playDhol();
      speechEngine.speak("Correct pattern matched!");
      aiEngine.processSessionResult('pattern', { timeSec: 15, mistakes: 0, hintsUsed: 0, accuracyPct: 100 });
      alert("✨ Perfect Pattern Match! Great attention to visual details.");
      this.nextQuestion();
    } else {
      audioSynth.playChime();
      speechEngine.speak("Try looking closely at the shapes.");
      alert("Not a match. Take your time to compare the shapes.");
    }
  }
};

window.patternSortingGame = patternSortingGame;
