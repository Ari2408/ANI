import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/step_tracker_service.dart';
import '../services/i18n_service.dart';
import '../models/daily_activity_record.dart';
import '../widgets/elder_card.dart';

class ElderActivityScreen extends StatefulWidget {
  final bool isCaregiverView;
  final String elderId;
  final String? elderName;

  const ElderActivityScreen({
    Key? key,
    required this.isCaregiverView,
    required this.elderId,
    this.elderName,
  }) : super(key: key);

  @override
  State<ElderActivityScreen> createState() => _ElderActivityScreenState();
}

class _ElderActivityScreenState extends State<ElderActivityScreen> {
  DailyActivityRecord? _selectedDateRecord;

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepTracker = Provider.of<StepTrackerService>(context);
    final i18n = Provider.of<I18nService>(context);

    final today = stepTracker.todayRecord;
    final history = stepTracker.dailyHistory;
    final weekly = stepTracker.getWeeklySummary();
    final monthly = stepTracker.getMonthlySummary();

    final sevenDayAvg = stepTracker.calculateSevenDayAverage();
    final thirtyDayAvg = stepTracker.calculateThirtyDayAverage();
    final overallAvg = stepTracker.calculateOverallAverage();

    final allRecords = <DailyActivityRecord>[
      today,
      ...history.where((h) => h.date != today.date),
    ];

    final title = widget.isCaregiverView
        ? '${widget.elderName ?? "Elder"} - ${i18n.translate("activityTracker")}'
        : i18n.translate('activityTracker');

    return Scaffold(
      backgroundColor: const Color(0xFFFDF0E6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF61C5B0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B2824)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2824),
          ),
        ),
        actions: [
          IconButton(
            icon: stepTracker.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B2824)),
                  )
                : const Icon(Icons.refresh, color: Color(0xFF1B2824)),
            tooltip: i18n.translate('refreshBtn'),
            onPressed: stepTracker.isSyncing
                ? null
                : () {
                    if (widget.isCaregiverView) {
                      stepTracker.fetchCaregiverElderActivity(widget.elderId);
                    } else {
                      stepTracker.refreshElderToday();
                    }
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (widget.isCaregiverView) {
            await stepTracker.fetchCaregiverElderActivity(widget.elderId);
          } else {
            await stepTracker.refreshElderToday();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. TODAY'S PRIMARY ACTIVITY HERO CARD
            _buildTodayHeroCard(context, stepTracker, today, i18n),

            const SizedBox(height: 8),

            // 2. MULTI-PERIOD AVERAGES CARD
            _buildAveragesCard(context, today.steps, sevenDayAvg, thirtyDayAvg, overallAvg, i18n),

            const SizedBox(height: 8),

            // 3. THIS WEEK'S SUMMARY & BAR CHART
            _buildWeeklyChartCard(context, weekly, i18n),

            const SizedBox(height: 8),

            // 4. MONTHLY ACTIVITY SUMMARY
            _buildMonthlySummaryCard(context, monthly, i18n),

            const SizedBox(height: 8),

            // 5. SELECTED DATE DETAIL POPUP / VIEW (if user tapped a date)
            if (_selectedDateRecord != null) ...[
              _buildSelectedDateCard(context, _selectedDateRecord!, i18n),
              const SizedBox(height: 8),
            ],

            // 6. DAILY ACTIVITY HISTORY TABLE
            _buildDailyHistoryCard(context, allRecords, i18n),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayHeroCard(
    BuildContext context,
    StepTrackerService stepTracker,
    DailyActivityRecord today,
    I18nService i18n,
  ) {
    return ElderCard(
      backgroundColor: Colors.white,
      border: Border.all(color: const Color(0xFF61C5B0), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                i18n.translate('todayProgressTitle'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
              ),
              if (!widget.isCaregiverView)
                TextButton.icon(
                  onPressed: () => _showGoalDialog(context, stepTracker, i18n),
                  icon: const Icon(Icons.edit, size: 14, color: Color(0xFF23B39B)),
                  label: Text(
                    i18n.translate('changeGoalBtn'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF23B39B)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Big Steps Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(today.steps),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2824),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                i18n.translate('stepsLabel'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF23B39B)),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${i18n.translate("dailyGoal")}: ${_formatNumber(today.goal)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF555555)),
                  ),
                  Text(
                    '${today.progressPercent}% ${i18n.translate("completedLabel")}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: today.isGoalCompleted ? const Color(0xFF16A34A) : const Color(0xFF23B39B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: today.progressRatio,
              minHeight: 14,
              backgroundColor: const Color(0xFFE6F4F1),
              valueColor: AlwaysStoppedAnimation<Color>(
                today.isGoalCompleted ? const Color(0xFF16A34A) : const Color(0xFF23B39B),
              ),
            ),
          ),
          if (today.isGoalCompleted) ...[
            const SizedBox(height: 8),
            Text(
              '🎉 ${i18n.translate("goalCompleted")}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
            ),
          ],
          const SizedBox(height: 16),

          // 3 Metric Pills
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.straighten,
                  title: i18n.translate('estimatedDistance'),
                  val: '${today.distanceKm.toStringAsFixed(1)} km',
                  color: const Color(0xFF0284C7),
                  bg: const Color(0xFFF0F9FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.access_time,
                  title: i18n.translate('activeMinutes'),
                  val: '${today.activeMinutes} min',
                  color: const Color(0xFFD97706),
                  bg: const Color(0xFFFFFBEB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.local_fire_department,
                  title: i18n.translate('estimatedCalories'),
                  val: '${today.calories} kcal',
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFEF2F2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Today Time-of-Day Bins
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBinCol(i18n.translate('morningSteps'), today.morningSteps, Icons.wb_sunny_outlined, const Color(0xFFF59E0B)),
                Container(width: 1, height: 26, color: const Color(0xFFE5E7EB)),
                _buildBinCol(i18n.translate('afternoonSteps'), today.afternoonSteps, Icons.sunny, const Color(0xFFEA580C)),
                Container(width: 1, height: 26, color: const Color(0xFFE5E7EB)),
                _buildBinCol(i18n.translate('eveningSteps'), today.eveningSteps, Icons.nights_stay_outlined, const Color(0xFF6366F1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAveragesCard(
    BuildContext context,
    int todaySteps,
    int sevenDayAvg,
    int thirtyDayAvg,
    int overallAvg,
    I18nService i18n,
  ) {
    return ElderCard(
      backgroundColor: Colors.white,
      border: Border.all(color: const Color(0xFFCDE4E2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Color(0xFF23B39B), size: 22),
              const SizedBox(width: 8),
              Text(
                i18n.translate('stepAveragesTitle'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            i18n.translate('stepAveragesDesc'),
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAvgBox(
                  period: i18n.translate('todayStepsLabel'),
                  steps: todaySteps,
                  color: const Color(0xFF23B39B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAvgBox(
                  period: i18n.translate('sevenDayAverage'),
                  steps: sevenDayAvg,
                  color: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAvgBox(
                  period: i18n.translate('thirtyDayAverage'),
                  steps: thirtyDayAvg,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAvgBox(
                  period: i18n.translate('overallAverage'),
                  steps: overallAvg,
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvgBox({required String period, required int steps, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatNumber(steps),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            period,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChartCard(
    BuildContext context,
    Map<String, dynamic> weekly,
    I18nService i18n,
  ) {
    final Map<int, DailyActivityRecord?> daysMap = weekly['daysMap'];
    final int totalWeekly = weekly['totalWeekly'];
    final int dailyAvg = weekly['dailyAvg'];
    final String highestDay = weekly['highestDay'];
    final int highestSteps = weekly['highestSteps'];
    final String lowestDay = weekly['lowestDay'];
    final int lowestSteps = weekly['lowestSteps'];

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Find max value for Y axis
    double maxY = 10000;
    if (highestSteps > maxY) maxY = (highestSteps * 1.2);

    return ElderCard(
      backgroundColor: Colors.white,
      border: Border.all(color: const Color(0xFFCDE4E2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                i18n.translate('thisWeekActivity'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_formatNumber(totalWeekly)} ${i18n.translate("totalSteps")}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF23B39B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Simple Bar Chart
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${dayLabels[group.x.toInt()]}\n${_formatNumber(rod.toY.toInt())} steps',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < dayLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dayLabels[idx],
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (idx) {
                  final rec = daysMap[idx];
                  final steps = rec?.steps ?? 0;
                  final isToday = rec?.date == DateTime.now().toIso8601String().substring(0, 10);

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: steps.toDouble(),
                        color: isToday
                            ? const Color(0xFF16A34A)
                            : (steps > 0 ? const Color(0xFF23B39B) : const Color(0xFFE5E7EB)),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Weekly Metrics Overview
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatText(i18n.translate('dailyAvg'), '${_formatNumber(dailyAvg)}/day'),
                Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                _buildStatText(i18n.translate('highestDay'), '$highestDay (${_formatNumber(highestSteps)})'),
                Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                _buildStatText(i18n.translate('lowestDay'), '$lowestDay (${_formatNumber(lowestSteps)})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(BuildContext context, Map<String, dynamic> monthly, I18nService i18n) {
    return ElderCard(
      backgroundColor: Colors.white,
      border: Border.all(color: const Color(0xFFCDE4E2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Color(0xFF23B39B), size: 20),
              const SizedBox(width: 8),
              Text(
                i18n.translate('monthlySummaryTitle'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMonthKpi(
                  label: i18n.translate('totalSteps'),
                  val: _formatNumber(monthly['totalSteps']),
                  sub: '${_formatNumber(monthly["dailyAvg"])} ${i18n.translate("avgPerDay")}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMonthKpi(
                  label: i18n.translate('activeDays'),
                  val: '${monthly["activeDays"]} days',
                  sub: monthly['bestDayDate'].toString().isNotEmpty
                      ? '${i18n.translate("best")}: ${_formatDisplayDate(monthly["bestDayDate"])}'
                      : '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthKpi({required String label, required String val, required String sub}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4F1).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B2824))),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF23B39B), fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedDateCard(BuildContext context, DailyActivityRecord record, I18nService i18n) {
    return ElderCard(
      backgroundColor: const Color(0xFFFEF3C7),
      border: Border.all(color: const Color(0xFFF59E0B)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📅 ${_formatDisplayDate(record.date)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, size: 18, color: Color(0xFF92400E)),
                onPressed: () => setState(() => _selectedDateRecord = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatNumber(record.steps),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1B2824)),
              ),
              const SizedBox(width: 6),
              Text(i18n.translate('stepsLabel'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
              const Spacer(),
              Text('${record.distanceKm.toStringAsFixed(1)} km • ${record.activeMinutes} min • ${record.calories} kcal',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBinCol(i18n.translate('morningSteps'), record.morningSteps, Icons.wb_sunny_outlined, const Color(0xFFF59E0B)),
              _buildBinCol(i18n.translate('afternoonSteps'), record.afternoonSteps, Icons.sunny, const Color(0xFFEA580C)),
              _buildBinCol(i18n.translate('eveningSteps'), record.eveningSteps, Icons.nights_stay_outlined, const Color(0xFF6366F1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyHistoryCard(BuildContext context, List<DailyActivityRecord> records, I18nService i18n) {
    return ElderCard(
      backgroundColor: Colors.white,
      border: Border.all(color: const Color(0xFFCDE4E2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                i18n.translate('activityHistory'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2824)),
              ),
              Text(
                i18n.translate('tapToViewBreakdown'),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  i18n.translate('noActivityHistoryYet'),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            )
          else
            ...records.map((r) {
              final isToday = r.date == DateTime.now().toIso8601String().substring(0, 10);
              final isSelected = _selectedDateRecord?.date == r.date;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDateRecord = isSelected ? null : r;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFEF3C7)
                        : (isToday ? const Color(0xFFE6F4F1) : const Color(0xFFF9FAFB)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF59E0B)
                          : (isToday ? const Color(0xFF61C5B0) : const Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: isToday ? const Color(0xFF23B39B) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isToday ? '${_formatDisplayDate(r.date)} (${i18n.translate("todayDate")})' : _formatDisplayDate(r.date),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isToday ? const Color(0xFF23B39B) : const Color(0xFF1B2824),
                              ),
                            ),
                            Text(
                              '${r.distanceKm.toStringAsFixed(1)} km • ${r.activeMinutes} min',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatNumber(r.steps),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B2824),
                            ),
                          ),
                          Text(
                            '${r.progressPercent}% of goal',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: r.isGoalCompleted ? const Color(0xFF16A34A) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String val,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          ),
          Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildBinCol(String label, int steps, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(_formatNumber(steps), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B2824))),
      ],
    );
  }

  Widget _buildStatText(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B2824))),
      ],
    );
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
