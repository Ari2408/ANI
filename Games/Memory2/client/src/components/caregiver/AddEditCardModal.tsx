import React, { useState } from 'react';
import { Card, Elder, api } from '../../services/api';
import { SAMPLE_CARD_IMAGES } from '../../../../server/src/seedData';
import { X, Upload, Plus, Trash2, HelpCircle, Eye, Loader2, Sparkles } from 'lucide-react';

interface Props {
  elder: Elder;
  editingCard?: Card | null;
  onClose: () => void;
  onSaved: () => void;
}

export const AddEditCardModal: React.FC<Props> = ({ elder, editingCard, onClose, onSaved }) => {
  const [photoUrl, setPhotoUrl] = useState<string>(editingCard?.photo_url || '');
  const [questionPrompt, setQuestionPrompt] = useState<string>(editingCard?.question_prompt || '');
  const [correctChoice, setCorrectChoice] = useState<string>(editingCard?.correct_choice || '');
  const [wrongChoices, setWrongChoices] = useState<string[]>(
    editingCard?.wrong_choices && editingCard.wrong_choices.length > 0
      ? [...editingCard.wrong_choices]
      : ['']
  );

  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showHelper, setShowHelper] = useState(true);

  // File upload handler
  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;
    const file = e.target.files[0];
    setUploading(true);
    setError(null);
    try {
      const res = await api.uploadPhoto(file);
      setPhotoUrl(res.photo_url);
    } catch (err: any) {
      setError(err.message || 'Failed to upload photo.');
    } finally {
      setUploading(false);
    }
  };

  const handleAddWrongChoice = () => {
    if (wrongChoices.length < 3) {
      setWrongChoices([...wrongChoices, '']);
    }
  };

  const handleRemoveWrongChoice = (index: number) => {
    if (wrongChoices.length > 1) {
      setWrongChoices(wrongChoices.filter((_, i) => i !== index));
    }
  };

  const handleWrongChoiceChange = (index: number, val: string) => {
    const updated = [...wrongChoices];
    updated[index] = val;
    setWrongChoices(updated);
  };

  const handleSelectSampleImage = (img: string) => {
    setPhotoUrl(img);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!photoUrl) {
      setError('Please upload or select a photo.');
      return;
    }
    if (!questionPrompt.trim()) {
      setError('Please enter a question prompt.');
      return;
    }
    if (!correctChoice.trim()) {
      setError('Please enter the correct answer.');
      return;
    }

    const cleanedWrong = wrongChoices.map(s => s.trim()).filter(s => s.length > 0);
    if (cleanedWrong.length === 0) {
      setError('Please enter at least one wrong answer choice.');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      if (editingCard) {
        await api.updateCard(editingCard.id, {
          photo_url: photoUrl,
          question_prompt: questionPrompt.trim(),
          correct_choice: correctChoice.trim(),
          wrong_choices: cleanedWrong
        });
      } else {
        await api.createCard({
          elder_id: elder.id,
          photo_url: photoUrl,
          question_prompt: questionPrompt.trim(),
          correct_choice: correctChoice.trim(),
          wrong_choices: cleanedWrong
        });
      }
      onSaved();
    } catch (err: any) {
      setError(err.message || 'Failed to save photo card.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 overflow-y-auto">
      <div className="bg-white rounded-3xl max-w-4xl w-full shadow-2xl border border-slate-200 overflow-hidden my-8 animate-in fade-in zoom-in-95 duration-200">
        {/* Modal Header */}
        <div className="p-6 border-b border-slate-200 flex items-center justify-between bg-slate-50/70">
          <div>
            <h2 className="text-2xl font-black text-slate-900">
              {editingCard ? 'Edit Photo Card' : 'Add New Photo Card'}
            </h2>
            <p className="text-sm text-slate-500 font-medium">
              Authoring visual recall card for <span className="font-bold text-slate-800">{elder.display_name}</span>
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-slate-700 hover:bg-slate-200 transition-colors cursor-pointer"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {error && (
          <div className="mx-6 mt-6 p-4 bg-rose-50 border border-rose-200 text-rose-800 rounded-2xl text-sm font-semibold">
            {error}
          </div>
        )}

        {/* Lightweight Caregiver Guidance Helper */}
        {showHelper && (
          <div className="mx-6 mt-4 p-4 bg-blue-50 border border-blue-200 rounded-2xl flex items-start justify-between gap-3 text-xs sm:text-sm text-blue-900">
            <div className="flex items-start gap-2">
              <Sparkles className="w-5 h-5 text-blue-600 shrink-0 mt-0.5" />
              <div>
                <span className="font-bold">Elder-Friendly Question Best Practices:</span>
                <ul className="list-disc list-inside mt-1 space-y-0.5 text-blue-800">
                  <li>Ask about one distinct, visible detail (a bright color, count, or object name).</li>
                  <li>Keep wrong choices plausible but clearly distinct from the correct choice.</li>
                  <li>Avoid trick questions or details requiring outside memory beyond the picture.</li>
                </ul>
              </div>
            </div>
            <button
              onClick={() => setShowHelper(false)}
              className="text-blue-500 hover:text-blue-800 font-bold text-xs"
            >
              Hide
            </button>
          </div>
        )}

        {/* Form Body */}
        <form onSubmit={handleSave} className="p-6 space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Left Column: Image Selector & Upload */}
            <div className="space-y-4">
              <label className="block text-sm font-bold text-slate-800">
                1. Select or Upload Photo <span className="text-rose-500">*</span>
              </label>

              {/* Photo Preview or Dropzone */}
              <div className="relative border-2 border-dashed border-slate-300 rounded-2xl overflow-hidden bg-slate-50 min-h-[220px] flex flex-col items-center justify-center p-4">
                {photoUrl ? (
                  <div className="relative w-full h-56 flex items-center justify-center bg-black/5 rounded-xl overflow-hidden">
                    <img
                      src={photoUrl}
                      alt="Selected preview"
                      className="w-full h-full object-contain"
                    />
                    <button
                      type="button"
                      onClick={() => setPhotoUrl('')}
                      className="absolute top-2 right-2 p-2 bg-slate-900/80 text-white rounded-full hover:bg-rose-600 transition-colors cursor-pointer shadow-md"
                      title="Remove Photo"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                ) : (
                  <div className="text-center p-4">
                    {uploading ? (
                      <div className="flex flex-col items-center">
                        <Loader2 className="w-10 h-10 text-blue-600 animate-spin mb-2" />
                        <span className="text-sm font-semibold text-slate-600">Uploading photo...</span>
                      </div>
                    ) : (
                      <>
                        <Upload className="w-10 h-10 text-slate-400 mx-auto mb-2" />
                        <p className="text-sm font-bold text-slate-700">
                          Upload from your phone or computer
                        </p>
                        <p className="text-xs text-slate-500 mt-1">
                          JPG, PNG, or WebP up to 15MB
                        </p>
                        <label className="mt-3 inline-block px-4 py-2 bg-white border border-slate-300 hover:border-blue-500 rounded-xl text-xs font-bold text-slate-700 shadow-xs cursor-pointer">
                          Browse Files
                          <input
                            type="file"
                            accept="image/*"
                            onChange={handleFileChange}
                            className="hidden"
                          />
                        </label>
                      </>
                    )}
                  </div>
                )}
              </div>

              {/* Quick Starter Templates */}
              <div>
                <span className="text-xs font-bold text-slate-500 uppercase tracking-wider block mb-2">
                  Or pick a curated sample photo:
                </span>
                <div className="grid grid-cols-6 gap-2">
                  {Object.entries(SAMPLE_CARD_IMAGES).map(([name, url]) => (
                    <button
                      key={name}
                      type="button"
                      onClick={() => handleSelectSampleImage(url)}
                      className={`h-14 rounded-xl overflow-hidden border-2 transition-all cursor-pointer ${
                        photoUrl === url ? 'border-blue-600 ring-2 ring-blue-300 scale-105' : 'border-slate-200 hover:border-slate-400'
                      }`}
                      title={name}
                    >
                      <img src={url} alt={name} className="w-full h-full object-cover" />
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Right Column: Question & Answers */}
            <div className="space-y-4">
              {/* Question Input */}
              <div>
                <label className="block text-sm font-bold text-slate-800 mb-1">
                  2. Question Prompt <span className="text-rose-500">*</span>
                </label>
                <input
                  type="text"
                  value={questionPrompt}
                  onChange={e => setQuestionPrompt(e.target.value)}
                  placeholder='e.g., "What color was the teapot on the table?"'
                  className="w-full px-4 py-3 border border-slate-300 rounded-xl text-slate-900 text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 focus:outline-none"
                />
              </div>

              {/* Correct Answer */}
              <div>
                <label className="block text-sm font-bold text-emerald-800 mb-1 flex items-center justify-between">
                  <span>3. Correct Answer <span className="text-rose-500">*</span></span>
                  <span className="text-xs font-semibold text-emerald-600">The true detail</span>
                </label>
                <input
                  type="text"
                  value={correctChoice}
                  onChange={e => setCorrectChoice(e.target.value)}
                  placeholder='e.g., "Red"'
                  className="w-full px-4 py-3 border-2 border-emerald-300 bg-emerald-50/40 rounded-xl text-slate-900 text-sm font-bold focus:ring-2 focus:ring-emerald-500 focus:outline-none"
                />
              </div>

              {/* Wrong Answer Distractors */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <label className="text-sm font-bold text-slate-800">
                    4. Wrong-Answer Choices (Distractors) <span className="text-rose-500">*</span>
                  </label>
                  {wrongChoices.length < 3 && (
                    <button
                      type="button"
                      onClick={handleAddWrongChoice}
                      className="text-xs font-bold text-blue-600 hover:text-blue-800 flex items-center gap-1 cursor-pointer"
                    >
                      <Plus className="w-3.5 h-3.5" /> Add Choice
                    </button>
                  )}
                </div>

                {wrongChoices.map((wc, idx) => (
                  <div key={idx} className="flex items-center gap-2">
                    <input
                      type="text"
                      value={wc}
                      onChange={e => handleWrongChoiceChange(idx, e.target.value)}
                      placeholder={`Wrong option ${idx + 1} (e.g. "${['Blue', 'Yellow', 'Silver'][idx] || 'Other'}")`}
                      className="flex-1 px-4 py-2.5 border border-slate-300 rounded-xl text-slate-900 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none"
                    />
                    {wrongChoices.length > 1 && (
                      <button
                        type="button"
                        onClick={() => handleRemoveWrongChoice(idx)}
                        className="p-2 text-slate-400 hover:text-rose-600 rounded-lg cursor-pointer"
                        title="Remove choice"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Modal Footer */}
          <div className="pt-4 border-t border-slate-200 flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-5 py-2.5 rounded-xl border border-slate-300 font-bold text-sm text-slate-700 hover:bg-slate-100 transition-colors cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving || uploading}
              className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white rounded-xl font-bold text-sm shadow-md transition-all flex items-center gap-2 cursor-pointer disabled:opacity-50"
            >
              {saving && <Loader2 className="w-4 h-4 animate-spin" />}
              <span>{editingCard ? 'Update Card' : 'Save to Elder Pool'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
