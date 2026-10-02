/* ==========================================================================
   Voice Assistant & Web Speech API Engine
   Supports SpeechSynthesis (TTS) and SpeechRecognition (Voice Commands)
   ========================================================================== */

const speechEngine = {
  synth: window.speechSynthesis,
  recognition: null,
  isListening: false,

  // Map app language code to Web Speech BCP 47 language code
  langCodeMap: {
    ta: 'ta-IN',
    as: 'as-IN',
    bn: 'bn-IN',
    mni: 'hi-IN', // fallback for Manipur
    lus: 'en-IN',
    kha: 'en-IN',
    nag: 'hi-IN',
    en: 'en-US'
  },

  init() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (SpeechRecognition) {
      this.recognition = new SpeechRecognition();
      this.recognition.continuous = false;
      this.recognition.interimResults = false;
      
      this.recognition.onresult = (event) => {
        const transcript = event.results[0][0].transcript.toLowerCase();
        console.log('Voice Command Received:', transcript);
        this.processVoiceCommand(transcript);
      };

      this.recognition.onend = () => {
        this.isListening = false;
        const fab = document.getElementById('voiceFab');
        if (fab) fab.classList.remove('listening');
      };

      this.recognition.onerror = (err) => {
        console.warn('Speech recognition error:', err);
        this.isListening = false;
        const fab = document.getElementById('voiceFab');
        if (fab) fab.classList.remove('listening');
      };
    }
  },

  speak(text, onEndCallback) {
    if (!window.speechSynthesis) return;
    this.synth = window.speechSynthesis;
    this.synth.cancel(); // Stop ongoing speech
    if (this.synth.paused) {
      try { this.synth.resume(); } catch (_) {}
    }

    const utterance = new SpeechSynthesisUtterance(text);
    const speechLang = (window.i18n && this.langCodeMap[i18n.currentLang]) ? this.langCodeMap[i18n.currentLang] : 'ta-IN';
    utterance.lang = speechLang;
    utterance.rate = 0.85; // Slightly slower for elderly dementia comprehension
    utterance.pitch = 1.0;

    // Try finding exact regional voice if available
    try {
      const voices = this.synth.getVoices();
      if (voices && voices.length > 0) {
        const matchedVoice = voices.find(v => v.lang && (v.lang.startsWith(speechLang.slice(0, 2)) || v.lang.includes(speechLang)));
        if (matchedVoice) {
          utterance.voice = matchedVoice;
        }
      }
    } catch (_) {}

    if (onEndCallback) {
      utterance.onend = onEndCallback;
    }

    this.synth.speak(utterance);
  },

  toggleListen() {
    if (!this.recognition) {
      this.speak(i18n.t('voiceAssistantPrompt'));
      alert(i18n.t('voiceAssistantPrompt'));
      return;
    }

    const fab = document.getElementById('voiceFab');

    if (this.isListening) {
      this.recognition.stop();
      this.isListening = false;
      if (fab) fab.classList.remove('listening');
    } else {
      try {
        const speechLang = this.langCodeMap[i18n.currentLang] || 'ta-IN';
        this.recognition.lang = speechLang;
        this.recognition.start();
        this.isListening = true;
        if (fab) fab.classList.add('listening');
        this.speak(i18n.t('voiceAssistantPrompt'));
      } catch (e) {
        console.error('Speech Recognition start error:', e);
      }
    }
  },

  processVoiceCommand(command) {
    if (command.includes('game') || command.includes('விளையாட்டு') || command.includes('খেল')) {
      appRouter.navigate('games');
      this.speak(i18n.t('dailyGames'));
    } else if (command.includes('medicine') || command.includes('மருந்து') || command.includes('দৰব')) {
      appRouter.navigate('schedule');
      this.speak(i18n.t('takeMedicine'));
    } else if (command.includes('home') || command.includes('முகப்பு') || command.includes('মুখ্য')) {
      appRouter.navigate('home');
      this.speak(i18n.t('welcomeMessage'));
    } else if (command.includes('help') || command.includes('உதவி') || command.includes('সহায়')) {
      this.speak('Emergency call feature activated. Alerting caregiver.');
      if (window.triggerEmergencyAlert) window.triggerEmergencyAlert();
    } else {
      this.speak('Command recognized: ' + command);
    }
  }
};
