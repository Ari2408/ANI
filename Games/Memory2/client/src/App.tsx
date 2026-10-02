import React, { useEffect, useState } from 'react';
import { Elder, api } from './services/api';
import { ElderProfileSelect } from './components/elder/ElderProfileSelect';
import { ElderGameContainer } from './components/elder/ElderGameContainer';
import { CaregiverContainer } from './components/caregiver/CaregiverContainer';
import { Loader2 } from 'lucide-react';

export function App() {
  const [mode, setMode] = useState<'elder-select' | 'elder-play' | 'caregiver'>('elder-select');
  const [elders, setElders] = useState<Elder[]>([]);
  const [selectedElder, setSelectedElder] = useState<Elder | null>(null);
  const [loading, setLoading] = useState(true);

  // Sync mode with URL hash if present (#caregiver, #play)
  useEffect(() => {
    const handleHash = () => {
      const hash = window.location.hash.toLowerCase();
      if (hash.includes('caregiver')) {
        setMode('caregiver');
      } else if (hash.includes('play')) {
        setMode('elder-select');
      }
    };
    handleHash();
    window.addEventListener('hashchange', handleHash);
    return () => window.removeEventListener('hashchange', handleHash);
  }, []);

  useEffect(() => {
    loadElders();
  }, []);

  const loadElders = async () => {
    setLoading(true);
    try {
      const list = await api.getElders();
      setElders(list);

      // Restore saved elder or default to first
      const savedElderId = localStorage.getItem('memory_snap_elder_id');
      if (savedElderId) {
        const found = list.find(e => e.id === savedElderId);
        if (found) {
          setSelectedElder(found);
        } else if (list.length > 0) {
          setSelectedElder(list[0]);
        }
      } else if (list.length > 0) {
        setSelectedElder(list[0]);
      }
    } catch (err) {
      console.error('Failed to load elders', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSelectElder = (elder: Elder) => {
    setSelectedElder(elder);
    localStorage.setItem('memory_snap_elder_id', elder.id);
    setMode('elder-play');
    window.location.hash = '#play';
  };

  const handleSwitchModeToCaregiver = () => {
    setMode('caregiver');
    window.location.hash = '#caregiver';
  };

  const handleSwitchModeToElderSelect = () => {
    setMode('elder-select');
    window.location.hash = '#play';
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-amber-50 flex flex-col items-center justify-center p-6 text-center">
        <Loader2 className="w-16 h-16 text-blue-600 animate-spin mb-4" />
        <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight">
          Loading Memory Snap...
        </h1>
      </div>
    );
  }

  // 1. Elder Profile Select (Shared family tablet or profile switch)
  if (mode === 'elder-select') {
    return (
      <ElderProfileSelect
        elders={elders}
        onSelect={handleSelectElder}
        onOpenCaregiver={handleSwitchModeToCaregiver}
      />
    );
  }

  // 2. Elder Gameplay Mode (Distraction-free, large touch targets, gentle audio)
  if (mode === 'elder-play' && selectedElder) {
    return (
      <ElderGameContainer
        elder={selectedElder}
        onSwitchProfile={handleSwitchModeToElderSelect}
      />
    );
  }

  // 3. Caregiver Portal (Content management, telemetry, settings, and clinical reports)
  return (
    <CaregiverContainer
      elders={elders}
      selectedElder={selectedElder}
      onSelectElder={elder => {
        setSelectedElder(elder);
        localStorage.setItem('memory_snap_elder_id', elder.id);
      }}
      onRefreshElders={loadElders}
      onLaunchElderMode={() => {
        if (selectedElder) {
          setMode('elder-play');
          window.location.hash = '#play';
        } else {
          setMode('elder-select');
          window.location.hash = '#play';
        }
      }}
    />
  );
}

export default App;
