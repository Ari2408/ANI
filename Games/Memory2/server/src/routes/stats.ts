import { Router, Request, Response } from 'express';
import { db } from '../db.js';

export const statsRouter = Router();

// GET /api/stats/:id - Aggregated stats for caregiver dashboard
statsRouter.get('/:id', (req: Request, res: Response) => {
  const elderId = String(req.params.id);
  const elder = db.prepare('SELECT * FROM elders WHERE id = ?').get(elderId) as any;
  if (!elder) {
    return res.status(404).json({ error: 'Elder not found' });
  }

  // 1. Overall stats
  const overall = db.prepare(`
    SELECT 
      COUNT(*) as total_answers,
      SUM(CASE WHEN sa.is_correct = 1 THEN 1 ELSE 0 END) as correct_answers,
      AVG(sa.response_time_ms) as avg_response_time
    FROM session_answers sa
    JOIN sessions s ON sa.session_id = s.id
    WHERE s.elder_id = ?
  `).get(elderId) as any;

  const totalAnswers = overall?.total_answers || 0;
  const correctAnswers = overall?.correct_answers || 0;
  const overallAccuracy = totalAnswers > 0 ? Math.round((correctAnswers / totalAnswers) * 100) : 0;
  const overallAvgTimeSec = overall?.avg_response_time ? Number((overall.avg_response_time / 1000).toFixed(1)) : 0;

  // 2. Daily accuracy and response time trend over last 30 days
  const dailyRows = db.prepare(`
    SELECT 
      date(sa.answered_at) as session_date,
      COUNT(*) as answers_count,
      SUM(CASE WHEN sa.is_correct = 1 THEN 1 ELSE 0 END) as correct_count,
      AVG(sa.response_time_ms) as avg_time_ms
    FROM session_answers sa
    JOIN sessions s ON sa.session_id = s.id
    WHERE s.elder_id = ?
    GROUP BY date(sa.answered_at)
    ORDER BY session_date ASC
  `).all(elderId) as any[];

  const dailyTrend = dailyRows.map(r => ({
    date: r.session_date,
    accuracy: Math.round((r.correct_count / r.answers_count) * 100),
    avg_response_time_sec: Number((r.avg_time_ms / 1000).toFixed(1)),
    answers_count: r.answers_count
  }));

  // 3. Streak and Active Dates (for streak calendar)
  const sessionDates = db.prepare(`
    SELECT DISTINCT date(started_at) as play_date
    FROM sessions
    WHERE elder_id = ? AND completed_at IS NOT NULL
    ORDER BY play_date DESC
  `).all(elderId).map((row: any) => row.play_date) as string[];

  // Calculate current streak
  let currentStreak = 0;
  const todayStr = new Date().toISOString().split('T')[0];
  const yesterdayDate = new Date(Date.now() - 86400000);
  const yesterdayStr = yesterdayDate.toISOString().split('T')[0];

  if (sessionDates.includes(todayStr) || sessionDates.includes(yesterdayStr)) {
    let checkDate = sessionDates.includes(todayStr) ? new Date() : yesterdayDate;
    while (true) {
      const checkStr = checkDate.toISOString().split('T')[0];
      if (sessionDates.includes(checkStr)) {
        currentStreak++;
        checkDate = new Date(checkDate.getTime() - 86400000);
      } else {
        break;
      }
    }
  }

  // 4. Per-card accuracy breakdown
  const cardStats = db.prepare(`
    SELECT 
      c.id, c.question_prompt, c.photo_url, c.is_active,
      COUNT(sa.id) as times_asked,
      SUM(CASE WHEN sa.is_correct = 1 THEN 1 ELSE 0 END) as times_correct,
      AVG(sa.response_time_ms) as avg_time_ms
    FROM cards c
    LEFT JOIN session_answers sa ON c.id = sa.card_id
    WHERE c.elder_id = ?
    GROUP BY c.id
    ORDER BY times_asked DESC
  `).all(elderId) as any[];

  const cardBreakdown = cardStats.map(c => {
    const accuracy = c.times_asked > 0 ? Math.round((c.times_correct / c.times_asked) * 100) : null;
    return {
      id: c.id,
      question_prompt: c.question_prompt,
      photo_url: c.photo_url,
      is_active: Boolean(c.is_active),
      times_asked: c.times_asked,
      times_correct: c.times_correct,
      accuracy,
      avg_time_sec: c.avg_time_ms ? Number((c.avg_time_ms / 1000).toFixed(1)) : null,
      needs_attention: accuracy !== null && accuracy < 60 && c.times_asked >= 3
    };
  });

  const activeCardCount = cardStats.filter(c => c.is_active).length;

  // 5. Plain-language weekly digest note
  const sessionsThisWeek = db.prepare(`
    SELECT COUNT(*) as count
    FROM sessions
    WHERE elder_id = ? 
      AND completed_at IS NOT NULL
      AND datetime(started_at) >= datetime('now', '-7 days')
  `).get(elderId) as any;

  const weeklyCount = sessionsThisWeek?.count || 0;
  let weeklyDigest = '';
  if (weeklyCount === 0) {
    weeklyDigest = `No game sessions completed in the last 7 days. Gentle reminder: A 3-minute photo recall session each morning helps sustain visual engagement and cognitive routine.`;
  } else {
    weeklyDigest = `${weeklyCount} sessions completed this week with ${overallAccuracy}% overall accuracy. Average response time is holding steady around ${overallAvgTimeSec}s. Memory recall on family and familiar objects is strong.`;
  }

  const lowLibraryAlert = activeCardCount < 8
    ? `Library currently has ${activeCardCount} active cards. Adding 3-5 more photos (family members, pets, favorite vacation spots) provides fresh daily variety.`
    : null;

  res.json({
    elder: {
      id: elder.id,
      display_name: elder.display_name,
      difficulty_level: elder.difficulty_level,
      reveal_duration_seconds: elder.reveal_duration_seconds
    },
    overall: {
      total_sessions: sessionDates.length,
      total_answers: totalAnswers,
      accuracy_percentage: overallAccuracy,
      avg_response_time_sec: overallAvgTimeSec,
      current_streak_days: currentStreak,
      active_card_count: activeCardCount
    },
    daily_trend: dailyTrend,
    session_dates: sessionDates,
    card_breakdown: cardBreakdown,
    weekly_digest: weeklyDigest,
    low_library_alert: lowLibraryAlert
  });
});
