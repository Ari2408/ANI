import React from 'react';
import { Elder } from '../../services/api';
import { Play, LayoutDashboard, Image as ImageIcon, Users, FileText, UserCircle } from 'lucide-react';

interface Props {
  elders: Elder[];
  selectedElder: Elder | null;
  onSelectElder: (elder: Elder) => void;
  currentTab: 'dashboard' | 'library' | 'elders' | 'reports';
  onSelectTab: (tab: 'dashboard' | 'library' | 'elders' | 'reports') => void;
  onLaunchElderMode: () => void;
}

export const CaregiverNav: React.FC<Props> = ({
  elders,
  selectedElder,
  onSelectElder,
  currentTab,
  onSelectTab,
  onLaunchElderMode
}) => {
  return (
    <header className="bg-white border-b border-slate-200 sticky top-0 z-30 shadow-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-18">
          {/* Logo & Elder Switcher */}
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-blue-600 flex items-center justify-center text-white font-black text-xl shadow-sm">
                MS
              </div>
              <div>
                <h1 className="text-xl font-bold text-slate-900 leading-tight">
                  Memory Snap
                </h1>
                <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Caregiver Portal
                </span>
              </div>
            </div>

            {/* Elder Selector Dropdown */}
            {selectedElder && (
              <div className="hidden sm:flex items-center gap-2 bg-slate-100/90 py-1.5 px-3 rounded-2xl border border-slate-200">
                <img
                  src={selectedElder.avatar_url}
                  alt={selectedElder.display_name}
                  className="w-7 h-7 rounded-full object-cover bg-amber-100"
                />
                <select
                  value={selectedElder.id}
                  onChange={e => {
                    const found = elders.find(el => el.id === e.target.value);
                    if (found) onSelectElder(found);
                  }}
                  className="bg-transparent font-bold text-sm text-slate-800 focus:outline-none cursor-pointer pr-1"
                >
                  {elders.map(elder => (
                    <option key={elder.id} value={elder.id}>
                      {elder.display_name} ({elder.difficulty_level})
                    </option>
                  ))}
                </select>
              </div>
            )}
          </div>

          {/* Navigation Links */}
          <nav className="flex items-center gap-1 sm:gap-2">
            <button
              onClick={() => onSelectTab('dashboard')}
              className={`px-3 sm:px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition-colors cursor-pointer ${
                currentTab === 'dashboard'
                  ? 'bg-blue-50 text-blue-700'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <LayoutDashboard className="w-4 h-4" />
              <span>Dashboard</span>
            </button>

            <button
              onClick={() => onSelectTab('library')}
              className={`px-3 sm:px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition-colors cursor-pointer ${
                currentTab === 'library'
                  ? 'bg-blue-50 text-blue-700'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <ImageIcon className="w-4 h-4" />
              <span>Content Library</span>
            </button>

            <button
              onClick={() => onSelectTab('elders')}
              className={`px-3 sm:px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition-colors cursor-pointer ${
                currentTab === 'elders'
                  ? 'bg-blue-50 text-blue-700'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <Users className="w-4 h-4" />
              <span>Elder Profiles</span>
            </button>

            <button
              onClick={() => onSelectTab('reports')}
              className={`px-3 sm:px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition-colors cursor-pointer ${
                currentTab === 'reports'
                  ? 'bg-blue-50 text-blue-700'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <FileText className="w-4 h-4" />
              <span>Reports</span>
            </button>
          </nav>

          {/* Elder Mode Launch Button */}
          <div className="flex items-center gap-3">
            <button
              onClick={onLaunchElderMode}
              className="bg-emerald-600 hover:bg-emerald-700 active:bg-emerald-800 text-white font-bold px-4 py-2.5 rounded-xl text-sm shadow-sm hover:shadow flex items-center gap-2 transition-all cursor-pointer"
            >
              <Play className="w-4 h-4 fill-current" />
              <span>Launch Elder Mode</span>
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};
