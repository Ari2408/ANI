/* ==========================================================================
   Game 4: Word & Object Association Game
   ========================================================================== */

const wordAssociationGame = {
  pairs: [
    { item1: '☕ Cup', item2: '🫖 Teapot', category: 'Kitchen' },
    { item1: '👓 Glasses', item2: '📖 Book', category: 'Reading' },
    { item1: '🌧️ Rain', item2: '☂️ Umbrella', category: 'Weather' },
    { item1: '🌸 Flower', item2: '🐝 Honey Bee', category: 'Nature' },
    { item1: '🔑 Key', item2: '🔒 Lock', category: 'Home' },
    { item1: '👟 Shoes', item2: '🧦 Socks', category: 'Clothing' },
    { item1: '🌳 Tree', item2: '🍃 Leaf', category: 'Nature' },
    { item1: '🕯️ Candle', item2: '🔥 Matchbox', category: 'Home' }
  ],
  currentIndex: 0,
  score: 0,

  init(containerEl) {
    this.container = containerEl;
    this.currentIndex = 0;
    this.score = 0;
    this.renderQuestion();
  },

  renderQuestion() {
    const pair = this.pairs[this.currentIndex % this.pairs.length];
    const target = pair.item2;

    // Pick 2 wrong options
    const wrongOptions = this.pairs
      .filter(p => p.item2 !== target)
      .map(p => p.item2)
      .sort(() => Math.random() - 0.5)
      .slice(0, 2);

    const options = [target, ...wrongOptions].sort(() => Math.random() - 0.5);

    this.container.innerHTML = `
      <div class="game-play-area">
        <div class="game-status-bar">
          <button class="btn-elder btn-outline" style="padding: 6px 12px; font-size: 14px;" onclick="appRouter.navigate('games')">⬅ Back</button>
          <div class="status-item">⭐ Score: ${this.score}</div>
          <div class="status-item">Pair ${this.currentIndex + 1}</div>
        </div>

        <div class="elder-card" style="background: #FDF0E6; border: 2px solid #E59866; text-align: center; margin-bottom: 20px;">
          <p style="font-size: 16px; font-weight: 600; color: #5D4037; margin-bottom: 8px;">🔗 What goes best with:</p>
          <div style="display: inline-block; padding: 12px 24px; background: #FFF; border-radius: 16px; font-size: 32px; font-weight: 800; border: 2px solid rgba(229,152,102,0.5);">
            ${pair.item1}
          </div>
          <p style="font-size: 13px; color: #777; margin-top: 8px;">Category: ${pair.category}</p>
        </div>

        <div style="display: flex; flex-direction: column; gap: 12px;">
          ${options.map(opt => `
            <button class="word-opt-btn" onclick="wordAssociationGame.checkAnswer('${opt.replace(/'/g, "\\'")}')" style="padding: 18px; border-radius: 16px; font-size: 22px; font-weight: 700; border: 2px solid var(--border-color); background: #FFF; cursor: pointer; transition: all 0.2s;">
              ${opt}
            </button>
          `).join('')}
        </div>
      </div>
    `;
  },

  checkAnswer(selected) {
    const pair = this.pairs[this.currentIndex % this.pairs.length];
    const isCorrect = selected === pair.item2;

    if (isCorrect) {
      this.score += 10;
      if (window.aiEngine && aiEngine.recordGameSession) {
        aiEngine.recordGameSession('wordAssociation', this.score, true);
      }
      if (window.speechEngine && speechEngine.speak) {
        speechEngine.speak('Great Association! Ten points added.');
      }
    }

    this.currentIndex++;
    this.renderQuestion();
  }
};
