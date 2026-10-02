import React, { useEffect, useState } from 'react';

interface Props {
  photoUrl: string;
  durationSeconds: number;
  currentRound: number;
  totalRounds: number;
  onTimeUp: () => void;
}

export const ImageRevealScreen: React.FC<Props> = ({
  photoUrl,
  durationSeconds,
  currentRound,
  totalRounds,
  onTimeUp
}) => {
  const [timeLeft, setTimeLeft] = useState(durationSeconds);

  useEffect(() => {
    setTimeLeft(durationSeconds);

    const interval = setInterval(() => {
      setTimeLeft(prev => {
        if (prev <= 1) {
          clearInterval(interval);
          onTimeUp();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [durationSeconds, photoUrl, onTimeUp]);

  // Calculate SVG circular stroke offset
  const radius = 48;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (timeLeft / durationSeconds) * circumference;

  return (
    <div className="fixed inset-0 bg-slate-950 flex flex-col justify-between p-4 sm:p-8 select-none z-40 overflow-hidden">
      {/* Top Banner: Round indicator and friendly prompt */}
      <div className="w-full max-w-5xl mx-auto flex items-center justify-between z-10">
        <div className="bg-slate-900/90 backdrop-blur-md px-6 py-3 rounded-full border border-slate-700 text-white font-bold text-xl sm:text-2xl shadow-lg">
          Memory {currentRound} of {totalRounds}
        </div>

        <div className="bg-blue-600/90 text-white px-6 py-3 rounded-full font-bold text-xl sm:text-2xl shadow-lg animate-pulse">
          Look closely at the details...
        </div>

        {/* Large Countdown Ring */}
        <div className="relative w-20 h-20 sm:w-24 sm:h-24 flex items-center justify-center">
          <svg className="w-full h-full transform -rotate-90">
            <circle
              cx="50%"
              cy="50%"
              r={radius}
              stroke="rgba(255, 255, 255, 0.2)"
              strokeWidth="10"
              fill="transparent"
            />
            <circle
              cx="50%"
              cy="50%"
              r={radius}
              stroke="#38BDF8"
              strokeWidth="10"
              fill="transparent"
              strokeDasharray={circumference}
              strokeDashoffset={strokeDashoffset}
              strokeLinecap="round"
              className="transition-all duration-1000 ease-linear"
            />
          </svg>
          <div className="absolute inset-0 flex items-center justify-center text-white font-black text-3xl sm:text-4xl">
            {timeLeft}
          </div>
        </div>
      </div>

      {/* Main Full-Screen Photo Container */}
      <div className="flex-1 flex items-center justify-center my-4 relative">
        <div className="relative max-h-[82vh] max-w-[95vw] sm:max-w-5xl w-full h-full flex items-center justify-center rounded-3xl overflow-hidden shadow-2xl bg-black border-4 border-slate-800">
          <img
            src={photoUrl}
            alt="Memory target"
            className="w-full h-full object-contain rounded-2xl"
          />
        </div>
      </div>

      {/* Subtle reassurance footer - NO buttons to avoid accidental taps */}
      <div className="text-center text-slate-400 text-lg sm:text-xl font-medium pb-2">
        The picture will hide automatically when time is up. Relax and observe!
      </div>
    </div>
  );
};
