import { DatabaseSync } from 'node:sqlite';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { AVATAR_ELEANOR, AVATAR_ARTHUR, SAMPLE_CARD_IMAGES } from './seedData.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DB_PATH = path.resolve(__dirname, '../memory_snap.db');

export const db = new DatabaseSync(DB_PATH);

// Initialize Tables & Foreign Keys
db.exec(`
  PRAGMA foreign_keys = ON;

  CREATE TABLE IF NOT EXISTS caregivers (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    full_name TEXT NOT NULL,
    created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS elders (
    id TEXT PRIMARY KEY,
    caregiver_id TEXT NOT NULL REFERENCES caregivers(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    birth_year INTEGER,
    avatar_url TEXT,
    pin_code TEXT,
    difficulty_level TEXT DEFAULT 'easy',
    reveal_duration_seconds INTEGER DEFAULT 10,
    rounds_per_session INTEGER DEFAULT 5,
    created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS cards (
    id TEXT PRIMARY KEY,
    elder_id TEXT REFERENCES elders(id) ON DELETE CASCADE,
    caregiver_id TEXT NOT NULL REFERENCES caregivers(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    thumbnail_url TEXT,
    question_prompt TEXT NOT NULL,
    correct_choice TEXT NOT NULL,
    wrong_choices TEXT NOT NULL,
    is_active INTEGER DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    elder_id TEXT NOT NULL REFERENCES elders(id) ON DELETE CASCADE,
    started_at TEXT NOT NULL,
    completed_at TEXT,
    round_count INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS session_answers (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    card_id TEXT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    selected_choice TEXT NOT NULL,
    is_correct INTEGER NOT NULL,
    response_time_ms INTEGER NOT NULL,
    answered_at TEXT NOT NULL
  );
`);

export function initDatabaseSeed() {
  const caregiverCount = db.prepare('SELECT COUNT(*) as count FROM caregivers').get() as { count: number };
  if (caregiverCount && caregiverCount.count > 0) {
    return; // Already seeded
  }

  console.log('[DB] Seeding initial database with sample elder profiles, caregiver, and curated cards...');

  const now = new Date().toISOString();
  const caregiverId = 'c1';

  // 1. Caregiver
  db.prepare(`
    INSERT INTO caregivers (id, email, password_hash, full_name, created_at)
    VALUES (?, ?, ?, ?, ?)
  `).run(caregiverId, 'demo@memorysnap.com', 'demo123', 'Sarah Jenkins (Daughter)', now);

  // 2. Elders
  const elder1Id = 'e1';
  db.prepare(`
    INSERT INTO elders (id, caregiver_id, display_name, birth_year, avatar_url, pin_code, difficulty_level, reveal_duration_seconds, rounds_per_session, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(elder1Id, caregiverId, 'Eleanor Vance', 1944, AVATAR_ELEANOR, null, 'easy', 10, 5, now);

  const elder2Id = 'e2';
  db.prepare(`
    INSERT INTO elders (id, caregiver_id, display_name, birth_year, avatar_url, pin_code, difficulty_level, reveal_duration_seconds, rounds_per_session, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(elder2Id, caregiverId, 'Arthur Vance', 1941, AVATAR_ARTHUR, '1234', 'medium', 8, 5, now);

  // 3. Curated Starter Cards
  const starterCards = [
    {
      id: 'card-1',
      elder_id: elder1Id,
      photo_url: SAMPLE_CARD_IMAGES.goldenDog,
      thumbnail_url: SAMPLE_CARD_IMAGES.goldenDog,
      question_prompt: 'What kind of pet is lying on the green grass?',
      correct_choice: 'Golden dog',
      wrong_choices: JSON.stringify(['Black cat', 'Brown rabbit', 'Colorful parrot'])
    },
    {
      id: 'card-2',
      elder_id: elder1Id,
      photo_url: SAMPLE_CARD_IMAGES.redTeapot,
      thumbnail_url: SAMPLE_CARD_IMAGES.redTeapot,
      question_prompt: 'What color was the teapot on the wooden table?',
      correct_choice: 'Red',
      wrong_choices: JSON.stringify(['Blue', 'Yellow', 'Silver'])
    },
    {
      id: 'card-3',
      elder_id: elder1Id,
      photo_url: SAMPLE_CARD_IMAGES.sunflowers,
      thumbnail_url: SAMPLE_CARD_IMAGES.sunflowers,
      question_prompt: 'Which tall flowers were growing in the sunny garden?',
      correct_choice: 'Sunflowers',
      wrong_choices: JSON.stringify(['Red roses', 'Purple tulips', 'White daisies'])
    },
    {
      id: 'card-4',
      elder_id: elder1Id,
      photo_url: SAMPLE_CARD_IMAGES.vintageCar,
      thumbnail_url: SAMPLE_CARD_IMAGES.vintageCar,
      question_prompt: 'What color was the classic vintage convertible car?',
      correct_choice: 'Turquoise / Light Blue',
      wrong_choices: JSON.stringify(['Cherry Red', 'Dark Black', 'Bright Orange'])
    },
    {
      id: 'card-5',
      elder_id: elder1Id,
      photo_url: SAMPLE_CARD_IMAGES.fruitBowl,
      thumbnail_url: SAMPLE_CARD_IMAGES.fruitBowl,
      question_prompt: 'How many yellow bananas were in the fruit bowl?',
      correct_choice: 'Two bananas',
      wrong_choices: JSON.stringify(['Five bananas', 'No bananas', 'One orange'])
    },
    {
      id: 'card-6',
      elder_id: elder1Id,
      photo_url: SAMPLE_CARD_IMAGES.redCardinal,
      thumbnail_url: SAMPLE_CARD_IMAGES.redCardinal,
      question_prompt: 'What type of bird was perched on top of the snowy birdhouse?',
      correct_choice: 'Red cardinal',
      wrong_choices: JSON.stringify(['Blue jay', 'Grey pigeon', 'Woodpecker'])
    }
  ];

  // Insert cards for Eleanor
  for (const card of starterCards) {
    db.prepare(`
      INSERT INTO cards (id, elder_id, caregiver_id, photo_url, thumbnail_url, question_prompt, correct_choice, wrong_choices, is_active, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
    `).run(card.id, card.elder_id, caregiverId, card.photo_url, card.thumbnail_url, card.question_prompt, card.correct_choice, card.wrong_choices, now, now);
  }

  // Also share cards for Arthur with new IDs
  for (let i = 0; i < starterCards.length; i++) {
    const card = starterCards[i];
    db.prepare(`
      INSERT INTO cards (id, elder_id, caregiver_id, photo_url, thumbnail_url, question_prompt, correct_choice, wrong_choices, is_active, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
    `).run(`card-arthur-${i + 1}`, elder2Id, caregiverId, card.photo_url, card.thumbnail_url, card.question_prompt, card.correct_choice, card.wrong_choices, now, now);
  }

  // 4. Seed Historical Sessions for Eleanor (last 10 days) so trends & charts are rich immediately!
  const dayMs = 24 * 60 * 60 * 1000;
  const historyConfigs = [
    { daysAgo: 9, correct: 4, total: 5, avgTime: 4800 },
    { daysAgo: 8, correct: 5, total: 5, avgTime: 4500 },
    { daysAgo: 7, correct: 4, total: 5, avgTime: 4600 },
    { daysAgo: 6, correct: 5, total: 5, avgTime: 4200 },
    { daysAgo: 4, correct: 4, total: 5, avgTime: 3900 },
    { daysAgo: 3, correct: 5, total: 5, avgTime: 3700 },
    { daysAgo: 2, correct: 5, total: 5, avgTime: 3500 },
    { daysAgo: 1, correct: 5, total: 5, avgTime: 3400 }
  ];

  historyConfigs.forEach((conf, idx) => {
    const sessionDate = new Date(Date.now() - conf.daysAgo * dayMs);
    const sessionId = `hist-session-${idx + 1}`;
    db.prepare(`
      INSERT INTO sessions (id, elder_id, started_at, completed_at, round_count)
      VALUES (?, ?, ?, ?, ?)
    `).run(sessionId, elder1Id, sessionDate.toISOString(), new Date(sessionDate.getTime() + 120000).toISOString(), conf.total);

    for (let r = 0; r < conf.total; r++) {
      const card = starterCards[r % starterCards.length];
      const isCorrect = r < conf.correct ? 1 : 0;
      const selected = isCorrect ? card.correct_choice : JSON.parse(card.wrong_choices)[0];
      const resTime = conf.avgTime + Math.floor((Math.random() - 0.5) * 600);

      db.prepare(`
        INSERT INTO session_answers (id, session_id, card_id, selected_choice, is_correct, response_time_ms, answered_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(`ans-${sessionId}-${r}`, sessionId, card.id, selected, isCorrect, resTime, new Date(sessionDate.getTime() + (r + 1) * 20000).toISOString());
    }
  });

  console.log('[DB] Seeding completed successfully.');
}
