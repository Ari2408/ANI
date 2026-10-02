import React, { useState } from 'react';
import { Elder } from '../../services/api';
import { CaregiverNav } from './CaregiverNav';
import { DashboardView } from './DashboardView';
import { ContentLibraryView } from './ContentLibraryView';
import { ElderProfilesView } from './ElderProfilesView';
import { ReportsView } from './ReportsView';
import { AddEditCardModal } from './AddEditCardModal';

interface Props {
  elders: Elder[];
  selectedElder: Elder | null;
  onSelectElder: (elder: Elder) => void;
  onRefreshElders: () => void;
  onLaunchElderMode: () => void;
}

export const CaregiverContainer: React.FC<Props> = ({
  elders,
  selectedElder,
  onSelectElder,
  onRefreshElders,
  onLaunchElderMode
}) => {
  const [currentTab, setCurrentTab] = useState<'dashboard' | 'library' | 'elders' | 'reports'>('dashboard');
  const [isQuickAddOpen, setIsQuickAddOpen] = useState(false);

  // If no elder is selected, pick first available
  const activeElder = selectedElder || elders[0] || null;

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex flex-col">
      {/* Navigation */}
      <CaregiverNav
        elders={elders}
        selectedElder={activeElder}
        onSelectElder={onSelectElder}
        currentTab={currentTab}
        onSelectTab={setCurrentTab}
        onLaunchElderMode={onLaunchElderMode}
      />

      {/* Main Tab Content */}
      <main className="flex-1 pb-16">
        {activeElder ? (
          <>
            {currentTab === 'dashboard' && (
              <DashboardView
                elder={activeElder}
                onNavigateToLibrary={() => setCurrentTab('library')}
                onOpenAddCard={() => setIsQuickAddOpen(true)}
              />
            )}

            {currentTab === 'library' && (
              <ContentLibraryView
                elder={activeElder}
              />
            )}

            {currentTab === 'elders' && (
              <ElderProfilesView
                elders={elders}
                selectedElder={activeElder}
                onSelectElder={onSelectElder}
                onRefreshElders={onRefreshElders}
              />
            )}

            {currentTab === 'reports' && (
              <ReportsView
                elder={activeElder}
              />
            )}
          </>
        ) : (
          <div className="text-center p-16 text-slate-500">
            No elder profiles found. Please create one.
          </div>
        )}
      </main>

      {/* Global Quick Add Card Modal */}
      {isQuickAddOpen && activeElder && (
        <AddEditCardModal
          elder={activeElder}
          onClose={() => setIsQuickAddOpen(false)}
          onSaved={() => {
            setIsQuickAddOpen(false);
            onRefreshElders();
          }}
        />
      )}
    </div>
  );
};
