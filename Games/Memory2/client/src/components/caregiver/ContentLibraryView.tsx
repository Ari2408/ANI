import React, { useEffect, useState } from 'react';
import { Card, Elder, api } from '../../services/api';
import {
  Plus,
  Edit2,
  Trash2,
  RotateCcw,
  CheckCircle2,
  AlertCircle,
  HelpCircle,
  Archive,
  Layers,
  Loader2
} from 'lucide-react';
import { AddEditCardModal } from './AddEditCardModal';

interface Props {
  elder: Elder;
}

export const ContentLibraryView: React.FC<Props> = ({ elder }) => {
  const [activeTab, setActiveTab] = useState<'active' | 'trash'>('active');
  const [cards, setCards] = useState<Card[]>([]);
  const [loading, setLoading] = useState(true);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingCard, setEditingCard] = useState<Card | null>(null);

  // Soft delete confirmation
  const [confirmDeleteCard, setConfirmDeleteCard] = useState<Card | null>(null);
  const [confirmPermanentCard, setConfirmPermanentCard] = useState<Card | null>(null);

  useEffect(() => {
    loadCards();
  }, [elder.id, activeTab]);

  const loadCards = async () => {
    setLoading(true);
    try {
      const data = await api.getCards(elder.id, activeTab);
      setCards(data);
    } catch (err) {
      console.error('Failed to load cards', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSoftDelete = async (card: Card) => {
    try {
      await api.deleteCard(card.id);
      setConfirmDeleteCard(null);
      loadCards();
    } catch (err) {
      console.error('Failed to delete card', err);
    }
  };

  const handleRestore = async (card: Card) => {
    try {
      await api.restoreCard(card.id);
      loadCards();
    } catch (err) {
      console.error('Failed to restore card', err);
    }
  };

  const handlePermanentDelete = async (card: Card) => {
    try {
      await api.deleteCardPermanent(card.id);
      setConfirmPermanentCard(null);
      loadCards();
    } catch (err) {
      console.error('Failed to permanently delete card', err);
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      {/* Header with Title and Add Button */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-black text-slate-900">
            {elder.display_name}'s Photo Memory Library
          </h1>
          <p className="text-slate-500 text-sm font-medium">
            100% caregiver-authored visual memory exercises. Add, edit, or archive cards anytime.
          </p>
        </div>

        <button
          onClick={() => {
            setEditingCard(null);
            setIsAddModalOpen(true);
          }}
          className="inline-flex items-center gap-2 px-5 py-3 bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white rounded-xl text-sm font-bold shadow-md hover:shadow-lg transition-all cursor-pointer self-start sm:self-auto"
        >
          <Plus className="w-5 h-5" />
          <span>Add New Photo Card</span>
        </button>
      </div>

      {/* Tabs: Active Cards vs Trash */}
      <div className="flex items-center gap-3 border-b border-slate-200">
        <button
          onClick={() => setActiveTab('active')}
          className={`pb-3 px-2 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors cursor-pointer ${
            activeTab === 'active'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <Layers className="w-4 h-4" />
          <span>Active In Rotation</span>
        </button>

        <button
          onClick={() => setActiveTab('trash')}
          className={`pb-3 px-2 text-sm font-bold flex items-center gap-2 border-b-2 transition-colors cursor-pointer ${
            activeTab === 'trash'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <Archive className="w-4 h-4" />
          <span>Trash / Archived</span>
        </button>
      </div>

      {/* Content Cards Grid */}
      {loading ? (
        <div className="flex items-center justify-center p-20">
          <Loader2 className="w-10 h-10 text-blue-600 animate-spin" />
        </div>
      ) : cards.length === 0 ? (
        <div className="text-center py-16 bg-slate-50 border-2 border-dashed border-slate-200 rounded-3xl p-8">
          <Layers className="w-12 h-12 text-slate-400 mx-auto mb-3" />
          <h2 className="text-xl font-bold text-slate-800 mb-1">
            {activeTab === 'active' ? 'No active cards yet' : 'Trash is empty'}
          </h2>
          <p className="text-slate-500 text-sm max-w-md mx-auto mb-6">
            {activeTab === 'active'
              ? 'Add photos of pets, family members, garden flowers, or everyday items to create visual recall challenges for Eleanor.'
              : 'Cards removed from gameplay will appear here where they can be restored at any time.'}
          </p>
          {activeTab === 'active' && (
            <button
              onClick={() => {
                setEditingCard(null);
                setIsAddModalOpen(true);
              }}
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-sm font-bold shadow-sm cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>Add Your First Card</span>
            </button>
          )}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {cards.map(card => (
            <div
              key={card.id}
              className="bg-white rounded-2xl border border-slate-200 shadow-xs hover:shadow-md transition-shadow overflow-hidden flex flex-col justify-between"
            >
              {/* Card Media Preview */}
              <div className="relative h-48 bg-slate-950 flex items-center justify-center overflow-hidden">
                <img
                  src={card.photo_url}
                  alt={card.question_prompt}
                  className="w-full h-full object-contain"
                />

                {/* Accuracy Badge */}
                {card.accuracy !== null && card.accuracy !== undefined ? (
                  <div className="absolute top-3 right-3 bg-slate-900/80 backdrop-blur-xs text-white text-xs font-bold px-2.5 py-1 rounded-full flex items-center gap-1 shadow">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    <span>{card.accuracy}% Accuracy ({card.times_seen} plays)</span>
                  </div>
                ) : (
                  <div className="absolute top-3 right-3 bg-slate-900/80 backdrop-blur-xs text-slate-300 text-xs font-medium px-2.5 py-1 rounded-full shadow">
                    New Card
                  </div>
                )}
              </div>

              {/* Card Question & Choices Info */}
              <div className="p-5 flex-1 flex flex-col justify-between">
                <div>
                  <h2 className="text-base font-bold text-slate-900 mb-3 leading-snug">
                    {card.question_prompt}
                  </h2>

                  <div className="space-y-1.5 text-xs mb-4">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md">
                        Correct:
                      </span>
                      <span className="font-bold text-slate-800">{card.correct_choice}</span>
                    </div>

                    <div className="flex items-start gap-2">
                      <span className="font-bold text-slate-500 bg-slate-100 px-2 py-0.5 rounded-md shrink-0">
                        Wrong:
                      </span>
                      <span className="text-slate-600">
                        {card.wrong_choices.join(', ')}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Actions Footer */}
                <div className="pt-3 border-t border-slate-100 flex items-center justify-between">
                  {activeTab === 'active' ? (
                    <>
                      <button
                        onClick={() => {
                          setEditingCard(card);
                          setIsAddModalOpen(true);
                        }}
                        className="text-xs font-bold text-slate-700 hover:text-blue-600 flex items-center gap-1.5 py-1 px-2 rounded-lg hover:bg-slate-50 cursor-pointer"
                      >
                        <Edit2 className="w-3.5 h-3.5" />
                        <span>Edit</span>
                      </button>

                      <button
                        onClick={() => setConfirmDeleteCard(card)}
                        className="text-xs font-bold text-slate-400 hover:text-rose-600 flex items-center gap-1.5 py-1 px-2 rounded-lg hover:bg-rose-50 cursor-pointer"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        <span>Remove</span>
                      </button>
                    </>
                  ) : (
                    <>
                      <button
                        onClick={() => handleRestore(card)}
                        className="text-xs font-bold text-blue-600 hover:text-blue-800 flex items-center gap-1.5 py-1 px-2 rounded-lg hover:bg-blue-50 cursor-pointer"
                      >
                        <RotateCcw className="w-3.5 h-3.5" />
                        <span>Restore to Rotation</span>
                      </button>

                      <button
                        onClick={() => setConfirmPermanentCard(card)}
                        className="text-xs font-bold text-rose-600 hover:text-rose-800 flex items-center gap-1.5 py-1 px-2 rounded-lg hover:bg-rose-50 cursor-pointer"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        <span>Delete Forever</span>
                      </button>
                    </>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add / Edit Card Modal */}
      {isAddModalOpen && (
        <AddEditCardModal
          elder={elder}
          editingCard={editingCard}
          onClose={() => {
            setIsAddModalOpen(false);
            setEditingCard(null);
          }}
          onSaved={() => {
            setIsAddModalOpen(false);
            setEditingCard(null);
            loadCards();
          }}
        />
      )}

      {/* Confirmation Soft Delete Modal */}
      {confirmDeleteCard && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl p-6 sm:p-8 max-w-md w-full shadow-2xl border border-slate-200 text-center">
            <Trash2 className="w-12 h-12 text-rose-500 mx-auto mb-3" />
            <h3 className="text-xl font-bold text-slate-900 mb-2">
              Remove card from game?
            </h3>
            <p className="text-sm text-slate-600 mb-6">
              This card will immediately stop appearing in {elder.display_name}'s game sessions. Historical statistics will be preserved and you can restore it anytime from Trash.
            </p>
            <div className="flex gap-3 justify-center">
              <button
                onClick={() => setConfirmDeleteCard(null)}
                className="px-5 py-2.5 rounded-xl border border-slate-300 text-slate-700 font-bold text-sm hover:bg-slate-100 cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={() => handleSoftDelete(confirmDeleteCard)}
                className="px-5 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold text-sm shadow cursor-pointer"
              >
                Yes, Remove Card
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Confirmation Permanent Delete Modal */}
      {confirmPermanentCard && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl p-6 sm:p-8 max-w-md w-full shadow-2xl border border-slate-200 text-center">
            <AlertCircle className="w-12 h-12 text-rose-600 mx-auto mb-3" />
            <h3 className="text-xl font-bold text-slate-900 mb-2">
              Delete card permanently?
            </h3>
            <p className="text-sm text-slate-600 mb-6">
              This action cannot be undone. All records for this card will be permanently erased.
            </p>
            <div className="flex gap-3 justify-center">
              <button
                onClick={() => setConfirmPermanentCard(null)}
                className="px-5 py-2.5 rounded-xl border border-slate-300 text-slate-700 font-bold text-sm hover:bg-slate-100 cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={() => handlePermanentDelete(confirmPermanentCard)}
                className="px-5 py-2.5 rounded-xl bg-rose-700 hover:bg-rose-800 text-white font-bold text-sm shadow cursor-pointer"
              >
                Permanently Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
