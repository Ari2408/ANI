import { Router } from 'express';
import { db } from '../db.js';
import { AVATAR_ELEANOR } from '../seedData.js';
export const eldersRouter = Router();
// GET /api/elders - list elders with quick metrics
eldersRouter.get('/', (req, res) => {
    const elders = db.prepare(`
    SELECT e.*, 
      (SELECT COUNT(*) FROM cards c WHERE c.elder_id = e.id AND c.is_active = 1) as active_card_count,
      (SELECT COUNT(*) FROM sessions s WHERE s.elder_id = e.id) as total_sessions
    FROM elders e
    ORDER BY e.created_at ASC
  `).all();
    // Attach recent 7-day accuracy for each elder
    const enriched = elders.map(elder => {
        const stats = db.prepare(`
      SELECT 
        COUNT(*) as total_answers,
        SUM(CASE WHEN sa.is_correct = 1 THEN 1 ELSE 0 END) as correct_answers,
        AVG(sa.response_time_ms) as avg_response_time
      FROM session_answers sa
      JOIN sessions s ON sa.session_id = s.id
      WHERE s.elder_id = ?
    `).get(String(elder.id));
        const total = stats?.total_answers || 0;
        const correct = stats?.correct_answers || 0;
        const accuracy = total > 0 ? Math.round((correct / total) * 100) : 0;
        return {
            ...elder,
            has_pin: Boolean(elder.pin_code && elder.pin_code.trim().length > 0),
            pin_code: elder.pin_code ? '****' : null,
            recent_accuracy: accuracy,
            total_answers: total,
            avg_response_time_sec: stats?.avg_response_time ? Number((stats.avg_response_time / 1000).toFixed(1)) : null
        };
    });
    res.json({ elders: enriched });
});
// GET /api/elders/:id - get single elder
eldersRouter.get('/:id', (req, res) => {
    const id = String(req.params.id);
    const elder = db.prepare('SELECT * FROM elders WHERE id = ?').get(id);
    if (!elder) {
        return res.status(404).json({ error: 'Elder profile not found' });
    }
    res.json({
        elder: {
            ...elder,
            has_pin: Boolean(elder.pin_code && elder.pin_code.trim().length > 0)
        }
    });
});
// POST /api/elders - create elder
eldersRouter.post('/', (req, res) => {
    const { display_name, birth_year, avatar_url, pin_code, difficulty_level, reveal_duration_seconds, rounds_per_session } = req.body;
    if (!display_name) {
        return res.status(400).json({ error: 'Display name is required' });
    }
    const caregiver = db.prepare('SELECT id FROM caregivers LIMIT 1').get();
    const caregiver_id = caregiver?.id || 'c1';
    const id = 'elder-' + Date.now();
    const now = new Date().toISOString();
    db.prepare(`
    INSERT INTO elders (
      id, caregiver_id, display_name, birth_year, avatar_url, pin_code,
      difficulty_level, reveal_duration_seconds, rounds_per_session, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(id, caregiver_id, display_name.trim(), birth_year ? parseInt(birth_year, 10) : null, avatar_url || AVATAR_ELEANOR, pin_code ? pin_code.trim() : null, difficulty_level || 'easy', reveal_duration_seconds ? parseInt(reveal_duration_seconds, 10) : 10, rounds_per_session ? parseInt(rounds_per_session, 10) : 5, now);
    const created = db.prepare('SELECT * FROM elders WHERE id = ?').get(id);
    res.status(201).json({ elder: created });
});
// PATCH /api/elders/:id - update elder settings
eldersRouter.patch('/:id', (req, res) => {
    const id = String(req.params.id);
    const elder = db.prepare('SELECT * FROM elders WHERE id = ?').get(id);
    if (!elder) {
        return res.status(404).json({ error: 'Elder not found' });
    }
    const { display_name, birth_year, avatar_url, pin_code, difficulty_level, reveal_duration_seconds, rounds_per_session } = req.body;
    const newDisplayName = display_name !== undefined ? display_name : elder.display_name;
    const newBirthYear = birth_year !== undefined ? (birth_year ? parseInt(birth_year, 10) : null) : elder.birth_year;
    const newAvatar = avatar_url !== undefined ? avatar_url : elder.avatar_url;
    const newPin = pin_code !== undefined ? (pin_code ? pin_code.trim() : null) : elder.pin_code;
    const newDifficulty = difficulty_level !== undefined ? difficulty_level : elder.difficulty_level;
    const newDuration = reveal_duration_seconds !== undefined ? parseInt(reveal_duration_seconds, 10) : elder.reveal_duration_seconds;
    const newRounds = rounds_per_session !== undefined ? parseInt(rounds_per_session, 10) : elder.rounds_per_session;
    db.prepare(`
    UPDATE elders SET
      display_name = ?,
      birth_year = ?,
      avatar_url = ?,
      pin_code = ?,
      difficulty_level = ?,
      reveal_duration_seconds = ?,
      rounds_per_session = ?
    WHERE id = ?
  `).run(newDisplayName, newBirthYear, newAvatar, newPin, newDifficulty, newDuration, newRounds, id);
    const updated = db.prepare('SELECT * FROM elders WHERE id = ?').get(id);
    res.json({ elder: updated });
});
// DELETE /api/elders/:id - delete elder profile and related data
eldersRouter.delete('/:id', (req, res) => {
    const id = String(req.params.id);
    db.prepare('DELETE FROM elders WHERE id = ?').run(id);
    res.json({ success: true, message: 'Elder profile removed' });
});
// POST /api/elders/:id/verify-pin - verify 4-digit PIN
eldersRouter.post('/:id/verify-pin', (req, res) => {
    const id = String(req.params.id);
    const { pin } = req.body;
    const elder = db.prepare('SELECT pin_code FROM elders WHERE id = ?').get(id);
    if (!elder) {
        return res.status(404).json({ error: 'Elder not found' });
    }
    if (!elder.pin_code || elder.pin_code.trim() === '') {
        return res.json({ valid: true });
    }
    const isValid = elder.pin_code.trim() === (pin || '').trim();
    res.json({ valid: isValid });
});
