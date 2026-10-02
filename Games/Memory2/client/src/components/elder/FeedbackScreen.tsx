import React, { useEffect } from 'react';
import { CheckCircle2, Heart, Sparkles } from 'lucide-react';
import { soundManager } from '../../utils/audio';

interface Props {
  isCorrect: boolean;
  gentleMessage: string;
  correctChoice: string;
  selectedChoice: string;
  onAdvance: () => void;
}

export const FeedbackScreen: React.FC<Props> = ({
  isCorrect,
  gentleMessage,
  correctChoice,
  selectedChoice,
  onAdvance
}) => {
  useEffect(() => {
    // Play gentle audio sound
    if (isCorrect) {
      soundManager.playCorrectChime();
    } else {
      soundManager.playGentleTryChime();
    }

    // Auto-advance after 2 seconds
    const timer = setTimeout(() => {
      onAdvance();
    }, 2100);

    return () => clearTimeout(timer);
  }, [isCorrect, onAdvance]);

  return (
    <div
      className={`min-h-screen flex flex-col items-center justify-center p-6 text-center select-none transition-colors duration-300 ${
        isCorrect ? 'bg-emerald-50 text-emerald-950' : 'bg-amber-50 text-amber-950'
      }`}
    >
      <div className="max-w-xl w-full mx-auto bg-white rounded-3xl p-8 sm:p-12 shadow-2xl border-4 transition-all duration-300 transform scale-100 animate-gentle-pulse">
        {/* Visual Cue Icon */}
        <div className="mb-6 inline-flex p-4 rounded-full">
          {isCorrect ? (
            <div className="p-5 bg-emerald-100 text-emerald-600 rounded-full">
              <CheckCircle2 className="w-24 h-24" />
            </div>
          ) : (
            <div className="p-5 bg-amber-100 text-amber-600 rounded-full">
              <Heart className="w-24 h-24" />
            </div>
          )}
        </div>

        {/* Gentle Encouraging Header */}
        <h2 className="text-4xl sm:text-5xl font-black mb-4 tracking-tight">
          {gentleMessage}
        </h2>

        {/* Explanation text */}
        {isCorrect ? (
          <p className="text-2xl sm:text-3xl text-emerald-800 font-bold mb-4">
            "{selectedChoice}" is correct!
          </p>
        ) : (
          <div className="space-y-2 mb-4">
            <p className="text-xl sm:text-2xl text-slate-600 font-medium">
              You chose: <span className="font-semibold text-slate-800">"{selectedChoice}"</span>
            </p>
            <p className="text-2xl sm:text-3xl text-amber-800 font-bold">
              The photo showed: "{correctChoice}"
            </p>
          </div>
        )}

        <div className="inline-flex items-center gap-2 mt-4 px-4 py-2 bg-slate-100 rounded-full text-slate-500 font-semibold text-lg">
          <Sparkles className="w-5 h-5 text-amber-500" />
          <span>Moving to next memory...</span>
        </div>
      </div>
    </div>
  );
};
