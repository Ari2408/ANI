import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/step_tracker_service.dart';
import '../services/i18n_service.dart';
import '../screens/elder_activity_screen.dart';
import 'elder_card.dart';

class ElderStepTrackerCard extends StatelessWidget {
  const ElderStepTrackerCard({Key? key}) : super(key: key);

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
    final history = stepTracker.dailyHistory;
    final average = stepTracker.calculateSevenDayAverage();

    return ElderCard(
      backgroundColor: Colors.white,
      border: Border.all(color: const Color(0xFF61C5B0).withOpacity(0.5), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with Title and Tracking Status Badge
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
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    i18n.translate('todayActivity'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2824),
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(context, stepTracker, i18n),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Hardware Sensor Not Supported Handling
          if (!stepTracker.isSensorAvailable) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF87171)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      i18n.translate('stepTrackingNotSupported'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]
          // 3. Permission Required Handling
          else if (!stepTracker.hasPermission) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          i18n.translate('activityPermRequired'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23B39B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => stepTracker.requestActivityPermission(),
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: Text(
                        i18n.translate('allowActivityTracking'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]
          // 4. Normal Active Step Counting View
          else ...[
            // Main Big Steps Count
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatNumber(today.steps),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B2824),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  i18n.translate('stepsLabel'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF23B39B),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showGoalDialog(context, stepTracker, i18n),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4F1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF61C5B0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined, size: 14, color: Color(0xFF23B39B)),
                        const SizedBox(width: 4),
                        Text(
                          '${i18n.translate("dailyGoal")}: ${_formatNumber(today.goal)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2824),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress Bar & Percentage
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${i18n.translate("progressLabel")}: ${today.progressPercent}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555555),
                      ),
                    ),
                    Text(
                      '${_formatNumber(today.steps)} / ${_formatNumber(today.goal)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: today.progressRatio,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFE6F4F1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      today.isGoalCompleted ? const Color(0xFF16A34A) : const Color(0xFF23B39B),
                    ),
                  ),
                ),
              ],
            ),

            // Goal Completed Alert Banner
            if (today.isGoalCompleted) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF16A34A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        i18n.translate('goalCompleted'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Metric Summary Boxes: Distance, Active Time, Calories
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.straighten,
                    label: i18n.translate('estimatedDistance'),
                    value: '${today.distanceKm.toStringAsFixed(1)} km',
                    color: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFF0F9FF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.timer_outlined,
                    label: i18n.translate('activeMinutes'),
                    value: '${today.activeMinutes} min',
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.local_fire_department_outlined,
                    label: i18n.translate('estimatedCalories'),
                    value: '${today.calories} kcal',
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEF2F2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Time-of-Day Step Breakdown (Morning, Afternoon, Evening)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i18n.translate('timeOfDayActivity'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTimeBin(
                        label: i18n.translate('morningSteps'),
                        steps: today.morningSteps,
                        icon: Icons.wb_sunny_outlined,
                        color: const Color(0xFFF59E0B),
                      ),
                      Container(width: 1, height: 28, color: const Color(0xFFE5E7EB)),
                      _buildTimeBin(
                        label: i18n.translate('afternoonSteps'),
                        steps: today.afternoonSteps,
                        icon: Icons.sunny,
                        color: const Color(0xFFEA580C),
                      ),
                      Container(width: 1, height: 28, color: const Color(0xFFE5E7EB)),
                      _buildTimeBin(
                        label: i18n.translate('eveningSteps'),
                        steps: today.eveningSteps,
                        icon: Icons.nights_stay_outlined,
                        color: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Recent Days Quick Preview & Daily Average
            if (history.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF61C5B0).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    ...history.take(2).map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatHistoryDate(item.date),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${_formatNumber(item.steps)} ${i18n.translate("stepsLabel")}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF23B39B)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 14, color: Color(0xFFCDE4E2)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          i18n.translate('sevenDayAverage'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
                        ),
                        Text(
                          '${_formatNumber(average)} ${i18n.translate("stepsLabel")}/day',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1B2824)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Button: View Activity History & Trends
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF23B39B),
                  side: const BorderSide(color: Color(0xFF23B39B), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFFFDF0E6),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ElderActivityScreen(
                        isCaregiverView: false,
                        elderId: stepTracker.activeElderId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart, size: 20),
                label: Text(
                  i18n.translate('viewActivityHistory'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, StepTrackerService stepTracker, I18nService i18n) {
    if (!stepTracker.isSensorAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          i18n.translate('unsupportedBadge'),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
        ),
      );
    }

    if (!stepTracker.hasPermission) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          i18n.translate('permissionRequiredBadge'),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
        ),
      );
    }

    final isActive = stepTracker.isTrackingActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? const Color(0xFF86EFAC) : const Color(0xFFD1D5DB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF16A34A) : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? i18n.translate('activeStatus') : i18n.translate('pausedStatus'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF166534) : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBin({
    required String label,
    required int steps,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _formatNumber(steps),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
        ),
      ],
    );
  }

  String _formatHistoryDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt).inDays;
      if (diff == 1) return 'Yesterday';
      if (diff == 2) return '2 days ago';
      if (diff == 3) return '3 days ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showGoalDialog(BuildContext context, StepTrackerService stepTracker, I18nService i18n) {
    int selected = stepTracker.dailyGoal;
    final options = [4000, 6000, 8000, 10000, 12000, 15000];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            i18n.translate('configureStepGoalTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                i18n.translate('selectDailyStepTargetDesc'),
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((g) {
                  final isSel = selected == g;
                  return ChoiceChip(
                    label: Text('${_formatNumber(g)} ${i18n.translate("stepsLabel")}'),
                    selected: isSel,
                    selectedColor: const Color(0xFF61C5B0),
                    onSelected: (val) {
                      if (val) setDlgState(() => selected = g);
                    },
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF1B2824),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(i18n.translate('cancelBtn')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF23B39B)),
              onPressed: () {
                stepTracker.setDailyGoal(selected);
                Navigator.pop(ctx);
              },
              child: Text(i18n.translate('saveBtn'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
