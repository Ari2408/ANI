import React, { useEffect, useState } from 'react';
import { Elder, ElderStats, api } from '../../services/api';
import {
  TrendingUp,
  Clock,
  Flame,
  Layers,
  Sparkles,
  AlertTriangle,
  Calendar,
  CheckCircle2,
  XCircle,
  Plus,
  Loader2
} from 'lucide-react';

interface Props {
  elder: Elder;
  onNavigateToLibrary: () => void;
  onOpenAddCard: () => void;
}

export const DashboardView: React.FC<Props> = ({ elder, onNavigateToLibrary, onOpenAddCard }) => {
  const [stats, setStats] = useState<ElderStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, [elder.id]);

  const loadStats = async () => {
    setLoading(true);
    try {
      const data = await api.getStats(elder.id);
      setStats(data);
    } catch (err) {
      console.error('Failed to load stats', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-16">
        <Loader2 className="w-10 h-10 text-blue-600 animate-spin" />
      </div>
    );
  }

  if (!stats) return null;

  const { overall, daily_trend, weekly_digest, low_library_alert, card_breakdown, session_dates } = stats;

  // Prepare 30-day streak dates
  const today = new Date();
  const past30Days: { dateStr: string; dayNum: number; played: boolean }[] = [];
  for (let i = 29; i >= 0; i--) {
    const d = new Date(today.getTime() - i * 24 * 60 * 60 * 1000);
    const dateStr = d.toISOString().split('T')[0];
    past30Days.push({
      dateStr,
      dayNum: d.getDate(),
      played: session_dates.includes(dateStr)
    });
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
      {/* Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2">
        <div className="flex items-center gap-4">
          <img
            src={elder.avatar_url}
            alt={elder.display_name}
            className="w-14 h-14 rounded-full object-cover border-2 border-amber-300 shadow-sm bg-amber-100"
          />
          <div>
            <h1 className="text-2xl sm:text-3xl font-black text-slate-900">
              {elder.display_name}'s Cognitive Overview
            </h1>
            <p className="text-slate-500 text-sm font-medium">
              Difficulty: <span className="capitalize font-bold text-slate-700">{elder.difficulty_level}</span> • Viewing Time: <span className="font-bold text-slate-700">{elder.reveal_duration_seconds}s</span>
            </p>
          </div>
        </div>

        <button
          onClick={onOpenAddCard}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white rounded-xl text-sm font-bold shadow-sm transition-all cursor-pointer self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          <span>Add New Photo Card</span>
        </button>
      </div>

      {/* Plain Language Weekly Digest Banner */}
      <div className="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-2xl p-5 sm:p-6 shadow-xs flex items-start gap-4">
        <div className="p-3 bg-blue-600 text-white rounded-xl shadow-xs shrink-0">
          <Sparkles className="w-6 h-6" />
        </div>
        <div className="flex-1">
          <h2 className="text-base font-bold text-blue-950 mb-1">
            Caregiver Weekly Summary Note
          </h2>
          <p className="text-slate-700 text-sm sm:text-base leading-relaxed">
            {weekly_digest}
          </p>
        </div>
      </div>

      {/* Low Library Size Warning Banner if < 8 cards */}
      {low_library_alert && (
        <div className="bg-amber-50 border border-amber-300 rounded-2xl p-5 shadow-xs flex items-start justify-between gap-4">
          <div className="flex items-start gap-3">
            <AlertTriangle className="w-6 h-6 text-amber-600 shrink-0 mt-0.5" />
            <div>
              <h3 className="text-sm font-bold text-amber-900">
                Card Variety Recommendation
              </h3>
              <p className="text-amber-800 text-sm mt-0.5">
                {low_library_alert}
              </p>
            </div>
          </div>
          <button
            onClick={onNavigateToLibrary}
            className="text-xs font-bold text-amber-900 bg-amber-200 hover:bg-amber-300 px-3 py-1.5 rounded-lg shrink-0 cursor-pointer"
          >
            Manage Cards
          </button>
        </div>
      )}

      {/* Key Metrics Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
        {/* Accuracy */}
        <div className="bg-white rounded-2xl p-5 sm:p-6 border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-bold uppercase tracking-wider">Overall Accuracy</span>
            <TrendingUp className="w-5 h-5 text-emerald-500" />
          </div>
          <div className="text-3xl sm:text-4xl font-black text-slate-900">
            {overall.accuracy_percentage}%
          </div>
          <div className="text-xs text-slate-500 mt-2">
            Across {overall.total_answers} memory questions answered
          </div>
        </div>

        {/* Response Time */}
        <div className="bg-white rounded-2xl p-5 sm:p-6 border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-bold uppercase tracking-wider">Avg Response Time</span>
            <Clock className="w-5 h-5 text-blue-500" />
          </div>
          <div className="text-3xl sm:text-4xl font-black text-slate-900">
            {overall.avg_response_time_sec}s
          </div>
          <div className="text-xs text-slate-500 mt-2">
            Proxy for cognitive ease and confidence
          </div>
        </div>

        {/* Current Streak */}
        <div className="bg-white rounded-2xl p-5 sm:p-6 border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-bold uppercase tracking-wider">Daily Streak</span>
            <Flame className="w-5 h-5 text-amber-500" />
          </div>
          <div className="text-3xl sm:text-4xl font-black text-slate-900">
            {overall.current_streak_days} {overall.current_streak_days === 1 ? 'day' : 'days'}
          </div>
          <div className="text-xs text-slate-500 mt-2">
            {overall.total_sessions} total completed game sessions
          </div>
        </div>

        {/* Active Cards */}
        <div className="bg-white rounded-2xl p-5 sm:p-6 border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-bold uppercase tracking-wider">Active Photos</span>
            <Layers className="w-5 h-5 text-indigo-500" />
          </div>
          <div className="text-3xl sm:text-4xl font-black text-slate-900">
            {overall.active_card_count}
          </div>
          <div className="text-xs text-slate-500 mt-2">
            In active rotation for {elder.display_name}
          </div>
        </div>
      </div>

      {/* 30-Day Activity Streak Calendar */}
      <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Calendar className="w-5 h-5 text-slate-600" />
            <h2 className="text-lg font-bold text-slate-900">
              30-Day Session Consistency Calendar
            </h2>
          </div>
          <span className="text-xs font-semibold text-slate-500">
            Green = completed game session
          </span>
        </div>

        <div className="grid grid-cols-6 sm:grid-cols-10 md:grid-cols-15 gap-2">
          {past30Days.map((item, idx) => (
            <div
              key={idx}
              title={`${item.dateStr}: ${item.played ? 'Session completed' : 'No session'}`}
              className={`p-2.5 rounded-xl text-center border text-xs font-bold transition-all ${
                item.played
                  ? 'bg-emerald-500 border-emerald-600 text-white shadow-xs'
                  : 'bg-slate-50 border-slate-200 text-slate-400'
              }`}
            >
              {item.dayNum}
            </div>
          ))}
        </div>
      </div>

      {/* Interactive Charts Section: Accuracy & Response Time */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Accuracy Trend Chart */}
        <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs flex flex-col justify-between">
          <div className="mb-4">
            <h2 className="text-lg font-bold text-slate-900">
              Accuracy Trend Over Time (%)
            </h2>
            <p className="text-xs text-slate-500">
              Daily percentage of questions answered correctly
            </p>
          </div>

          <div className="h-60 w-full flex items-end gap-3 pt-6 border-b border-slate-200">
            {daily_trend.length === 0 ? (
              <div className="text-slate-400 text-sm italic m-auto">
                No session history recorded yet.
              </div>
            ) : (
              daily_trend.map((pt, i) => (
                <div key={i} className="flex-1 flex flex-col items-center group relative">
                  {/* Tooltip */}
                  <div className="absolute -top-10 opacity-0 group-hover:opacity-100 bg-slate-900 text-white text-xs py-1 px-2 rounded font-bold transition-opacity pointer-events-none z-10 whitespace-nowrap shadow-md">
                    {pt.date}: {pt.accuracy}% ({pt.answers_count} questions)
                  </div>
                  {/* Bar/Pillar */}
                  <div
                    style={{ height: `${Math.max(12, (pt.accuracy / 100) * 190)}px` }}
                    className="w-full max-w-[28px] bg-emerald-500 group-hover:bg-emerald-600 rounded-t-lg transition-all"
                  />
                  <span className="text-[10px] text-slate-500 mt-2 font-medium">
                    {pt.date.slice(5)}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Response Time Trend Chart */}
        <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs flex flex-col justify-between">
          <div className="mb-4">
            <h2 className="text-lg font-bold text-slate-900">
              Average Response Time (Seconds)
            </h2>
            <p className="text-xs text-slate-500">
              Time taken per answer — lower/steady indicates comfort
            </p>
          </div>

          <div className="h-60 w-full flex items-end gap-3 pt-6 border-b border-slate-200">
            {daily_trend.length === 0 ? (
              <div className="text-slate-400 text-sm italic m-auto">
                No session history recorded yet.
              </div>
            ) : (
              daily_trend.map((pt, i) => {
                // Scale assuming normal response 2s to 8s
                const heightPercent = Math.min(100, Math.max(15, (pt.avg_response_time_sec / 8) * 100));
                return (
                  <div key={i} className="flex-1 flex flex-col items-center group relative">
                    <div className="absolute -top-10 opacity-0 group-hover:opacity-100 bg-slate-900 text-white text-xs py-1 px-2 rounded font-bold transition-opacity pointer-events-none z-10 whitespace-nowrap shadow-md">
                      {pt.date}: {pt.avg_response_time_sec}s
                    </div>
                    <div
                      style={{ height: `${(heightPercent / 100) * 190}px` }}
                      className="w-full max-w-[28px] bg-blue-500 group-hover:bg-blue-600 rounded-t-lg transition-all"
                    />
                    <span className="text-[10px] text-slate-500 mt-2 font-medium">
                      {pt.date.slice(5)}
                    </span>
                  </div>
                );
              })
            )}
          </div>
        </div>
      </div>

      {/* Per-Card Performance Breakdown */}
      <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-xs">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-lg font-bold text-slate-900">
              Per-Card Memory Diagnostic
            </h2>
            <p className="text-xs text-slate-500">
              Track which specific images and questions are well-remembered vs. frequently missed
            </p>
          </div>

          <button
            onClick={onNavigateToLibrary}
            className="text-sm font-bold text-blue-600 hover:text-blue-800 cursor-pointer"
          >
            Manage Library →
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-slate-200 text-slate-500 font-bold text-xs uppercase">
              <tr>
                <th className="py-3 px-3">Photo & Question</th>
                <th className="py-3 px-3">Times Seen</th>
                <th className="py-3 px-3">Accuracy</th>
                <th className="py-3 px-3">Avg Time</th>
                <th className="py-3 px-3 text-right">Caregiver Guidance</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {card_breakdown.map(card => (
                <tr key={card.id} className="hover:bg-slate-50/80 transition-colors">
                  <td className="py-3 px-3 flex items-center gap-3">
                    <img
                      src={card.photo_url}
                      alt="Thumbnail"
                      className="w-12 h-12 rounded-xl object-cover border border-slate-200 bg-slate-100 shrink-0"
                    />
                    <div className="max-w-md">
                      <p className="font-bold text-slate-900 line-clamp-1">
                        {card.question_prompt}
                      </p>
                      {!card.is_active && (
                        <span className="text-xs text-rose-500 font-semibold">(Archived in Trash)</span>
                      )}
                    </div>
                  </td>

                  <td className="py-3 px-3 font-semibold text-slate-700">
                    {card.times_asked} times
                  </td>

                  <td className="py-3 px-3 font-bold">
                    {card.accuracy !== null ? (
                      <span
                        className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold ${
                          card.accuracy >= 75
                            ? 'bg-emerald-100 text-emerald-800'
                            : card.accuracy >= 50
                            ? 'bg-amber-100 text-amber-800'
                            : 'bg-rose-100 text-rose-800'
                        }`}
                      >
                        {card.accuracy >= 75 ? <CheckCircle2 className="w-3.5 h-3.5" /> : <XCircle className="w-3.5 h-3.5" />}
                        {card.accuracy}%
                      </span>
                    ) : (
                      <span className="text-slate-400 text-xs italic">Not seen yet</span>
                    )}
                  </td>

                  <td className="py-3 px-3 font-medium text-slate-600">
                    {card.avg_time_sec !== null ? `${card.avg_time_sec}s` : '—'}
                  </td>

                  <td className="py-3 px-3 text-right">
                    {card.needs_attention ? (
                      <span className="inline-flex items-center gap-1 text-xs font-bold text-amber-700 bg-amber-100 px-2.5 py-1 rounded-full">
                        <AlertTriangle className="w-3.5 h-3.5" /> Review question wording
                      </span>
                    ) : card.accuracy !== null && card.accuracy >= 80 ? (
                      <span className="text-xs font-semibold text-emerald-700">
                        Well retained
                      </span>
                    ) : (
                      <span className="text-xs text-slate-400 font-medium">Standard</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
