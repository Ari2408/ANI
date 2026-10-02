import React, { useState } from 'react';
import { Elder } from '../../services/api';
import { Volume2, VolumeX, Sparkles, Play, Users, Sun } from 'lucide-react';
import { soundManager } from '../../utils/audio';

interface Props {
  elder: Elder;
  onStartGame: () => void;
  onSwitchProfile: () => void;
}

export const ElderHome: React.FC<Props> = ({ elder, onStartGame, onSwitchProfile }) => {
  const [speaking, setSpeaking] = useState(false);
  const [soundOn, setSoundOn] = useState(soundManager.isSoundEnabled());

  const instructionText = "Look at each picture carefully for a few seconds. Then, answer a simple question about what you just saw. There is no rush!";

  const handleSpeakInstructions = () => {
    if (speaking) {
      soundManager.stopSpeech();
      setSpeaking(false);
    } else {
      setSpeaking(true);
      soundManager.speak(
        `Hello ${elder.display_name}! Welcome to Memory Snap. ${instructionText} Tap the big green Start button whenever you are ready.`,
        () => setSpeaking(false)
      );
    }
  };

  const handleToggleSound = () => {
    const next = soundManager.toggleSound();
    setSoundOn(next);
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-amber-50 to-orange-50/40 flex flex-col justify-between p-6 sm:p-12 text-slate-900 select-none">
      {/* Top Bar: Switch Profile & Audio Controls */}
      <div className="max-w-4xl mx-auto w-full flex items-center justify-between">
        <button
          onClick={onSwitchProfile}
          className="elder-touch-target px-6 py-3 bg-white border-2 border-slate-200 hover:border-slate-400 rounded-full font-semibold text-xl text-slate-700 shadow-sm flex items-center gap-3 transition-colors cursor-pointer"
        >
          <Users className="w-6 h-6 text-blue-600" />
          <span>Switch Player</span>
        </button>

        <div className="flex items-center gap-3">
          <button
            onClick={handleToggleSound}
            aria-label="Toggle Sound Effects"
            className="elder-touch-target p-3.5 bg-white border-2 border-slate-200 hover:border-slate-400 rounded-full font-semibold text-xl text-slate-700 shadow-sm transition-colors cursor-pointer"
            title={soundOn ? 'Mute Sounds' : 'Unmute Sounds'}
          >
            {soundOn ? <Volume2 className="w-7 h-7 text-blue-600" /> : <VolumeX className="w-7 h-7 text-slate-400" />}
          </button>
        </div>
      </div>

      {/* Main Content Card */}
      <div className="max-w-2xl mx-auto w-full text-center my-auto py-8">
        {/* Elder Avatar */}
        <div className="relative inline-block mb-6">
          <div className="w-36 h-36 sm:w-44 sm:h-44 rounded-full overflow-hidden border-6 border-white shadow-xl mx-auto bg-amber-100">
            <img
              src={elder.avatar_url}
              alt={elder.display_name}
              className="w-full h-full object-cover"
            />
          </div>
          <div className="absolute -bottom-2 right-2 bg-amber-400 text-amber-950 p-2.5 rounded-full shadow-md">
            <Sun className="w-7 h-7" />
          </div>
        </div>

        {/* Warm Greeting */}
        <h1 className="text-4xl sm:text-5xl font-black text-slate-900 tracking-tight mb-3">
          Hello, {elder.display_name}!
        </h1>

        {/* Friendly Streak Indicator (qualitative, warm) */}
        <div className="inline-flex items-center gap-2 px-5 py-2.5 bg-amber-100/80 text-amber-900 rounded-full text-lg sm:text-xl font-bold mb-8 shadow-xs">
          <Sparkles className="w-6 h-6 text-amber-600" />
          <span>Wonderful day to exercise your memory!</span>
        </div>

        {/* Instruction Box with Read Aloud */}
        <div className="bg-white rounded-3xl p-6 sm:p-8 border-2 border-amber-200/80 shadow-md text-left mb-10">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h2 className="text-2xl font-bold text-slate-800 mb-2">
                How to Play:
              </h2>
              <p className="text-xl sm:text-2xl text-slate-600 font-medium leading-relaxed">
                {instructionText}
              </p>
            </div>

            <button
              onClick={handleSpeakInstructions}
              className={`elder-touch-target p-4 rounded-2xl border-2 transition-all cursor-pointer shrink-0 ${
                speaking
                  ? 'bg-blue-600 text-white border-blue-600 animate-pulse'
                  : 'bg-blue-50 text-blue-700 border-blue-200 hover:bg-blue-100'
              }`}
              title="Read Instructions Aloud"
            >
              <Volume2 className="w-8 h-8" />
            </button>
          </div>
        </div>

        {/* Big Start Button */}
        <button
          onClick={onStartGame}
          className="elder-touch-target w-full py-6 px-10 bg-emerald-600 hover:bg-emerald-700 active:bg-emerald-800 text-white font-extrabold text-3xl sm:text-4xl rounded-3xl shadow-xl hover:shadow-2xl transition-all duration-200 transform hover:scale-[1.02] cursor-pointer flex items-center justify-center gap-4 border-4 border-emerald-500"
        >
          <Play className="w-10 h-10 fill-current" />
          <span>Start Game</span>
        </button>
      </div>

      {/* Footer calm note */}
      <div className="text-center text-slate-500 font-medium text-lg">
        Caregiver authored pictures • Memory Snap v1.0
      </div>
    </div>
  );
};
