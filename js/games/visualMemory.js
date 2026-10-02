/* ==========================================================================
   Visual Memory Match Game (Cultural North East & Tamil Symbols)
   ========================================================================== */

const visualMemoryGame = {
  container: null,
  cards: [],
  flippedCards: [],
  matchedPairs: 0,
  totalPairs: 4,
  moves: 0,
  startTime: null,
  timerInterval: null,
  elapsedSec: 0,

  // Culturally rich card items (NER & Tamil motifs)
  cardCatalog: [
    { id: 'jaapi', name: 'Assam Jaapi Hat', icon: '👒', img: 'assets/images/bihu_dance.jpg' },
    { id: 'tanjore', name: 'Tamil Tanjore Art', icon: '🎨', img: 'assets/images/kaziranga.jpg' },
    { id: 'rhino', name: 'Kaziranga Rhino', icon: '🦏', img: 'assets/images/kaziranga.jpg' },
    { id: 'rootbridge', name: 'Living Root Bridge', icon: '🌉', img: 'assets/images/living_root_bridge.jpg' },
    { id: 'dhol', name: 'Bihu Dhol Drum', icon: '🥁', img: 'assets/images/bihu_dance.jpg' },
    { id: 'loktak', name: 'Loktak Phumdi Lake', icon: '🏞️', img: 'assets/images/kaziranga.jpg' },
    { id: 'tea', name: 'Assam Tea Leaf', icon: '🍃', img: 'assets/images/kaziranga.jpg' },
    { id: 'silk', name: 'Muga Silk Weave', icon: '🧵', img: 'assets/images/bihu_dance.jpg' }
  ],

  init(containerEl) {
    this.container = containerEl;
    this.resetGame();
  },

  resetGame() {
    const level = aiEngine.patientState.currentLevel || 1;
    this.totalPairs = level === 1 ? 3 : (level === 2 ? 4 : (level === 3 ? 6 : 8));
    this.flippedCards = [];
    this.matchedPairs = 0;
    this.moves = 0;
    this.elapsedSec = 0;
    if (this.timerInterval) clearInterval(this.timerInterval);

    // Pick pairs from catalog
    const selectedItems = this.cardCatalog.slice(0, this.totalPairs);
    const deck = [...selectedItems, ...selectedItems].map((item, idx) => ({
      ...item,
      uniqueId: idx
    }));

    // Shuffle deck
    deck.sort(() => Math.random() - 0.5);
    this.cards = deck;

    this.render();
    this.startTimer();
    speechEngine.speak(i18n.t('memoryMatchTitle'));
  },

  startTimer() {
    this.startTime = Date.now();
    this.timerInterval = setInterval(() => {
      this.elapsedSec++;
      const timerEl = document.getElementById('memoryTimer');
      if (timerEl) timerEl.textContent = `${this.elapsedSec}s`;
    }, 1000);
  },

  render() {
    if (!this.container) return;

    this.container.innerHTML = `
      <div class="game-play-area">
        <div class="game-status-bar">
          <div class="status-item">⏱️ <span id="memoryTimer">0s</span></div>
          <div class="status-item">🎯 level ${aiEngine.patientState.currentLevel}</div>
          <div class="status-item">✨ <span id="memoryScore">${this.matchedPairs}/${this.totalPairs}</span></div>
        </div>

        <div class="memory-grid ${this.totalPairs >= 6 ? 'grid-6' : 'grid-4'}">
          ${this.cards.map((card, idx) => `
            <div class="memory-card" data-index="${idx}" onclick="visualMemoryGame.flipCard(${idx})">
              <div class="memory-card-inner">
                <div class="memory-card-front">
                  <span>🌺</span>
                </div>
                <div class="memory-card-back">
                  <div style="font-size: 32px;">${card.icon}</div>
                  <span>${card.name}</span>
                </div>
              </div>
            </div>
          `).join('')}
        </div>

        <button class="btn-elder btn-outline" onclick="visualMemoryGame.resetGame()">
          🔄 ${i18n.t('routineTitle')}
        </button>
      </div>
    `;
  },

  flipCard(index) {
    if (this.flippedCards.length >= 2) return;
    const cardEl = this.container.querySelectorAll('.memory-card')[index];
    if (cardEl.classList.contains('flipped') || cardEl.classList.contains('matched')) return;

    audioSynth.playChime();
    cardEl.classList.add('flipped');
    this.flippedCards.push({ index, data: this.cards[index] });

    if (this.flippedCards.length === 2) {
      this.moves++;
      this.checkMatch();
    }
  },

  checkMatch() {
    const [c1, c2] = this.flippedCards;
    const cardsElements = this.container.querySelectorAll('.memory-card');

    if (c1.data.id === c2.data.id) {
      // Match found!
      setTimeout(() => {
        cardsElements[c1.index].classList.add('matched');
        cardsElements[c2.index].classList.add('matched');
        this.matchedPairs++;
        audioSynth.playDhol();

        const scoreEl = document.getElementById('memoryScore');
        if (scoreEl) scoreEl.textContent = `${this.matchedPairs}/${this.totalPairs}`;

        this.flippedCards = [];

        if (this.matchedPairs === this.totalPairs) {
          this.gameComplete();
        }
      }, 400);
    } else {
      // No match
      setTimeout(() => {
        cardsElements[c1.index].classList.remove('flipped');
        cardsElements[c2.index].classList.remove('flipped');
        this.flippedCards = [];
      }, 1000);
    }
  },

  gameComplete() {
    clearInterval(this.timerInterval);
    const accuracy = Math.round((this.totalPairs / this.moves) * 100);

    // AI Engine difficulty update
    const result = aiEngine.processSessionResult('memory', {
      timeSec: this.elapsedSec,
      mistakes: this.moves - this.totalPairs,
      hintsUsed: 0,
      accuracyPct: accuracy
    });

    audioSynth.playDhol();
    speechEngine.speak(`Great job! Completed in ${this.elapsedSec} seconds.`);

    setTimeout(() => {
      alert(`🎉 Wonderful Memory Session!\n\nCompleted in ${this.elapsedSec}s with ${accuracy}% accuracy.\nYour AI Cognitive Health Index is now: ${result.chi}`);
    }, 500);
  }
};

window.visualMemoryGame = visualMemoryGame;
