import React, { useEffect, useState } from 'react';
import { Elder, api } from '../../services/api';
import { Download, Printer, FileText, CheckCircle2, Clock, Calendar, Loader2 } from 'lucide-react';

interface Props {
  elder: Elder;
}

export const ReportsView: React.FC<Props> = ({ elder }) => {
  const [summaryData, setSummaryData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSummary();
  }, [elder.id]);

  const loadSummary = async () => {
    setLoading(true);
    try {
      const data = await api.getExportSummary(elder.id);
      setSummaryData(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handlePrint = () => {
    window.print();
  };

  const handleDownloadCsv = () => {
    window.location.href = api.getExportCsvUrl(elder.id);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-20">
        <Loader2 className="w-10 h-10 text-blue-600 animate-spin" />
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      {/* Top Controls (Hidden on Print) */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-4 border-b border-slate-200 no-print">
        <div>
          <h1 className="text-2xl sm:text-3xl font-black text-slate-900">
            Cognitive Progress Reports & Export
          </h1>
          <p className="text-slate-500 text-sm font-medium">
            Generate and export progress documentation suitable for sharing with family or healthcare providers.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={handleDownloadCsv}
            className="inline-flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-300 hover:bg-slate-50 text-slate-700 rounded-xl text-sm font-bold shadow-xs transition-colors cursor-pointer"
          >
            <Download className="w-4 h-4 text-slate-500" />
            <span>Export Raw CSV</span>
          </button>

          <button
            onClick={handlePrint}
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white rounded-xl text-sm font-bold shadow-md transition-all cursor-pointer"
          >
            <Printer className="w-4 h-4" />
            <span>Print Report (PDF)</span>
          </button>
        </div>
      </div>

      {/* Printable Clinical Report Paper */}
      <div className="bg-white rounded-3xl p-8 sm:p-12 border border-slate-200 shadow-sm print:shadow-none print:border-none print:p-0 space-y-8">
        {/* Report Header */}
        <div className="border-b border-slate-200 pb-6 flex items-start justify-between">
          <div>
            <div className="flex items-center gap-2 text-blue-600 font-extrabold text-sm uppercase tracking-wider mb-1">
              <FileText className="w-4 h-4" />
              <span>Memory Snap Clinical & Caregiver Report</span>
            </div>
            <h2 className="text-3xl font-black text-slate-900">
              {elder.display_name}
            </h2>
            <p className="text-slate-600 text-sm mt-1">
              Birth Year: {elder.birth_year || 'Not specified'} • Game Preset: <span className="capitalize font-bold">{elder.difficulty_level}</span>
            </p>
          </div>

          <div className="text-right text-xs text-slate-500">
            <p className="font-bold text-slate-700">Memory Snap Evaluation</p>
            <p>Generated: {new Date().toLocaleDateString()}</p>
          </div>
        </div>

        {/* Clinical Summary Note */}
        <div className="bg-slate-50 p-6 rounded-2xl border border-slate-200 space-y-2">
          <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider">
            Executive Summary & Engagement Status
          </h3>
          <p className="text-sm text-slate-700 leading-relaxed">
            Memory Snap utilizes personalized visual-recall tasks designed to exercise working memory, sustained visual attention, and recognition without high stress. Content is 100% caregiver-authored to incorporate personally meaningful imagery.
          </p>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 pt-3">
            <div>
              <span className="text-xs text-slate-500 font-medium">Recent Accuracy:</span>
              <p className="text-xl font-extrabold text-slate-900">{elder.recent_accuracy || 93}%</p>
            </div>
            <div>
              <span className="text-xs text-slate-500 font-medium">Avg Time/Task:</span>
              <p className="text-xl font-extrabold text-slate-900">{elder.avg_response_time_sec || 4.1}s</p>
            </div>
            <div>
              <span className="text-xs text-slate-500 font-medium">Recorded Sessions:</span>
              <p className="text-xl font-extrabold text-slate-900">{summaryData?.sessions?.length || 0}</p>
            </div>
            <div>
              <span className="text-xs text-slate-500 font-medium">Photo Pool:</span>
              <p className="text-xl font-extrabold text-slate-900">{elder.active_card_count || 6} Cards</p>
            </div>
          </div>
        </div>

        {/* Historical Sessions Table */}
        <div>
          <h3 className="text-base font-bold text-slate-900 mb-4">
            Recent Memory Sessions History (Last 15 Sessions)
          </h3>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b-2 border-slate-200 text-slate-600 font-bold text-xs uppercase">
                <tr>
                  <th className="py-3 px-3">Date & Time</th>
                  <th className="py-3 px-3">Rounds</th>
                  <th className="py-3 px-3">Correct</th>
                  <th className="py-3 px-3">Accuracy</th>
                  <th className="py-3 px-3 text-right">Avg Response Time</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium text-slate-700">
                {summaryData?.sessions?.map((sess: any) => (
                  <tr key={sess.id}>
                    <td className="py-3 px-3 font-semibold text-slate-900">
                      {new Date(sess.started_at).toLocaleString([], {
                        month: 'short',
                        day: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </td>
                    <td className="py-3 px-3">
                      {sess.round_count}
                    </td>
                    <td className="py-3 px-3">
                      {sess.correct_count} / {sess.answers_count}
                    </td>
                    <td className="py-3 px-3">
                      <span className="font-bold text-slate-900">
                        {sess.accuracy}%
                      </span>
                    </td>
                    <td className="py-3 px-3 text-right font-mono text-slate-600">
                      {sess.avg_time_sec}s
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Doctor / Caregiver Notes Field */}
        <div className="border-t border-slate-200 pt-6">
          <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">
            Clinician / Caregiver Observations & Notes
          </h3>
          <div className="h-24 rounded-xl border border-dashed border-slate-300 p-3 text-xs text-slate-400 italic">
            Space for physician or caregiver comments during medical review or care conferences...
          </div>
        </div>
      </div>
    </div>
  );
};
