/* ==========================================================================
   Mobile Offline Data Persistence Layer (LocalStorage / IndexedDB)
   ========================================================================== */

const appStorage = {
  PREFIX: 'smritijyoti_',

  get(key, defaultValue = null) {
    try {
      const item = localStorage.getItem(this.PREFIX + key);
      return item ? JSON.parse(item) : defaultValue;
    } catch (e) {
      console.warn('LocalStorage Read Error:', e);
      return defaultValue;
    }
  },

  set(key, value) {
    try {
      localStorage.setItem(this.PREFIX + key, JSON.stringify(value));
    } catch (e) {
      console.warn('LocalStorage Write Error:', e);
    }
  },

  saveAIState(aiState) {
    this.set('ai_state', aiState);
  },

  loadAIState() {
    return this.get('ai_state', null);
  },

  saveReminders(reminders) {
    this.set('reminders', reminders);
  },

  loadReminders() {
    return this.get('reminders', [
      { id: 'm1', type: 'medicine', title: 'Donepezil 5mg', time: '08:00 AM', completed: true, dosage: '1 tablet after breakfast' },
      { id: 'm2', type: 'medicine', title: 'Memantine 10mg', time: '02:00 PM', completed: false, dosage: '1 tablet with water' },
      { id: 'm3', type: 'medicine', title: 'Multivitamin', time: '08:00 PM', completed: false, dosage: '1 tablet after dinner' },
      { id: 'a1', type: 'appointment', title: 'Neurologist Consultation (Dr. Barua)', time: 'Tomorrow 11:00 AM', completed: false, location: 'Guwahati Civil Hospital' }
    ]);
  },

  saveHydration(intake) {
    this.set('hydration_today', intake);
  },

  loadHydration() {
    return this.get('hydration_today', 5); // Default 5 glasses consumed
  },

  saveMemoryLane(photos) {
    this.set('memory_photos', photos);
  },

  loadMemoryLane() {
    return this.get('memory_photos', [
      { id: 'p1', title: 'Assam Tea Garden Walk', year: '1984', image: 'assets/images/kaziranga.jpg', note: 'Visited Sibsagar tea gardens with family.' },
      { id: 'p2', title: 'Living Root Bridge Visit', year: '1992', image: 'assets/images/living_root_bridge.jpg', note: 'Trip to Cherrapunji in Meghalaya.' },
      { id: 'p3', title: 'Rongali Bihu Festival', year: '2005', image: 'assets/images/bihu_dance.jpg', note: 'Dancing Bihu with village elders in Guwahati.' }
    ]);
  }
};

window.appStorage = appStorage;
