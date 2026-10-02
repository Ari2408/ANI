// API Client for Memory Snap Backend

export interface Elder {
  id: string;
  caregiver_id: string;
  display_name: string;
  birth_year: number | null;
  avatar_url: string;
  pin_code: string | null;
  has_pin: boolean;
  difficulty_level: 'easy' | 'medium' | 'hard';
  reveal_duration_seconds: number;
  rounds_per_session: number;
  created_at: string;
  active_card_count?: number;
  total_sessions?: number;
  recent_accuracy?: number;
  total_answers?: number;
  avg_response_time_sec?: number | null;
}

export interface Card {
  id: string;
  elder_id: string;
  caregiver_id: string;
  photo_url: string;
  thumbnail_url: string;
  question_prompt: string;
  correct_choice: string;
  wrong_choices: string[];
  is_active: boolean;
  created_at: string;
  updated_at: string;
  times_seen?: number;
  times_correct?: number;
  accuracy?: number | null;
  avg_time_sec?: number | null;
}

export interface PlaySessionData {
  session_id: string;
  elder: {
    id: string;
    display_name: string;
    avatar_url: string;
    difficulty_level: string;
  };
  reveal_duration_seconds: number;
  round_count: number;
  rounds: {
    card_id: string;
    photo_url: string;
    question_prompt: string;
    choices: string[];
  }[];
}

export interface SessionSummary {
  session_id: string;
  elder_id: string;
  total_rounds: number;
  correct_count: number;
  stars: number;
  warm_title: string;
  warm_subtitle: string;
  avg_response_time_sec: number;
}

export interface ElderStats {
  elder: {
    id: string;
    display_name: string;
    difficulty_level: string;
    reveal_duration_seconds: number;
  };
  overall: {
    total_sessions: number;
    total_answers: number;
    accuracy_percentage: number;
    avg_response_time_sec: number;
    current_streak_days: number;
    active_card_count: number;
  };
  daily_trend: {
    date: string;
    accuracy: number;
    avg_response_time_sec: number;
    answers_count: number;
  }[];
  session_dates: string[];
  card_breakdown: {
    id: string;
    question_prompt: string;
    photo_url: string;
    is_active: boolean;
    times_asked: number;
    times_correct: number;
    accuracy: number | null;
    avg_time_sec: number | null;
    needs_attention: boolean;
  }[];
  weekly_digest: string;
  low_library_alert: string | null;
}

const API_BASE = '/api';

export const api = {
  // Elders
  async getElders(): Promise<Elder[]> {
    const res = await fetch(`${API_BASE}/elders`);
    if (!res.ok) throw new Error('Failed to fetch elders');
    const data = await res.json();
    return data.elders;
  },

  async getElder(id: string): Promise<Elder> {
    const res = await fetch(`${API_BASE}/elders/${id}`);
    if (!res.ok) throw new Error('Failed to fetch elder');
    const data = await res.json();
    return data.elder;
  },

  async createElder(payload: Partial<Elder>): Promise<Elder> {
    const res = await fetch(`${API_BASE}/elders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    if (!res.ok) throw new Error('Failed to create elder profile');
    const data = await res.json();
    return data.elder;
  },

  async updateElder(id: string, payload: Partial<Elder>): Promise<Elder> {
    const res = await fetch(`${API_BASE}/elders/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    if (!res.ok) throw new Error('Failed to update elder profile');
    const data = await res.json();
    return data.elder;
  },

  async deleteElder(id: string): Promise<void> {
    const res = await fetch(`${API_BASE}/elders/${id}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Failed to delete elder profile');
  },

  async verifyPin(elderId: string, pin: string): Promise<boolean> {
    const res = await fetch(`${API_BASE}/elders/${elderId}/verify-pin`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pin })
    });
    if (!res.ok) return false;
    const data = await res.json();
    return Boolean(data.valid);
  },

  // Cards
  async getCards(elderId: string, status: 'active' | 'trash' | 'all' = 'active'): Promise<Card[]> {
    const res = await fetch(`${API_BASE}/cards/elder/${elderId}?status=${status}`);
    if (!res.ok) throw new Error('Failed to fetch cards');
    const data = await res.json();
    return data.cards;
  },

  async uploadPhoto(file: File): Promise<{ photo_url: string; thumbnail_url: string }> {
    const formData = new FormData();
    formData.append('photo', file);
    const res = await fetch(`${API_BASE}/cards/upload`, {
      method: 'POST',
      body: formData
    });
    if (!res.ok) throw new Error('Failed to upload image');
    return res.json();
  },

  async createCard(payload: {
    elder_id: string;
    photo_url: string;
    thumbnail_url?: string;
    question_prompt: string;
    correct_choice: string;
    wrong_choices: string[];
  }): Promise<Card> {
    const res = await fetch(`${API_BASE}/cards`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    if (!res.ok) throw new Error('Failed to save card');
    const data = await res.json();
    return data.card;
  },

  async updateCard(id: string, payload: Partial<Card>): Promise<Card> {
    const res = await fetch(`${API_BASE}/cards/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });
    if (!res.ok) throw new Error('Failed to update card');
    const data = await res.json();
    return data.card;
  },

  async deleteCard(id: string): Promise<void> {
    const res = await fetch(`${API_BASE}/cards/${id}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Failed to delete card');
  },

  async restoreCard(id: string): Promise<void> {
    const res = await fetch(`${API_BASE}/cards/${id}/restore`, { method: 'POST' });
    if (!res.ok) throw new Error('Failed to restore card');
  },

  async deleteCardPermanent(id: string): Promise<void> {
    const res = await fetch(`${API_BASE}/cards/${id}/permanent`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Failed to permanently delete card');
  },

  // Play Session
  async startSession(elderId: string): Promise<PlaySessionData> {
    const res = await fetch(`${API_BASE}/play/${elderId}/session`);
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.error || 'Failed to start session');
    }
    return res.json();
  },

  async submitAnswer(elderId: string, sessionId: string, cardId: string, choice: string, timeMs: number): Promise<{
    is_correct: boolean;
    correct_choice: string;
    gentle_message: string;
  }> {
    const res = await fetch(`${API_BASE}/play/${elderId}/session/${sessionId}/answer`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        card_id: cardId,
        selected_choice: choice,
        response_time_ms: timeMs
      })
    });
    if (!res.ok) throw new Error('Failed to submit answer');
    return res.json();
  },

  async completeSession(elderId: string, sessionId: string): Promise<{ summary: SessionSummary }> {
    const res = await fetch(`${API_BASE}/play/${elderId}/session/${sessionId}/complete`, {
      method: 'POST'
    });
    if (!res.ok) throw new Error('Failed to complete session');
    return res.json();
  },

  // Stats & Reports
  async getStats(elderId: string): Promise<ElderStats> {
    const res = await fetch(`${API_BASE}/stats/${elderId}`);
    if (!res.ok) throw new Error('Failed to fetch stats');
    return res.json();
  },

  async getExportSummary(elderId: string) {
    const res = await fetch(`${API_BASE}/export/${elderId}/summary`);
    if (!res.ok) throw new Error('Failed to fetch summary');
    return res.json();
  },

  getExportCsvUrl(elderId: string): string {
    return `${API_BASE}/export/${elderId}/csv`;
  }
};
