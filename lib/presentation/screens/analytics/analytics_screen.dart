import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/providers/habit_providers.dart';
import '../../../domain/providers/task_providers.dart';
import '../../../domain/providers/mood_providers.dart';
import '../../../domain/providers/pomodoro_providers.dart';
import '../../widgets/day_activity_bottom_sheet.dart';
import '../../widgets/habit_heatmap.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyData = ref.watch(weeklyCompletionsProvider);
    final monthlyData = ref.watch(monthlyCompletionsProvider);
    final habits = ref.watch(activeHabitsProvider);
    final currentStreak = ref.watch(currentStreakProvider);
    final longestStreak = ref.watch(longestStreakProvider);
    final productivity = ref.watch(productivityScoreProvider);

    // Premium Analytics
    final totalFocusMinutes = ref.watch(totalFocusTimeMinutesProvider);
    final completedPomodoros = ref.watch(completedPomodorosCountProvider);
    final moodAverages = ref.watch(averageMoodByDayOfWeekProvider);

    // Build completed dates set for calendar
    final completedDays = <DateTime>{};
    for (final habit in habits) {
      for (final key in habit.completedDates) {
        try {
          completedDays.add(AppDateUtils.fromStorageKey(key));
        } catch (_) {}
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            floating: true,
            snap: true,
            title: Text(
              'Analytics',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingPage,
              0,
              AppDimensions.paddingPage,
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary row
                _buildSummaryRow(currentStreak, longestStreak, productivity),
                const SizedBox(height: AppDimensions.spaceL),

                // Heatmap graph (Premium)
                _SectionTitle(title: 'Consistency Heatmap'),
                const SizedBox(height: AppDimensions.spaceM),
                HabitHeatmap(
                  completedData: weeklyData,
                  totalHabits: habits.length,
                  onDayPressed: (date) {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.card,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppDimensions.radiusXL),
                        ),
                      ),
                      builder: (_) => DayActivityBottomSheet(date: date),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.spaceL),

                // Focus stats (Premium)
                _SectionTitle(title: 'Focus Stats (Pomodoro)'),
                const SizedBox(height: AppDimensions.spaceM),
                _buildFocusStatsCard(totalFocusMinutes, completedPomodoros),
                const SizedBox(height: AppDimensions.spaceL),

                // Mood averages (Premium)
                if (moodAverages.isNotEmpty) ...[
                  _SectionTitle(title: 'Weekly Mood Trends'),
                  const SizedBox(height: AppDimensions.spaceM),
                  _buildMoodAveragesCard(moodAverages),
                  const SizedBox(height: AppDimensions.spaceL),
                ],

                // Weekly bar chart
                _SectionTitle(title: 'This Week Completion'),
                const SizedBox(height: AppDimensions.spaceM),
                _buildWeeklyChart(weeklyData),
                const SizedBox(height: AppDimensions.spaceL),

                // Monthly line chart
                _SectionTitle(title: 'Last 30 Days trend'),
                const SizedBox(height: AppDimensions.spaceM),
                _buildMonthlyChart(monthlyData, habits.length),
                const SizedBox(height: AppDimensions.spaceL),

                // Calendar heatmap
                _SectionTitle(title: 'Habit Calendar'),
                const SizedBox(height: AppDimensions.spaceM),
                _buildCalendar(context, completedDays),
                const SizedBox(height: AppDimensions.spaceL),

                // Per-habit stats
                if (habits.isNotEmpty) ...[
                  _SectionTitle(title: 'Habit Breakdown'),
                  const SizedBox(height: AppDimensions.spaceM),
                  ...habits.take(8).map((h) {
                    final repo =
                        ref.read(habitRepositoryProvider);
                    final streak = repo.getCurrentStreak(h.id);
                    final total = h.completedDates.length;
                    final pct = habits.isNotEmpty && total > 0
                        ? (total / 30).clamp(0.0, 1.0)
                        : 0.0;
                    return _HabitStatRow(
                      title: h.title,
                      category: h.category,
                      streak: streak,
                      total: total,
                      progress: pct,
                    );
                  }),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusStatsCard(int focusMinutes, int sessions) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '$focusMinutes',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text('Focus Minutes', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          Column(
            children: [
              Text(
                '$sessions',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text('Sessions Completed', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodAveragesCard(Map<String, double> averages) {
    final list = averages.entries.toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: 5,
          minY: 0,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= list.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(list[idx].key, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (val, _) => Text('${val.toInt()}', style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(list.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: list[i].value,
                  color: AppColors.textPrimary,
                  width: 14,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      int currentStreak, int longestStreak, double productivity) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Current Streak',
            value: '$currentStreak',
            suffix: 'days',
            icon: Icons.local_fire_department_rounded,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: _SummaryCard(
            label: 'Longest Streak',
            value: '$longestStreak',
            suffix: 'days',
            icon: Icons.emoji_events_rounded,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: _SummaryCard(
            label: 'Score',
            value: '${productivity.round()}',
            suffix: '%',
            icon: Icons.trending_up_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(Map<String, int> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final entries = data.entries.toList();
    final maxY = data.values.fold(0, (a, b) => a > b ? a : b).toDouble();
    final chartMax = maxY < 3 ? 3.0 : maxY + 1;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: chartMax,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItem: (group, gI, rod, rI) {
                return BarTooltipItem(
                  '${rod.toY.round()}',
                  GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= entries.length) return const SizedBox();
                  final date = AppDateUtils.fromStorageKey(entries[i].key);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('E').format(date),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  );
                },
                reservedSize: 20,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (val, _) {
                  if (val % 1 != 0) return const SizedBox();
                  return Text(
                    '${val.toInt()}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  );
                },
                reservedSize: 20,
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border,
              strokeWidth: 0.5,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (i) {
            final val = entries[i].value.toDouble();
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: val > 0
                      ? AppColors.textPrimary
                      : AppColors.surface,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(Map<String, int> data, int totalHabits) {
    if (data.isEmpty) return const SizedBox.shrink();

    final entries = data.entries.toList();
    final spots = List.generate(entries.length, (i) {
      return FlSpot(i.toDouble(), entries[i].value.toDouble());
    });

    return Container(
      height: 180,
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: totalHabits > 0 ? (totalHabits / 2).ceilToDouble() : 1,
                getTitlesWidget: (val, _) => Text(
                  '${val.toInt()}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
                reservedSize: 20,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 7,
                getTitlesWidget: (val, _) {
                  final i = val.toInt();
                  if (i < 0 || i >= entries.length) return const SizedBox();
                  final date = AppDateUtils.fromStorageKey(entries[i].key);
                  return Text(
                    DateFormat('d MMM').format(date),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: AppColors.textTertiary,
                    ),
                  );
                },
                reservedSize: 20,
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.textPrimary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.textPrimary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, Set<DateTime> completedDays) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: TableCalendar(
        startingDayOfWeek: StartingDayOfWeek.monday,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: DateTime.now(),
        calendarFormat: CalendarFormat.month,
        headerVisible: true,
        daysOfWeekVisible: true,
        calendarStyle: CalendarStyle(
          defaultTextStyle: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          weekendTextStyle: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          outsideTextStyle: GoogleFonts.inter(
            color: AppColors.textDisabled,
            fontSize: 13,
          ),
          todayDecoration: BoxDecoration(
            border: Border.all(color: AppColors.borderBright, width: 1.5),
            shape: BoxShape.circle,
          ),
          todayTextStyle: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: GoogleFonts.inter(
            color: AppColors.background,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left,
              color: AppColors.textSecondary),
          rightChevronIcon: const Icon(Icons.chevron_right,
              color: AppColors.textSecondary),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        eventLoader: (day) {
          final stripped = DateTime(day.year, day.month, day.day);
          return completedDays.any((d) =>
              d.year == stripped.year &&
              d.month == stripped.month &&
              d.day == stripped.day)
              ? ['●']
              : [];
        },
        onDaySelected: (selectedDay, _) {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.card,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXL),
              ),
            ),
            builder: (_) => DayActivityBottomSheet(date: selectedDay),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' $suffix',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitStatRow extends StatelessWidget {
  final String title;
  final String category;
  final int streak;
  final int total;
  final double progress;

  const _HabitStatRow({
    required this.title,
    required this.category,
    required this.streak,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$streak day streak',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation(AppColors.textPrimary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$total completions · $category',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
