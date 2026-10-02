import { Router } from 'express';
import { db } from '../db.js';
export const playRouter = Router();
// Helper to shuffle array
function shuffle(array) {
    const arr = [...array];
    for (let i = arr.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
}
// GET /api/play/:elderId/session - Start a new game session
playRouter.get('/:elderId/session', (req, res) => {
    const elderId = String(req.params.elderId);
    const elder = db.prepare('SELECT * FROM elders WHERE id = ?').get(elderId);
    if (!elder) {
        return res.status(404).json({ error: 'Elder profile not found' });
    }
    // 1. Fetch active cards for this elder
    let cards = db.prepare('SELECT * FROM cards WHERE elder_id = ? AND is_active = 1').all(elderId);
    // Fallback: If this elder has no active cards yet, borrow active cards from other elders so the elder is never blocked!
    if (cards.length === 0) {
        cards = db.prepare('SELECT * FROM cards WHERE is_active = 1').all();
    }
    if (cards.length === 0) {
        return res.status(400).json({ error: 'No active picture cards available. Please add at least one card in the Caregiver Portal.' });
    }
    // Determine difficulty settings
    const difficulty = elder.difficulty_level || 'easy';
    let defaultDuration = 10;
    let maxChoices = 2;
    if (difficulty === 'easy') {
        defaultDuration = elder.reveal_duration_seconds || 12;
        maxChoices = 2; // 1 correct + 1 wrong
    }
    else if (difficulty === 'medium') {
        defaultDuration = elder.reveal_duration_seconds || 8;
        maxChoices = 3; // 1 correct + 2 wrong
    }
    else {
        defaultDuration = elder.reveal_duration_seconds || 6;
        maxChoices = 4; // 1 correct + 3 wrong
    }
    const roundsCount = Math.min(cards.length, elder.rounds_per_session || 5);
    const shuffledCards = shuffle(cards).slice(0, roundsCount);
    // Build rounds
    const rounds = shuffledCards.map(c => {
        let wrongChoices = [];
        try {
            wrongChoices = JSON.parse(c.wrong_choices);
        }
        catch {
            wrongChoices = [];
        }
        const wrongNeeded = Math.max(1, maxChoices - 1);
        const selectedWrong = shuffle(wrongChoices).slice(0, wrongNeeded);
        const allChoices = shuffle([c.correct_choice, ...selectedWrong]);
        return {
            card_id: c.id,
            photo_url: c.photo_url,
            question_prompt: c.question_prompt,
            choices: allChoices
        };
    });
    // Create session record
    const sessionId = 'sess-' + Date.now();
    const now = new Date().toISOString();
    db.prepare(`
    INSERT INTO sessions (id, elder_id, started_at, round_count)
    VALUES (?, ?, ?, ?)
  `).run(sessionId, elderId, now, rounds.length);
    res.json({
        session_id: sessionId,
        elder: {
            id: elder.id,
            display_name: elder.display_name,
            avatar_url: elder.avatar_url,
            difficulty_level: difficulty
        },
        reveal_duration_seconds: defaultDuration,
        round_count: rounds.length,
        rounds
    });
});
// POST /api/play/:elderId/session/:sessionId/answer - Submit answer for current round
playRouter.post('/:elderId/session/:sessionId/answer', (req, res) => {
    const sessionId = String(req.params.sessionId);
    const { card_id, selected_choice, response_time_ms } = req.body;
    if (!card_id || !selected_choice) {
        return res.status(400).json({ error: 'card_id and selected_choice are required' });
    }
    const card = db.prepare('SELECT * FROM cards WHERE id = ?').get(String(card_id));
    if (!card) {
        return res.status(404).json({ error: 'Card not found' });
    }
    const isCorrect = card.correct_choice.trim().toLowerCase() === selected_choice.trim().toLowerCase();
    const answerId = 'ans-' + Date.now() + '-' + Math.round(Math.random() * 1000);
    const now = new Date().toISOString();
    db.prepare(`
    INSERT INTO session_answers (
      id, session_id, card_id, selected_choice, is_correct, response_time_ms, answered_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(answerId, sessionId, String(card_id), String(selected_choice), isCorrect ? 1 : 0, Math.max(200, parseInt(response_time_ms || 2000, 10)), now);
    res.json({
        is_correct: isCorrect,
        correct_choice: card.correct_choice,
        gentle_message: isCorrect
            ? ['Wonderful!', 'Spot on!', 'Splendid memory!', 'Great job!'][Math.floor(Math.random() * 4)]
            : ['Good try!', 'Almost had it!', 'Nice thinking!', 'Keep going!'][Math.floor(Math.random() * 4)]
    });
});
// POST /api/play/:elderId/session/:sessionId/complete - Mark session finished
playRouter.post('/:elderId/session/:sessionId/complete', (req, res) => {
    const sessionId = String(req.params.sessionId);
    const elderId = String(req.params.elderId);
    const now = new Date().toISOString();
    db.prepare('UPDATE sessions SET completed_at = ? WHERE id = ?').run(now, sessionId);
    // Compute session stats
    const answers = db.prepare('SELECT * FROM session_answers WHERE session_id = ?').all(sessionId);
    const totalRounds = answers.length;
    const correctCount = answers.filter(a => a.is_correct === 1).length;
    const avgResponseTimeMs = totalRounds > 0
        ? Math.round(answers.reduce((acc, a) => acc + a.response_time_ms, 0) / totalRounds)
        : 0;
    let stars = 3;
    let warmTitle = 'Wonderful Memory Session!';
    let warmSubtitle = 'You exercised your visual memory wonderfully today.';
    if (totalRounds > 0) {
        const ratio = correctCount / totalRounds;
        if (ratio >= 0.8) {
            stars = 3;
            warmTitle = 'Magnificent Effort!';
            warmSubtitle = 'You did splendidly observing the details!';
        }
        else if (ratio >= 0.5) {
            stars = 2;
            warmTitle = 'Well Done!';
            warmSubtitle = 'Every game helps keep your mind sharp and active.';
        }
        else {
            stars = 1;
            warmTitle = 'Great Try Today!';
            warmSubtitle = 'Thank you for playing! Practice makes each day brighter.';
        }
    }
    res.json({
        summary: {
            session_id: sessionId,
            elder_id: elderId,
            total_rounds: totalRounds,
            correct_count: correctCount,
            stars,
            warm_title: warmTitle,
            warm_subtitle: warmSubtitle,
            avg_response_time_sec: Number((avgResponseTimeMs / 1000).toFixed(1))
        }
    });
});
