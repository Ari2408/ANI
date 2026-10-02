/* ==========================================================================
   Adaptive AI/ML Cognitive Performance Engine
   Calculates Cognitive Health Index (CHI) and Dynamic Difficulty Adjustment (DDA)
   ========================================================================== */

const aiEngine = {
  // Current patient dynamic state
  patientState: {
    currentLevel: 1, // Level 1 (Easy) to Level 5 (Hard)
    memoryScore: 82,
    attentionScore: 78,
    routineScore: 85,
    adherenceRate: 90,
    chiHistory: [
      { date: 'Sep 1', score: 76 },
      { date: 'Sep 2', score: 79 },
      { date: 'Sep 3', score: 81 },
      { date: 'Sep 4', score: 80 },
      { date: 'Sep 5', score: 84 },
      { date: 'Sep 6', score: 82 },
      { date: 'Sep 7', score: 85 }
    ]
  },

  /**
   * Calculate overall Cognitive Health Index (CHI)
   * Formula: CHI = (0.4 * Memory) + (0.3 * Attention) + (0.2 * Routine) + (0.1 * Adherence)
   */
  calculateCHI() {
    const s = this.patientState;
    const chi = Math.round(
      (0.4 * s.memoryScore) + 
      (0.3 * s.attentionScore) + 
      (0.2 * s.routineScore) + 
      (0.1 * s.adherenceRate)
    );
    return Math.min(100, Math.max(0, chi));
  },

  /**
   * Evaluate game session performance and perform Dynamic Difficulty Adjustment (DDA)
   * @param {string} gameType - 'memory', 'routine', 'pattern'
   * @param {object} session - { timeSec, mistakes, hintsUsed, accuracyPct }
   */
  processSessionResult(gameType, session) {
    const { timeSec, mistakes, hintsUsed, accuracyPct } = session;

    // Update specific cognitive domain score based on accuracy and speed
    if (gameType === 'memory') {
      const delta = accuracyPct > 80 ? 3 : (accuracyPct < 50 ? -3 : 0);
      this.patientState.memoryScore = Math.min(100, Math.max(30, this.patientState.memoryScore + delta));
    } else if (gameType === 'routine') {
      const delta = mistakes === 0 ? 4 : (mistakes > 2 ? -2 : 1);
      this.patientState.routineScore = Math.min(100, Math.max(30, this.patientState.routineScore + delta));
    } else if (gameType === 'pattern') {
      const delta = accuracyPct > 75 ? 3 : -2;
      this.patientState.attentionScore = Math.min(100, Math.max(30, this.patientState.attentionScore + delta));
    }

    // Adaptive Level Scaling logic
    if (accuracyPct >= 85 && mistakes <= 1) {
      if (this.patientState.currentLevel < 5) {
        this.patientState.currentLevel++;
        console.log('AI Difficulty Increased to Level:', this.patientState.currentLevel);
      }
    } else if (accuracyPct < 50 || mistakes >= 4) {
      if (this.patientState.currentLevel > 1) {
        this.patientState.currentLevel--;
        console.log('AI Difficulty Adjusted Down to Level:', this.patientState.currentLevel);
      }
    }

    // Record CHI in history
    const todayLabel = new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    const newChi = this.calculateCHI();
    
    const lastEntry = this.patientState.chiHistory[this.patientState.chiHistory.length - 1];
    if (lastEntry && lastEntry.date === todayLabel) {
      lastEntry.score = newChi;
    } else {
      this.patientState.chiHistory.push({ date: todayLabel, score: newChi });
      if (this.patientState.chiHistory.length > 14) this.patientState.chiHistory.shift();
    }

    // Save state to Storage
    if (window.appStorage) {
      window.appStorage.saveAIState(this.patientState);
    }

    return {
      chi: newChi,
      newLevel: this.patientState.currentLevel,
      recommendation: this.getAIRecommendation(newChi)
    };
  },

  /**
   * Determine Cognitive Risk Level (Low, Moderate, High)
   */
  getRiskAssessment() {
    const chi = this.calculateCHI();
    if (chi >= 75) {
      return { level: 'low', text: i18n.t('riskLow'), color: 'var(--success)' };
    } else if (chi >= 55) {
      return { level: 'moderate', text: i18n.t('riskModerate'), color: 'var(--warning)' };
    } else {
      return { level: 'high', text: i18n.t('riskHigh'), color: 'var(--danger)' };
    }
  },

  getAIRecommendation(chi) {
    if (chi >= 80) {
      return "Excellent cognitive engagement today! Keep up the daily memory games.";
    } else if (chi >= 60) {
      return "Good focus. Recommend 10 minutes of nature soundscape guided breathing.";
    } else {
      return "Noticeable reaction latency today. Recommend lighter 4-card memory match and caregiver check-in.";
    }
  }
};
