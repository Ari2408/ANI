/* ==========================================================================
   Daily Routine Recall Sequencing Game
   ========================================================================== */

const routineRecallGame = {
  container: null,
  correctSequence: [],
  currentItems: [],
  selectedItems: [],

  catalog: [
    { id: '1', text: '🌅 Morning Assam Tea / Filter Coffee', icon: '☕' },
    { id: '2', text: '💊 Take Morning Medicine (Donepezil)', icon: '💊' },
    { id: '3', text: '🥛 Morning Water Hydration', icon: '💧' },
    { id: '4', text: '🧩 Memory Game Brain Exercise', icon: '🧠' },
    { id: '5', text: '🚶 Evening Walk in Tea Garden', icon: '🌳' },
    { id: '6', text: '🌙 Night Pill & Rest', icon: '💤' }
  ],

  init(containerEl) {
    this.container = containerEl;
    this.correctSequence = [...this.catalog.slice(0, 4)]; // 4 daily steps
    this.currentItems = [...this.correctSequence].sort(() => Math.random() - 0.5);
    this.selectedItems = [];
    this.render();
    speechEngine.speak(i18n.t('routineTitle'));
  },

  render() {
    if (!this.container) return;

    this.container.innerHTML = `
      <div class="game-play-area">
        <div class="elder-card" style="text-align: center;">
          <h3 class="card-title" style="justify-content: center;">📅 ${i18n.t('routineTitle')}</h3>
          <p style="font-size: 15px; color: var(--text-muted);">${i18n.t('routineDesc')}</p>
        </div>

        <div class="routine-list" id="routineOptions">
          ${this.currentItems.map((item) => {
            const isSelected = this.selectedItems.some(s => s.id === item.id);
            const selectIndex = this.selectedItems.findIndex(s => s.id === item.id);

            return `
              <div class="routine-item ${isSelected ? 'selected' : ''}" onclick="routineRecallGame.tapItem('${item.id}')">
                <div style="display: flex; align-items: center; gap: 12px;">
                  <span style="font-size: 24px;">${item.icon}</span>
                  <span>${item.text}</span>
                </div>
                <div class="item-num">${isSelected ? selectIndex + 1 : '+'}</div>
              </div>
            `;
          }).join('')}
        </div>

        <button class="btn-elder btn-secondary" onclick="routineRecallGame.checkAnswer()" style="margin-top: 12px;">
          ✔️ Check Routine Sequence
        </button>
      </div>
    `;
  },

  tapItem(id) {
    audioSynth.playChime();
    const existingIdx = this.selectedItems.findIndex(s => s.id === id);
    if (existingIdx !== -1) {
      this.selectedItems.splice(existingIdx, 1);
    } else {
      const itemObj = this.currentItems.find(i => i.id === id);
      if (itemObj) this.selectedItems.push(itemObj);
    }
    this.render();
  },

  checkAnswer() {
    if (this.selectedItems.length < this.correctSequence.length) {
      speechEngine.speak("Please select all steps in order.");
      alert("Please tap all 4 routine steps in correct chronological order.");
      return;
    }

    let isCorrect = true;
    for (let i = 0; i < this.correctSequence.length; i++) {
      if (this.selectedItems[i].id !== this.correctSequence[i].id) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      audioSynth.playDhol();
      speechEngine.speak("Perfect! Routine sequence is completely correct.");
      aiEngine.processSessionResult('routine', { timeSec: 30, mistakes: 0, hintsUsed: 0, accuracyPct: 100 });
      alert("🌟 Excellent Recall! You placed your daily activities in perfect sequence.");
    } else {
      speechEngine.speak("Not quite right. Let's try again.");
      alert("Some steps are out of order. Remember: Morning Tea comes first, then Morning Pill, then Hydration, then Memory Exercise!");
      this.selectedItems = [];
      this.render();
    }
  }
};

window.routineRecallGame = routineRecallGame;
