import { Router } from 'express';
import multer from 'multer';
import path from 'node:path';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import { db } from '../db.js';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const UPLOADS_DIR = path.resolve(__dirname, '../../../uploads');
if (!fs.existsSync(UPLOADS_DIR)) {
    fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}
// Multer disk storage configuration
const storage = multer.diskStorage({
    destination: (_req, _file, cb) => {
        cb(null, UPLOADS_DIR);
    },
    filename: (_req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, 'photo-' + uniqueSuffix + ext);
    }
});
const upload = multer({
    storage,
    limits: { fileSize: 15 * 1024 * 1024 }, // 15MB
    fileFilter: (_req, file, cb) => {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        }
        else {
            cb(new Error('Only image files (JPG, PNG, WebP) are allowed'));
        }
    }
});
export const cardsRouter = Router();
// POST /api/cards/upload - upload photo
cardsRouter.post('/upload', upload.single('photo'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No image file uploaded' });
    }
    const fileUrl = `/uploads/${req.file.filename}`;
    res.json({
        photo_url: fileUrl,
        thumbnail_url: fileUrl
    });
});
// GET /api/elders/:elderId/cards - list cards for an elder
cardsRouter.get('/elder/:elderId', (req, res) => {
    const elderId = String(req.params.elderId);
    const statusFilter = req.query.status; // 'active' | 'trash' | 'all'
    let sql = 'SELECT * FROM cards WHERE elder_id = ?';
    const params = [elderId];
    if (statusFilter === 'trash') {
        sql += ' AND is_active = 0';
    }
    else if (statusFilter === 'active' || !statusFilter) {
        sql += ' AND is_active = 1';
    }
    sql += ' ORDER BY created_at DESC';
    const cards = db.prepare(sql).all(...params);
    // Attach card accuracy telemetry from session_answers
    const enriched = cards.map(c => {
        const stats = db.prepare(`
      SELECT 
        COUNT(*) as times_seen,
        SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as times_correct,
        AVG(response_time_ms) as avg_time_ms
      FROM session_answers
      WHERE card_id = ?
    `).get(String(c.id));
        const timesSeen = stats?.times_seen || 0;
        const timesCorrect = stats?.times_correct || 0;
        const accuracy = timesSeen > 0 ? Math.round((timesCorrect / timesSeen) * 100) : null;
        let wrongChoicesArray = [];
        try {
            wrongChoicesArray = JSON.parse(c.wrong_choices);
        }
        catch {
            wrongChoicesArray = [];
        }
        return {
            ...c,
            wrong_choices: wrongChoicesArray,
            is_active: Boolean(c.is_active),
            times_seen: timesSeen,
            times_correct: timesCorrect,
            accuracy,
            avg_time_sec: stats?.avg_time_ms ? Number((stats.avg_time_ms / 1000).toFixed(1)) : null
        };
    });
    res.json({ cards: enriched });
});
// POST /api/cards - create a new card
cardsRouter.post('/', (req, res) => {
    const { elder_id, photo_url, thumbnail_url, question_prompt, correct_choice, wrong_choices } = req.body;
    if (!elder_id || !photo_url || !question_prompt || !correct_choice) {
        return res.status(400).json({ error: 'Missing required card fields (elder_id, photo, question, correct answer)' });
    }
    const caregiver = db.prepare('SELECT id FROM caregivers LIMIT 1').get();
    const caregiver_id = caregiver?.id || 'c1';
    let formattedWrongChoices;
    if (Array.isArray(wrong_choices)) {
        const cleaned = wrong_choices.map(s => String(s).trim()).filter(s => s.length > 0);
        if (cleaned.length === 0) {
            return res.status(400).json({ error: 'At least one wrong answer choice is required' });
        }
        formattedWrongChoices = JSON.stringify(cleaned);
    }
    else {
        formattedWrongChoices = JSON.stringify(['Other choice']);
    }
    const id = 'card-' + Date.now();
    const now = new Date().toISOString();
    db.prepare(`
    INSERT INTO cards (
      id, elder_id, caregiver_id, photo_url, thumbnail_url,
      question_prompt, correct_choice, wrong_choices, is_active, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
  `).run(id, elder_id, caregiver_id, photo_url, thumbnail_url || photo_url, question_prompt.trim(), correct_choice.trim(), formattedWrongChoices, now, now);
    const created = db.prepare('SELECT * FROM cards WHERE id = ?').get(id);
    res.status(201).json({
        card: {
            ...created,
            wrong_choices: JSON.parse(created.wrong_choices),
            is_active: true
        }
    });
});
// PATCH /api/cards/:id - edit existing card
cardsRouter.patch('/:id', (req, res) => {
    const id = String(req.params.id);
    const card = db.prepare('SELECT * FROM cards WHERE id = ?').get(id);
    if (!card) {
        return res.status(404).json({ error: 'Card not found' });
    }
    const { photo_url, thumbnail_url, question_prompt, correct_choice, wrong_choices } = req.body;
    const newPhoto = photo_url !== undefined ? photo_url : card.photo_url;
    const newThumb = thumbnail_url !== undefined ? thumbnail_url : (photo_url || card.thumbnail_url);
    const newQuestion = question_prompt !== undefined ? question_prompt.trim() : card.question_prompt;
    const newCorrect = correct_choice !== undefined ? correct_choice.trim() : card.correct_choice;
    let newWrong = card.wrong_choices;
    if (wrong_choices !== undefined) {
        if (Array.isArray(wrong_choices)) {
            const cleaned = wrong_choices.map(s => String(s).trim()).filter(s => s.length > 0);
            newWrong = JSON.stringify(cleaned);
        }
    }
    const now = new Date().toISOString();
    db.prepare(`
    UPDATE cards SET
      photo_url = ?,
      thumbnail_url = ?,
      question_prompt = ?,
      correct_choice = ?,
      wrong_choices = ?,
      updated_at = ?
    WHERE id = ?
  `).run(newPhoto, newThumb, newQuestion, newCorrect, newWrong, now, id);
    const updated = db.prepare('SELECT * FROM cards WHERE id = ?').get(id);
    res.json({
        card: {
            ...updated,
            wrong_choices: JSON.parse(updated.wrong_choices),
            is_active: Boolean(updated.is_active)
        }
    });
});
// DELETE /api/cards/:id - Soft-delete (sets is_active = 0)
cardsRouter.delete('/:id', (req, res) => {
    const id = String(req.params.id);
    const now = new Date().toISOString();
    db.prepare('UPDATE cards SET is_active = 0, updated_at = ? WHERE id = ?').run(now, id);
    res.json({ success: true, message: 'Card moved to trash (soft-deleted)' });
});
// POST /api/cards/:id/restore - Restore soft-deleted card
cardsRouter.post('/:id/restore', (req, res) => {
    const id = String(req.params.id);
    const now = new Date().toISOString();
    db.prepare('UPDATE cards SET is_active = 1, updated_at = ? WHERE id = ?').run(now, id);
    res.json({ success: true, message: 'Card restored to active rotation' });
});
// DELETE /api/cards/:id/permanent - Permanent hard delete
cardsRouter.delete('/:id/permanent', (req, res) => {
    const id = String(req.params.id);
    db.prepare('DELETE FROM cards WHERE id = ?').run(id);
    res.json({ success: true, message: 'Card permanently removed' });
});
