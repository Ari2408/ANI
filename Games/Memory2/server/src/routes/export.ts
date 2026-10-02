import { Router, Request, Response } from 'express';
import { db } from '../db.js';

export const exportRouter = Router();

// GET /api/elders/:id/export/csv - Download raw CSV export
exportRouter.get('/:id/csv', (req: Request, res: Response) => {
  const elderId = String(req.params.id);
  const elder = db.prepare('SELECT * FROM elders WHERE id = ?').get(elderId) as any;
  if (!elder) {
    return res.status(404).send('Elder profile not found');
  }

  const answers = db.prepare(`
    SELECT 
      sa.id as answer_id,
      s.id as session_id,
      sa.answered_at,
      c.question_prompt,
      sa.selected_choice,
      c.correct_choice,
      sa.is_correct,
      sa.response_time_ms,
      e.difficulty_level
    FROM session_answers sa
    JOIN sessions s ON sa.session_id = s.id
    JOIN cards c ON sa.card_id = c.id
    JOIN elders e ON s.elder_id = e.id
    WHERE s.elder_id = ?
    ORDER BY sa.answered_at DESC
  `).all(elderId) as any[];

  // Build CSV content
  const headers = ['Answer Timestamp', 'Session ID', 'Question Prompt', 'Elder Choice', 'Correct Answer', 'Is Correct', 'Response Time (ms)', 'Difficulty'];
  
  const escapeCsv = (str: string) => `"${(str || '').replace(/"/g, '""')}"`;
  
  const rows = answers.map(a => [
    escapeCsv(a.answered_at),
    escapeCsv(a.session_id),
    escapeCsv(a.question_prompt),
    escapeCsv(a.selected_choice),
    escapeCsv(a.correct_choice),
    a.is_correct === 1 ? 'CORRECT' : 'INCORRECT',
    a.response_time_ms,
    escapeCsv(a.difficulty_level)
  ].join(','));

  const csvContent = [headers.join(','), ...rows].join('\r\n');
  const filename = `MemorySnap_${elder.display_name.replace(/\s+/g, '_')}_Progress_${new Date().toISOString().split('T')[0]}.csv`;

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  res.send(csvContent);
});

// GET /api/elders/:id/export/summary - Formatted report data for print / doctor view
exportRouter.get('/:id/summary', (req: Request, res: Response) => {
  const elderId = String(req.params.id);
  const elder = db.prepare('SELECT * FROM elders WHERE id = ?').get(elderId) as any;
  if (!elder) {
    return res.status(404).json({ error: 'Elder not found' });
  }

  const sessions = db.prepare(`
    SELECT s.id, s.started_at, s.completed_at, s.round_count,
      COUNT(sa.id) as answers_count,
      SUM(CASE WHEN sa.is_correct = 1 THEN 1 ELSE 0 END) as correct_count,
      AVG(sa.response_time_ms) as avg_time
    FROM sessions s
    LEFT JOIN session_answers sa ON s.id = sa.session_id
    WHERE s.elder_id = ? AND s.completed_at IS NOT NULL
    GROUP BY s.id
    ORDER BY s.started_at DESC
    LIMIT 15
  `).all(elderId) as any[];

  res.json({
    elder,
    report_generated_at: new Date().toISOString(),
    sessions: sessions.map(s => ({
      ...s,
      accuracy: s.answers_count > 0 ? Math.round((s.correct_count / s.answers_count) * 100) : 0,
      avg_time_sec: s.avg_time ? Number((s.avg_time / 1000).toFixed(1)) : 0
    }))
  });
});
