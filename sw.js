const CACHE_NAME = 'smritijyoti-v1';
const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './manifest.json',
  './css/mobile.css',
  './css/games.css',
  './css/caregiver.css',
  './js/i18n.js',
  './js/speech.js',
  './js/aiEngine.js',
  './js/storage.js',
  './js/audioSynth.js',
  './js/games/visualMemory.js',
  './js/games/routineRecall.js',
  './js/games/patternSorting.js',
  './js/games/mindfulNature.js',
  './js/components/patientView.js',
  './js/components/scheduleReminders.js',
  './js/components/memoryLane.js',
  './js/components/caregiverDashboard.js',
  './js/app.js',
  './assets/images/kaziranga.jpg',
  './assets/images/living_root_bridge.jpg',
  './assets/images/bihu_dance.jpg'
];

self.addEventListener('install', (evt) => {
  evt.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('Caching offline app assets');
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );
});

self.addEventListener('activate', (evt) => {
  evt.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) return caches.delete(key);
        })
      );
    })
  );
});

self.addEventListener('fetch', (evt) => {
  evt.respondWith(
    caches.match(evt.request).then((cachedResponse) => {
      return cachedResponse || fetch(evt.request).catch(() => {
        return caches.match('./index.html');
      });
    })
  );
});
