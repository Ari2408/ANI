import React, { useState } from 'react';
import { Elder, api } from '../../services/api';
import { Lock, Delete, UserCheck, ShieldAlert } from 'lucide-react';

interface Props {
  elders: Elder[];
  onSelect: (elder: Elder) => void;
  onOpenCaregiver: () => void;
}

export const ElderProfileSelect: React.FC<Props> = ({ elders, onSelect, onOpenCaregiver }) => {
  const [pinModalElder, setPinModalElder] = useState<Elder | null>(null);
  const [pinInput, setPinInput] = useState('');
  const [pinError, setPinError] = useState(false);
  const [verifying, setVerifying] = useState(false);

  const handleElderClick = (elder: Elder) => {
    if (elder.has_pin) {
      setPinModalElder(elder);
      setPinInput('');
      setPinError(false);
    } else {
      onSelect(elder);
    }
  };

  const handlePinDigit = (digit: string) => {
    if (pinInput.length < 4) {
      const next = pinInput + digit;
      setPinInput(next);
      setPinError(false);
      if (next.length === 4 && pinModalElder) {
        verifyAndProceed(pinModalElder, next);
      }
    }
  };

  const handlePinBackspace = () => {
    setPinInput(prev => prev.slice(0, -1));
    setPinError(false);
  };

  const verifyAndProceed = async (elder: Elder, pin: string) => {
    setVerifying(true);
    try {
      const ok = await api.verifyPin(elder.id, pin);
      if (ok) {
        setPinModalElder(null);
        onSelect(elder);
      } else {
        setPinError(true);
        setPinInput('');
      }
    } catch {
      setPinError(true);
    } finally {
      setVerifying(false);
    }
  };

  return (
    <div className="min-h-screen bg-amber-50/60 flex flex-col justify-between p-6 sm:p-12 text-slate-900">
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto pt-6">
        <div className="inline-flex items-center justify-center p-3 bg-blue-100 text-blue-800 rounded-full mb-4 shadow-sm">
          <span className="text-2xl font-bold tracking-tight px-3">Memory Snap</span>
        </div>
        <h1 className="text-4xl sm:text-5xl font-extrabold text-slate-900 tracking-tight mb-3">
          Who is playing today?
        </h1>
        <p className="text-xl sm:text-2xl text-slate-600 font-medium">
          Tap your photo to begin your memory game
        </p>
      </div>

      {/* Profiles Grid */}
      <div className="max-w-4xl mx-auto w-full my-8">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-8 justify-center">
          {elders.map(elder => (
            <button
              key={elder.id}
              onClick={() => handleElderClick(elder)}
              className="group relative bg-white border-3 border-amber-200 hover:border-blue-500 rounded-3xl p-8 flex flex-col items-center text-center shadow-lg hover:shadow-2xl transition-all duration-200 transform hover:-translate-y-1 focus:outline-none focus:ring-4 focus:ring-blue-400 cursor-pointer min-h-[260px]"
            >
              {elder.has_pin && (
                <div className="absolute top-4 right-4 bg-amber-100 text-amber-800 px-3 py-1 rounded-full text-sm font-semibold flex items-center gap-1">
                  <Lock className="w-3.5 h-3.5" /> PIN Protected
                </div>
              )}

              <div className="w-32 h-32 rounded-full overflow-hidden border-4 border-amber-100 shadow-inner group-hover:border-blue-200 transition-colors mb-5 bg-amber-50">
                <img
                  src={elder.avatar_url}
                  alt={elder.display_name}
                  className="w-full h-full object-cover"
                />
              </div>

              <h2 className="text-3xl font-bold text-slate-900 mb-2">
                {elder.display_name}
              </h2>

              <div className="flex items-center gap-2">
                <span className="capitalize px-4 py-1.5 bg-blue-50 text-blue-800 rounded-full text-base font-medium">
                  {elder.difficulty_level} Mode
                </span>
                {elder.active_card_count !== undefined && (
                  <span className="px-3 py-1.5 bg-emerald-50 text-emerald-800 rounded-full text-base font-medium">
                    {elder.active_card_count} Photo Cards
                  </span>
                )}
              </div>

              <div className="mt-6 w-full py-3.5 bg-blue-600 group-hover:bg-blue-700 text-white text-xl font-bold rounded-2xl transition-colors shadow">
                Tap to Play
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* PIN Verification Modal */}
      {pinModalElder && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl p-8 max-w-sm w-full shadow-2xl border border-slate-200 text-center animate-gentle-pulse">
            <h3 className="text-2xl font-bold text-slate-900 mb-1">
              Welcome, {pinModalElder.display_name}!
            </h3>
            <p className="text-lg text-slate-600 mb-6">
              Please enter your 4-digit PIN
            </p>

            {/* PIN Dots */}
            <div className="flex justify-center gap-4 mb-6">
              {[0, 1, 2, 3].map(idx => (
                <div
                  key={idx}
                  className={`w-6 h-6 rounded-full border-2 transition-all ${
                    pinInput.length > idx
                      ? 'bg-blue-600 border-blue-600 scale-110'
                      : 'border-slate-300 bg-slate-100'
                  }`}
                />
              ))}
            </div>

            {pinError && (
              <div className="mb-4 text-rose-600 font-semibold flex items-center justify-center gap-1.5 text-base">
                <ShieldAlert className="w-5 h-5" /> Incorrect PIN. Try again.
              </div>
            )}

            {/* Tactile Keypad */}
            <div className="grid grid-cols-3 gap-3 mb-6">
              {['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'].map((item, idx) => {
                if (item === '') return <div key={idx} />;
                if (item === 'back') {
                  return (
                    <button
                      key={idx}
                      onClick={handlePinBackspace}
                      className="h-16 bg-slate-100 hover:bg-slate-200 active:bg-slate-300 rounded-2xl flex items-center justify-center text-slate-700 font-bold transition-colors cursor-pointer"
                    >
                      <Delete className="w-6 h-6" />
                    </button>
                  );
                }
                return (
                  <button
                    key={idx}
                    disabled={verifying}
                    onClick={() => handlePinDigit(item)}
                    className="h-16 bg-slate-100 hover:bg-blue-100 active:bg-blue-200 text-slate-900 text-2xl font-bold rounded-2xl transition-colors cursor-pointer"
                  >
                    {item}
                  </button>
                );
              })}
            </div>

            <button
              onClick={() => setPinModalElder(null)}
              className="text-slate-600 hover:text-slate-900 font-medium py-2 px-4 rounded-lg text-lg"
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      {/* Caregiver Portal Portal Entrance */}
      <div className="text-center pt-4">
        <button
          onClick={onOpenCaregiver}
          className="inline-flex items-center gap-2 px-5 py-3 rounded-full bg-white hover:bg-slate-100 text-slate-600 border border-slate-300 font-medium text-lg shadow-sm transition-all cursor-pointer"
        >
          <Lock className="w-5 h-5 text-slate-400" />
          Caregiver Portal & Content Settings
        </button>
      </div>
    </div>
  );
};
