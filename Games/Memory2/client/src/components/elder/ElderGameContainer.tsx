import React, { useState } from 'react';
import { Elder, PlaySessionData, SessionSummary, api } from '../../services/api';
import { ElderHome } from './ElderHome';
import { ImageRevealScreen } from './ImageRevealScreen';
import { QuestionScreen } from './QuestionScreen';
import { FeedbackScreen } from './FeedbackScreen';
import { SessionSummaryScreen } from './SessionSummaryScreen';
import { Loader2, AlertCircle } from 'lucide-react';

interface Props {
  elder: Elder;
  onSwitchProfile: () => void;
}

type GamePhase = 'home' | 'reveal' | 'question' | 'feedback' | 'summary';

export const ElderGameContainer: React.FC<Props> = ({ elder, onSwitchProfile }) => {
  const [phase, setPhase] = useState<GamePhase>('home');
  const [session, setSession] = useState<PlaySessionData | null>(null);
  const [currentRoundIndex, setCurrentRoundIndex] = useState(0);
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Question response tracking
  const [questionStartTime, setQuestionStartTime] = useState<number>(0);
  const [lastFeedback, setLastFeedback] = useState<{
    isCorrect: boolean;
    gentleMessage: string;
    correctChoice: string;
    selectedChoice: string;
  } | null>(null);

  // Final summary
  const [summary, setSummary] = useState<SessionSummary | null>(null);

  // Start new game session
  const handleStartGame = async () => {
    setLoading(true);
    setErrorMessage(null);
    try {
      const sess = await api.startSession(elder.id);
      setSession(sess);
      setCurrentRoundIndex(0);
      setPhase('reveal');
    } catch (err: any) {
      setErrorMessage(err.message || 'Could not start game session.');
    } finally {
      setLoading(false);
    }
  };

  // Image reveal timer finishes -> move to question step
  const handleRevealTimeUp = () => {
    setQuestionStartTime(performance.now());
    setPhase('question');
  };

  // Elder selects answer
  const handleSelectChoice = async (selectedChoice: string) => {
    if (!session) return;
    const currentRound = session.rounds[currentRoundIndex];
    const timeTakenMs = Math.round(performance.now() - questionStartTime);

    try {
      const result = await api.submitAnswer(
        elder.id,
        session.session_id,
        currentRound.card_id,
        selectedChoice,
        timeTakenMs
      );

      setLastFeedback({
        isCorrect: result.is_correct,
        gentleMessage: result.gentle_message,
        correctChoice: result.correct_choice,
        selectedChoice
      });
      setPhase('feedback');
    } catch {
      // Fallback in case of brief network flicker: still give positive feedback
      setLastFeedback({
        isCorrect: true,
        gentleMessage: 'Good try!',
        correctChoice: selectedChoice,
        selectedChoice
      });
      setPhase('feedback');
    }
  };

  // Advance from feedback to next round or summary
  const handleAdvanceFromFeedback = async () => {
    if (!session) return;

    if (currentRoundIndex + 1 < session.rounds.length) {
      setCurrentRoundIndex(prev => prev + 1);
      setPhase('reveal');
    } else {
      // Session completed!
      try {
        const { summary: sum } = await api.completeSession(elder.id, session.session_id);
        setSummary(sum);
        setPhase('summary');
      } catch {
        setPhase('home');
      }
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-amber-50 flex flex-col items-center justify-center p-6 text-center">
        <Loader2 className="w-16 h-16 text-blue-600 animate-spin mb-4" />
        <h2 className="text-3xl font-bold text-slate-800">
          Preparing your photo memories...
        </h2>
      </div>
    );
  }

  if (errorMessage) {
    return (
      <div className="min-h-screen bg-amber-50 flex flex-col items-center justify-center p-6 text-center">
        <div className="bg-white rounded-3xl p-8 max-w-lg border-2 border-rose-200 shadow-xl">
          <AlertCircle className="w-16 h-16 text-rose-500 mx-auto mb-4" />
          <h2 className="text-3xl font-bold text-slate-900 mb-2">
            Notice
          </h2>
          <p className="text-xl text-slate-600 mb-6">
            {errorMessage}
          </p>
          <button
            onClick={() => setErrorMessage(null)}
            className="elder-touch-target px-8 py-4 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xl rounded-2xl cursor-pointer"
          >
            Back to Home
          </button>
        </div>
      </div>
    );
  }

  if (phase === 'home') {
    return (
      <ElderHome
        elder={elder}
        onStartGame={handleStartGame}
        onSwitchProfile={onSwitchProfile}
      />
    );
  }

  if (phase === 'reveal' && session) {
    const currentRound = session.rounds[currentRoundIndex];
    return (
      <ImageRevealScreen
        photoUrl={currentRound.photo_url}
        durationSeconds={session.reveal_duration_seconds}
        currentRound={currentRoundIndex + 1}
        totalRounds={session.rounds.length}
        onTimeUp={handleRevealTimeUp}
      />
    );
  }

  if (phase === 'question' && session) {
    const currentRound = session.rounds[currentRoundIndex];
    return (
      <QuestionScreen
        questionPrompt={currentRound.question_prompt}
        choices={currentRound.choices}
        currentRound={currentRoundIndex + 1}
        totalRounds={session.rounds.length}
        onSelectChoice={handleSelectChoice}
      />
    );
  }

  if (phase === 'feedback' && lastFeedback) {
    return (
      <FeedbackScreen
        isCorrect={lastFeedback.isCorrect}
        gentleMessage={lastFeedback.gentleMessage}
        correctChoice={lastFeedback.correctChoice}
        selectedChoice={lastFeedback.selectedChoice}
        onAdvance={handleAdvanceFromFeedback}
      />
    );
  }

  if (phase === 'summary' && summary) {
    return (
      <SessionSummaryScreen
        summary={summary}
        onPlayAgain={handleStartGame}
        onDone={() => setPhase('home')}
      />
    );
  }

  return null;
};
