import React, { useEffect } from 'react';
import confetti from 'canvas-confetti';
import { Star, RotateCcw, Home, Sparkles } from 'lucide-react';
import { SessionSummary } from '../../services/api';
import { soundManager } from '../../utils/audio';

interface Props {
  summary: SessionSummary;
  onPlayAgain: () => void;
  onDone: () => void;
}

export const SessionSummaryScreen: React.FC<Props> = ({ summary, onPlayAgain, onDone }) => {
  useEffect(() => {
    // Launch celebratory confetti burst
    try {
      confetti({
        particleCount: 80,
        spread: 70,
        origin: { y: 0.6 }
      });
    } catch {
      // ignore
    }

    // Speak warm conclusion
    soundManager.speak(
      `${summary.warm_title}. ${summary.warm_subtitle} Thank you for exercising your memory today!`
    );

    return () => {
      soundManager.stopSpeech();
    };
  }, [summary]);

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 via-amber-50 to-orange-50/50 flex flex-col justify-between p-6 sm:p-12 text-slate-900 select-none">
      <div className="max-w-2xl mx-auto w-full text-center my-auto py-8">
        <div className="bg-white rounded-3xl p-8 sm:p-12 border-4 border-amber-200 shadow-2xl">
          {/* Smiling Stars Scale */}
          <div className="flex justify-center items-center gap-3 sm:gap-4 mb-8">
            {[1, 2, 3].map(starIndex => (
              <div
                key={starIndex}
                className={`p-3 rounded-full transition-transform transform ${
                  starIndex <= summary.stars
                    ? 'text-amber-400 fill-amber-400 scale-110 drop-shadow-md animate-bounce'
                    : 'text-slate-200 fill-slate-200'
                }`}
                style={{ animationDelay: `${starIndex * 150}ms` }}
              >
                <Star className="w-16 h-16 sm:w-20 sm:h-20 fill-current" />
              </div>
            ))}
          </div>

          {/* Warm Congratulatory Titles */}
          <h1 className="text-4xl sm:text-5xl font-black text-slate-900 mb-4 tracking-tight">
            {summary.warm_title}
          </h1>

          <p className="text-2xl sm:text-3xl text-slate-600 font-medium leading-relaxed mb-8">
            {summary.warm_subtitle}
          </p>

          <div className="inline-flex items-center gap-2 px-6 py-3 bg-amber-100 text-amber-900 rounded-full text-xl font-bold mb-10 shadow-xs">
            <Sparkles className="w-6 h-6 text-amber-600" />
            <span>{summary.total_rounds} Photo Memories Completed</span>
          </div>

          {/* Big Tactile Action Buttons */}
          <div className="flex flex-col sm:flex-row gap-5 justify-center">
            <button
              onClick={onPlayAgain}
              className="elder-touch-target flex-1 py-5 px-8 bg-emerald-600 hover:bg-emerald-700 active:bg-emerald-800 text-white font-extrabold text-2xl sm:text-3xl rounded-2xl shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-3 cursor-pointer"
            >
              <RotateCcw className="w-8 h-8" />
              <span>Play Again</span>
            </button>

            <button
              onClick={onDone}
              className="elder-touch-target flex-1 py-5 px-8 bg-slate-100 hover:bg-slate-200 active:bg-slate-300 text-slate-800 font-bold text-2xl sm:text-3xl rounded-2xl border-2 border-slate-300 transition-all flex items-center justify-center gap-3 cursor-pointer"
            >
              <Home className="w-8 h-8 text-slate-600" />
              <span>Done for Now</span>
            </button>
          </div>
        </div>
      </div>

      <div className="text-center text-slate-500 font-medium text-lg pb-2">
        Regular visual exercises help support healthy cognitive vitality
      </div>
    </div>
  );
};
