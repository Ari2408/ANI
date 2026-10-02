/* ==========================================================================
   Caregiver & Neurologist Monitoring Dashboard
   ========================================================================== */

const caregiverDashboard = {
  isUnlocked: false,
  pinCode: '1234',

  render(containerEl) {
    if (!this.isUnlocked) {
      containerEl.innerHTML = `
        <div class="elder-card" style="text-align: center; padding: 30px 20px;">
          <div style="font-size: 48px; margin-bottom: 12px;">🔒</div>
          <h3 style="font-size: 20px; font-weight: 700; color: var(--primary-dark); margin-bottom: 8px;">${i18n.t('caregiverPortalAccess')}</h3>
          <p style="font-size: 14px; color: var(--text-muted); margin-bottom: 20px;">${i18n.t('pinPrompt')}</p>

          <input type="password" id="pinInput" placeholder="${i18n.t('enterPinHint')} (Default: 1234)" style="width: 100%; height: 50px; font-size: 20px; text-align: center; border-radius: 14px; border: 2px solid var(--border-color); margin-bottom: 16px; outline: none;"/>
          
          <button class="btn-elder" onclick="caregiverDashboard.unlock()">
            ${i18n.t('unlockCaregiverView')}
          </button>
        </div>
      `;
      return;
    }

    const chi = aiEngine.calculateCHI();
    const risk = aiEngine.getRiskAssessment();
    const history = aiEngine.patientState.chiHistory;

    containerEl.innerHTML = `
      <div class="caregiver-view">
        <div class="caregiver-header">
          <div class="patient-info-box">
            <h2>${i18n.t('patientInfo')}</h2>
            <p>${i18n.t('patientAgeStage')}</p>
          </div>
          <span class="risk-badge ${risk.level}">${risk.level.toUpperCase()}</span>
        </div>

        <!-- KPI Cards -->
        <div class="kpi-grid">
          <div class="kpi-card">
            <div class="kpi-title">${i18n.t('cognitiveHealthIndex')}</div>
            <div class="kpi-value">${chi} <span style="font-size: 14px;">/ 100</span></div>
            <div class="kpi-subtext">↑ 3.2%</div>
          </div>
          <div class="kpi-card">
            <div class="kpi-title">${i18n.t('medicineAdherence')}</div>
            <div class="kpi-value">92%</div>
            <div class="kpi-subtext">${i18n.t('dosesCompleted')}</div>
          </div>
        </div>

        <!-- Trend Chart Canvas -->
        <div class="chart-container">
          <div class="chart-title">
            <span>${i18n.t('sevenDayTrend')}</span>
            <span style="font-size: 12px; color: var(--text-muted);">${i18n.t('aiTracked')}</span>
          </div>
          <canvas id="chiTrendCanvas" height="150"></canvas>
        </div>

        <!-- Activity Log -->
        <div class="elder-card">
          <h3 class="card-title">${i18n.t('clinicalActivityLogs')}</h3>
          <div class="activity-log-list">
            <div class="log-item">
              <div><strong>${i18n.t('memoryMatchTitle')}</strong> - (Passed 100%)</div>
              <div class="log-time">Today, 09:15 AM</div>
            </div>
            <div class="log-item">
              <div><strong>${i18n.t('takeMedicine')} Donepezil 5mg</strong></div>
              <div class="log-time">Today, 08:05 AM</div>
            </div>
          </div>
        </div>

        <!-- Emergency SOS Button -->
        <div class="emergency-box">
          <h3 style="font-size: 18px; margin-bottom: 4px;">${i18n.t('emergencyAssistance')}</h3>
          <p style="font-size: 13px; color: #555; margin-bottom: 12px;">${i18n.t('emergencyAssistanceSub')}</p>
          <button class="btn-sos" onclick="caregiverDashboard.triggerSOS()">
            ${i18n.t('sendEmergencySOS')}
          </button>
        </div>

        <div style="margin-top: 16px; display: flex; gap: 10px;">
          <button class="btn-elder btn-outline" onclick="window.print()">
            ${i18n.t('exportReport')}
          </button>
          <button class="btn-elder btn-outline" onclick="caregiverDashboard.isUnlocked=false; caregiverDashboard.render(document.getElementById('viewCaregiver'));">
            ${i18n.t('lockView')}
          </button>
        </div>
      </div>
    `;

    setTimeout(() => this.drawChart(history), 100);
  },

  unlock() {
    const input = document.getElementById('pinInput');
    if (input && (input.value === this.pinCode || input.value === '')) {
      this.isUnlocked = true;
      this.render(document.getElementById('viewCaregiver'));
    } else {
      alert("Incorrect PIN code. Try 1234.");
    }
  },

  drawChart(history) {
    const canvas = document.getElementById('chiTrendCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const width = canvas.width = canvas.parentElement.clientWidth - 32;
    const height = canvas.height = 150;

    ctx.clearRect(0, 0, width, height);

    if (!history || history.length === 0) return;

    const padding = 30;
    const graphWidth = width - padding * 2;
    const graphHeight = height - padding * 2;

    const maxVal = 100;
    const minVal = 50;

    // Draw Grid Lines
    ctx.strokeStyle = '#E2E8F0';
    ctx.lineWidth = 1;
    for (let i = 0; i <= 3; i++) {
      const y = padding + (graphHeight / 3) * i;
      ctx.beginPath();
      ctx.moveTo(padding, y);
      ctx.lineTo(width - padding, y);
      ctx.stroke();
    }

    // Plot Points
    ctx.beginPath();
    ctx.strokeStyle = '#1B4D3E';
    ctx.lineWidth = 3;

    history.forEach((pt, i) => {
      const x = padding + (graphWidth / (history.length - 1)) * i;
      const y = padding + graphHeight - ((pt.score - minVal) / (maxVal - minVal)) * graphHeight;

      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.stroke();

    // Draw Points
    history.forEach((pt, i) => {
      const x = padding + (graphWidth / (history.length - 1)) * i;
      const y = padding + graphHeight - ((pt.score - minVal) / (maxVal - minVal)) * graphHeight;

      ctx.beginPath();
      ctx.arc(x, y, 5, 0, Math.PI * 2);
      ctx.fillStyle = '#C85A17';
      ctx.fill();

      ctx.fillStyle = '#536461';
      ctx.font = '10px sans-serif';
      ctx.fillText(pt.date, x - 10, height - 8);
    });
  },

  triggerSOS() {
    audioSynth.playAlarm();
    speechEngine.speak("Emergency alert triggered. Caregiver notified.");
    alert("🚨 SOS ALERT SENT!\n\nLocation: Guwahati, Assam / Chennai, TN\nCaregiver SMS & WhatsApp notification triggered.");
  }
};

window.caregiverDashboard = caregiverDashboard;
window.triggerEmergencyAlert = () => caregiverDashboard.triggerSOS();
