import React, { useState } from 'react';
import { Elder, api } from '../../services/api';
import { AVATAR_ELEANOR, AVATAR_ARTHUR } from '../../../../server/src/seedData';
import { Plus, Settings, UserCheck, Shield, Clock, Hash, Check, X, Trash2 } from 'lucide-react';

interface Props {
  elders: Elder[];
  selectedElder: Elder | null;
  onSelectElder: (elder: Elder) => void;
  onRefreshElders: () => void;
}

export const ElderProfilesView: React.FC<Props> = ({
  elders,
  selectedElder,
  onSelectElder,
  onRefreshElders
}) => {
  const [editingElder, setEditingElder] = useState<Elder | null>(null);
  const [isCreating, setIsCreating] = useState(false);

  // Form State
  const [displayName, setDisplayName] = useState('');
  const [birthYear, setBirthYear] = useState('');
  const [avatarUrl, setAvatarUrl] = useState(AVATAR_ELEANOR);
  const [difficulty, setDifficulty] = useState<'easy' | 'medium' | 'hard'>('easy');
  const [revealSeconds, setRevealSeconds] = useState(10);
  const [roundsPerSession, setRoundsPerSession] = useState(5);
  const [pinCode, setPinCode] = useState('');

  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const startCreate = () => {
    setEditingElder(null);
    setDisplayName('');
    setBirthYear('1945');
    setAvatarUrl(AVATAR_ELEANOR);
    setDifficulty('easy');
    setRevealSeconds(10);
    setRoundsPerSession(5);
    setPinCode('');
    setError(null);
    setIsCreating(true);
  };

  const startEdit = (elder: Elder) => {
    setEditingElder(elder);
    setDisplayName(elder.display_name);
    setBirthYear(elder.birth_year ? String(elder.birth_year) : '');
    setAvatarUrl(elder.avatar_url);
    setDifficulty(elder.difficulty_level);
    setRevealSeconds(elder.reveal_duration_seconds);
    setRoundsPerSession(elder.rounds_per_session);
    setPinCode(''); // Don't pre-fill secret PIN
    setError(null);
    setIsCreating(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!displayName.trim()) {
      setError('Name is required');
      return;
    }

    setSaving(true);
    setError(null);
    try {
      if (editingElder) {
        const payload: any = {
          display_name: displayName.trim(),
          birth_year: birthYear ? parseInt(birthYear, 10) : null,
          avatar_url: avatarUrl,
          difficulty_level: difficulty,
          reveal_duration_seconds: revealSeconds,
          rounds_per_session: roundsPerSession
        };
        if (pinCode.trim().length > 0) {
          payload.pin_code = pinCode.trim();
        }
        await api.updateElder(editingElder.id, payload);
      } else {
        await api.createElder({
          display_name: displayName.trim(),
          birth_year: birthYear ? parseInt(birthYear, 10) : null,
          avatar_url: avatarUrl,
          difficulty_level: difficulty,
          reveal_duration_seconds: revealSeconds,
          rounds_per_session: roundsPerSession,
          pin_code: pinCode.trim() || undefined
        });
      }
      setIsCreating(false);
      onRefreshElders();
    } catch (err: any) {
      setError(err.message || 'Failed to save profile');
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteElder = async (id: string) => {
    if (!confirm('Are you sure you want to remove this elder profile and all associated data?')) return;
    try {
      await api.deleteElder(id);
      onRefreshElders();
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-black text-slate-900">
            Elder Profiles & Gameplay Configuration
          </h1>
          <p className="text-slate-500 text-sm font-medium">
            Manage player accounts, cognitive difficulty presets, photo viewing durations, and access PINs.
          </p>
        </div>

        <button
          onClick={startCreate}
          className="inline-flex items-center gap-2 px-5 py-3 bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white rounded-xl text-sm font-bold shadow-md cursor-pointer self-start sm:self-auto"
        >
          <Plus className="w-5 h-5" />
          <span>Add New Elder Profile</span>
        </button>
      </div>

      {/* Profiles Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {elders.map(elder => {
          const isSelected = selectedElder?.id === elder.id;
          return (
            <div
              key={elder.id}
              className={`bg-white rounded-3xl p-6 border-2 transition-all shadow-xs flex flex-col justify-between ${
                isSelected ? 'border-blue-500 ring-2 ring-blue-100' : 'border-slate-200 hover:border-slate-300'
              }`}
            >
              <div>
                <div className="flex items-start justify-between gap-4 mb-4">
                  <div className="flex items-center gap-4">
                    <img
                      src={elder.avatar_url}
                      alt={elder.display_name}
                      className="w-16 h-16 rounded-full object-cover border-2 border-amber-200 bg-amber-50"
                    />
                    <div>
                      <h2 className="text-xl font-bold text-slate-900">
                        {elder.display_name}
                      </h2>
                      <p className="text-xs text-slate-500 font-medium">
                        {elder.birth_year ? `Born in ${elder.birth_year}` : 'Age not specified'}
                      </p>
                      {elder.has_pin && (
                        <span className="inline-flex items-center gap-1 text-[11px] font-bold text-amber-700 bg-amber-100 px-2 py-0.5 rounded-full mt-1">
                          <Shield className="w-3 h-3" /> PIN Protected
                        </span>
                      )}
                    </div>
                  </div>

                  <span className="capitalize px-3 py-1 bg-slate-100 text-slate-800 rounded-full text-xs font-bold">
                    {elder.difficulty_level} Difficulty
                  </span>
                </div>

                {/* Configuration Specs */}
                <div className="grid grid-cols-2 gap-3 p-4 bg-slate-50 rounded-2xl text-xs text-slate-600 mb-6">
                  <div className="flex items-center gap-2">
                    <Clock className="w-4 h-4 text-blue-500" />
                    <span>Viewing Time: <strong>{elder.reveal_duration_seconds}s</strong></span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Hash className="w-4 h-4 text-indigo-500" />
                    <span>Rounds / Session: <strong>{elder.rounds_per_session}</strong></span>
                  </div>
                </div>
              </div>

              {/* Actions Footer */}
              <div className="flex items-center justify-between pt-4 border-t border-slate-100">
                <button
                  onClick={() => onSelectElder(elder)}
                  className={`px-4 py-2 rounded-xl text-xs font-bold transition-colors cursor-pointer ${
                    isSelected
                      ? 'bg-blue-600 text-white'
                      : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                  }`}
                >
                  {isSelected ? 'Currently Selected' : 'Set as Active'}
                </button>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => startEdit(elder)}
                    className="p-2 text-slate-500 hover:text-blue-600 rounded-lg hover:bg-slate-100 cursor-pointer"
                    title="Edit Settings"
                  >
                    <Settings className="w-4 h-4" />
                  </button>

                  {elders.length > 1 && (
                    <button
                      onClick={() => handleDeleteElder(elder.id)}
                      className="p-2 text-slate-400 hover:text-rose-600 rounded-lg hover:bg-rose-50 cursor-pointer"
                      title="Delete Profile"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Create / Edit Modal */}
      {isCreating && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 overflow-y-auto">
          <div className="bg-white rounded-3xl max-w-lg w-full shadow-2xl border border-slate-200 p-6 sm:p-8 my-8 animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between mb-6 pb-4 border-b border-slate-200">
              <h3 className="text-xl font-bold text-slate-900">
                {editingElder ? `Edit ${editingElder.display_name}'s Settings` : 'Add New Elder Profile'}
              </h3>
              <button
                onClick={() => setIsCreating(false)}
                className="p-2 text-slate-400 hover:text-slate-700 rounded-lg cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {error && (
              <div className="mb-4 p-3 bg-rose-50 border border-rose-200 text-rose-800 rounded-xl text-xs font-semibold">
                {error}
              </div>
            )}

            <form onSubmit={handleSave} className="space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase text-slate-600 mb-1">
                  Full Name / Display Name
                </label>
                <input
                  type="text"
                  required
                  value={displayName}
                  onChange={e => setDisplayName(e.target.value)}
                  placeholder="e.g. Eleanor Vance"
                  className="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none font-medium"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold uppercase text-slate-600 mb-1">
                    Birth Year
                  </label>
                  <input
                    type="number"
                    value={birthYear}
                    onChange={e => setBirthYear(e.target.value)}
                    placeholder="e.g. 1944"
                    className="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none font-medium"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase text-slate-600 mb-1">
                    Optional 4-Digit PIN
                  </label>
                  <input
                    type="password"
                    maxLength={4}
                    value={pinCode}
                    onChange={e => setPinCode(e.target.value)}
                    placeholder="Leave blank for none"
                    className="w-full px-4 py-2.5 border border-slate-300 rounded-xl text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none font-medium"
                  />
                </div>
              </div>

              {/* Avatar Selector */}
              <div>
                <label className="block text-xs font-bold uppercase text-slate-600 mb-2">
                  Choose Avatar Icon
                </label>
                <div className="flex gap-4">
                  <button
                    type="button"
                    onClick={() => setAvatarUrl(AVATAR_ELEANOR)}
                    className={`p-2 rounded-2xl border-2 transition-all cursor-pointer ${
                      avatarUrl === AVATAR_ELEANOR ? 'border-blue-600 ring-2 ring-blue-200' : 'border-slate-200'
                    }`}
                  >
                    <img src={AVATAR_ELEANOR} alt="Avatar 1" className="w-14 h-14 rounded-full" />
                  </button>
                  <button
                    type="button"
                    onClick={() => setAvatarUrl(AVATAR_ARTHUR)}
                    className={`p-2 rounded-2xl border-2 transition-all cursor-pointer ${
                      avatarUrl === AVATAR_ARTHUR ? 'border-blue-600 ring-2 ring-blue-200' : 'border-slate-200'
                    }`}
                  >
                    <img src={AVATAR_ARTHUR} alt="Avatar 2" className="w-14 h-14 rounded-full" />
                  </button>
                </div>
              </div>

              {/* Difficulty Preset */}
              <div>
                <label className="block text-xs font-bold uppercase text-slate-600 mb-1">
                  Difficulty Level Preset
                </label>
                <div className="grid grid-cols-3 gap-2">
                  {(['easy', 'medium', 'hard'] as const).map(lvl => (
                    <button
                      key={lvl}
                      type="button"
                      onClick={() => {
                        setDifficulty(lvl);
                        if (lvl === 'easy') setRevealSeconds(12);
                        if (lvl === 'medium') setRevealSeconds(8);
                        if (lvl === 'hard') setRevealSeconds(6);
                      }}
                      className={`py-2.5 rounded-xl capitalize font-bold text-xs border transition-all cursor-pointer ${
                        difficulty === lvl
                          ? 'bg-blue-600 text-white border-blue-600 shadow-sm'
                          : 'bg-white text-slate-700 border-slate-300 hover:bg-slate-50'
                      }`}
                    >
                      {lvl}
                    </button>
                  ))}
                </div>
                <p className="text-[11px] text-slate-500 mt-1">
                  {difficulty === 'easy' && 'Easy: 12-15s viewing, 2 answer choices'}
                  {difficulty === 'medium' && 'Medium: 8-10s viewing, 3 answer choices'}
                  {difficulty === 'hard' && 'Hard: 5-6s viewing, 4 answer choices'}
                </p>
              </div>

              {/* Duration & Rounds Sliders */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold uppercase text-slate-600 mb-1">
                    Viewing Time ({revealSeconds}s)
                  </label>
                  <input
                    type="range"
                    min={4}
                    max={20}
                    value={revealSeconds}
                    onChange={e => setRevealSeconds(parseInt(e.target.value, 10))}
                    className="w-full accent-blue-600"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase text-slate-600 mb-1">
                    Rounds ({roundsPerSession})
                  </label>
                  <input
                    type="range"
                    min={3}
                    max={8}
                    value={roundsPerSession}
                    onChange={e => setRoundsPerSession(parseInt(e.target.value, 10))}
                    className="w-full accent-blue-600"
                  />
                </div>
              </div>

              {/* Footer */}
              <div className="pt-4 border-t border-slate-200 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsCreating(false)}
                  className="px-4 py-2 rounded-xl border border-slate-300 font-bold text-xs text-slate-700 hover:bg-slate-100 cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold text-xs shadow cursor-pointer disabled:opacity-50"
                >
                  {saving ? 'Saving...' : 'Save Profile'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
