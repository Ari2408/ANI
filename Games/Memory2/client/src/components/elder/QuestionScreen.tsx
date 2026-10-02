import React, { useState, useEffect } from 'react';
import { Volume2 } from 'lucide-react';
import { soundManager } from '../../utils/audio';

interface Props {
  questionPrompt: string;
  choices: string[];
  currentRound: number;
  totalRounds: number;
  onSelectChoice: (choice: string) => void;
}

export const QuestionScreen: React.FC<Props> = ({
  questionPrompt,
  choices,
  currentRound,
  totalRounds,
  onSelectChoice
}) => {
  const [speaking, setSpeaking] = useState(false);
  const [selectedChoice, setSelectedChoice] = useState<string | null>(null);

  // Automatically read question on mount if speech is enabled
  useEffect(() => {
    handleSpeakQuestion();
    return () => {
      soundManager.stopSpeech();
    };
  }, [questionPrompt]);

  const handleSpeakQuestion = () => {
    setSpeaking(true);
    const speechText = `${questionPrompt}. Your choices are: ${choices.join(', or ')}`;
    soundManager.speak(speechText, () => setSpeaking(false));
  };

  const handleChoiceClick = (choice: string) => {
    if (selectedChoice !== null) return; // Prevent double clicks
    setSelectedChoice(choice);
    soundManager.stopSpeech();
    onSelectChoice(choice);
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col justify-between p-6 sm:p-12 text-slate-900 select-none">
      {/* Top Banner: Round indicator */}
      <div className="max-w-4xl mx-auto w-full flex items-center justify-between">
        <div className="bg-blue-100 text-blue-900 font-extrabold text-xl sm:text-2xl px-6 py-2.5 rounded-full shadow-xs">
          Question {currentRound} of {totalRounds}
        </div>

        <div className="text-slate-500 font-semibold text-lg sm:text-xl">
          Take all the time you need
        </div>
      </div>

      {/* Center Question Prompt Box */}
      <div className="max-w-3xl mx-auto w-full text-center my-auto py-4">
        <div className="bg-white border-3 border-blue-200 rounded-3xl p-8 sm:p-12 shadow-xl mb-8 relative">
          <div className="flex items-center justify-center gap-4 mb-4">
            <button
              onClick={handleSpeakQuestion}
              className={`elder-touch-target px-5 py-3 rounded-full border-2 transition-all cursor-pointer flex items-center gap-2 font-bold text-lg ${
                speaking
                  ? 'bg-blue-600 text-white border-blue-600 animate-pulse'
                  : 'bg-blue-50 text-blue-700 border-blue-200 hover:bg-blue-100'
              }`}
              title="Hear question aloud"
            >
              <Volume2 className="w-7 h-7" />
              <span>Read Question Aloud</span>
            </button>
          </div>

          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-slate-900 leading-tight">
            {questionPrompt}
          </h2>
        </div>

        {/* Big Tappable Answer Choices Grid */}
        <div className={`grid gap-5 w-full ${choices.length > 2 ? 'grid-cols-1 sm:grid-cols-2' : 'grid-cols-1'}`}>
          {choices.map((choice, index) => {
            const isChosen = selectedChoice === choice;
            return (
              <button
                key={index}
                disabled={selectedChoice !== null}
                onClick={() => handleChoiceClick(choice)}
                className={`elder-touch-target w-full min-h-[80px] p-6 rounded-3xl font-extrabold text-2xl sm:text-3xl transition-all duration-200 shadow-md transform hover:-translate-y-1 active:translate-y-0 cursor-pointer border-4 text-left flex items-center justify-between ${
                  isChosen
                    ? 'bg-blue-600 text-white border-blue-700 shadow-xl scale-[1.02]'
                    : 'bg-white hover:bg-blue-50 text-slate-900 border-slate-300 hover:border-blue-400'
                }`}
              >
                <div className="flex items-center gap-4">
                  <span className="w-10 h-10 rounded-full bg-slate-100 text-slate-700 flex items-center justify-center font-bold text-xl shrink-0 border border-slate-300">
                    {String.fromCharCode(65 + index)}
                  </span>
                  <span>{choice}</span>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Calm Guidance Footer */}
      <div className="text-center text-slate-500 font-medium text-xl pb-2">
        Tap the answer you remember seeing in the photo
      </div>
    </div>
  );
};
