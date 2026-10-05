import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/step_tracker_service.dart';
import '../services/i18n_service.dart';
import '../screens/elder_activity_screen.dart';
import 'elder_card.dart';

class CaregiverActivityCard extends StatelessWidget {
  final String elderName;
  final String elderId;

  const CaregiverActivityCard({
    Key? key,
    required this.elderName,
    required this.elderId,
  }) : super(key: key);

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final stepTracker = Provider.of<StepTrackerService>(context);
    final i18n = Provider.of<I18nService>(context);

    final today = stepTracker.todayRecord;
    final average = stepTracker.calculateSevenDayAverage();
    final lastUpdated = stepTracker.formatLastUpdatedString();

    return ElderCard(
      backgroundColor: Colors.white,
      border: Border.all(color: const Color(0xFF61C5B0).withOpacity(0.5), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Elder Activity + Sync indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_walk,
                      color: Color(0xFF23B39B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.translate('elderActivityTitle'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2824),
                        ),
                      ),
                      Text(
                        elderName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF23B39B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _buildSyncStatusBadge(stepTracker.syncStatus),
                  IconButton(
                    icon: stepTracker.isSyncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF23B39B)),
                          )
                        : const Icon(Icons.sync, size: 20, color: Color(0xFF23B39B)),
                    tooltip: i18n.translate('syncNowBtn'),
                    onPressed: stepTracker.isSyncing
                        ? null
                        : () => stepTracker.fetchCaregiverElderActivity(elderId),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Today's Steps and Goal Progress
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(today.steps),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2824),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                i18n.translate('stepsLabel'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF23B39B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${i18n.translate("dailyGoal")}: ${_formatNumber(today.goal)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2824),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: today.progressRatio,
              minHeight: 10,
              backgroundColor: const Color(0xFFE6F4F1),
              valueColor: AlwaysStoppedAnimation<Color>(
                today.isGoalCompleted ? const Color(0xFF16A34A) : const Color(0xFF23B39B),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${i18n.translate("progressLabel")}: ${today.progressPercent}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF555555)),
              ),
              if (today.isGoalCompleted)
                Text(
                  i18n.translate('goalCompletedBadge'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Metric Details: Daily Average & Last Synced
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      i18n.translate('sevenDayAverage'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                    Text(
                      '${_formatNumber(average)} ${i18n.translate("stepsLabel")}/day',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1B2824)),
                    ),
                  ],
                ),
                const Divider(height: 12, color: Color(0xFFE5E7EB)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      i18n.translate('lastSyncedLabel'),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                    Row(
                      children: [
                        Icon(
                          stepTracker.syncStatus == StepTrackerSyncStatus.offline
                              ? Icons.cloud_off
                              : (stepTracker.syncStatus == StepTrackerSyncStatus.syncing
                                  ? Icons.cloud_sync
                                  : Icons.cloud_done),
                          size: 13,
                          color: stepTracker.syncStatus == StepTrackerSyncStatus.offline
                              ? const Color(0xFFEF4444)
                              : (stepTracker.syncStatus == StepTrackerSyncStatus.syncing
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lastUpdated,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Button: View Activity History & Trends
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23B39B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ElderActivityScreen(
                      isCaregiverView: true,
                      elderId: elderId,
                      elderName: elderName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.history, color: Colors.white, size: 18),
              label: Text(
                i18n.translate('viewActivityHistoryBtn'),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBadge(StepTrackerSyncStatus status) {
    Color dotColor;
    String label;
    Color textColor;
    Color bgColor;

    switch (status) {
      case StepTrackerSyncStatus.live:
        dotColor = const Color(0xFF16A34A);
        label = 'Live';
        textColor = const Color(0xFF15803D);
        bgColor = const Color(0xFFDCFCE7);
        break;
      case StepTrackerSyncStatus.syncing:
        dotColor = const Color(0xFFD97706);
        label = 'Syncing...';
        textColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case StepTrackerSyncStatus.offline:
        dotColor = const Color(0xFFDC2626);
        label = 'Offline';
        textColor = const Color(0xFFB91C1C);
        bgColor = const Color(0xFFFEE2E2);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
