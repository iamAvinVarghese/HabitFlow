import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/habit_model.dart';
import '../../domain/providers/habit_providers.dart';

class HabitHeatmap extends ConsumerStatefulWidget {
  final Map<String, int> completedData; // Kept for backwards compatibility but we now watch allHabitCompletionsProvider
  final int totalHabits;
  final ValueChanged<DateTime>? onDayPressed;

  const HabitHeatmap({
    super.key,
    required this.completedData,
    required this.totalHabits,
    this.onDayPressed,
  });

  @override
  ConsumerState<HabitHeatmap> createState() => _HabitHeatmapState();
}

class _HabitHeatmapState extends ConsumerState<HabitHeatmap> {
  late String _selectedYear;
  late String _selectedMonth; // 'All' or '1'-'12'

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year.toString();
    _selectedMonth = now.month.toString();
  }

  final List<String> _monthsShort = [
    'All', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  List<String> _getYearOptions() {
    final currentYear = DateTime.now().year;
    final years = <String>[];
    for (int y = 2026; y <= currentYear; y++) {
      years.add(y.toString());
    }
    years.add('Overall');
    return years;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final completions = ref.watch(allHabitCompletionsProvider);
    final habits = ref.watch(activeHabitsProvider);
    final yearOptions = _getYearOptions();

    final isOverall = _selectedYear == 'Overall';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title + Year Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOverall ? 'Overall Map' : 'Consistency Map',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              // Year pill selector
              Row(
                children: yearOptions.map((yr) {
                  final isYrSelected = _selectedYear == yr;
                  return GestureDetector(
                    onTap: hapticSelection(() {
                      setState(() {
                        _selectedYear = yr;
                        if (yr == 'Overall') {
                          _selectedMonth = 'All';
                        }
                      });
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isYrSelected ? AppColors.textPrimary : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        yr,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isYrSelected ? AppColors.background : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),

          // Month selector horizontal list (only if not Overall)
          if (!isOverall) ...[
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _monthsShort.length,
                itemBuilder: (context, index) {
                  final mLabel = _monthsShort[index];
                  final isMSelected = _selectedMonth == (index == 0 ? 'All' : index.toString());
                  
                  return GestureDetector(
                    onTap: hapticSelection(() {
                      setState(() {
                        _selectedMonth = index == 0 ? 'All' : index.toString();
                      });
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMSelected ? AppColors.textPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        border: Border.all(
                          color: isMSelected ? AppColors.textPrimary : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          mLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isMSelected ? AppColors.background : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
          ],

          // Calendar Grids Section
          _buildGridsContent(completions, habits),

          const SizedBox(height: AppDimensions.spaceM),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less ', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary)),
              _buildLegendBox(Colors.transparent),
              _buildLegendBox(AppColors.textPrimary.withValues(alpha: 0.3)),
              _buildLegendBox(AppColors.textPrimary.withValues(alpha: 0.65)),
              _buildLegendBox(AppColors.textPrimary),
              Text(' More', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGridsContent(Map<String, int> completions, List<HabitModel> habits) {
    final now = DateTime.now();

    if (_selectedYear == 'Overall') {
      // Show all months from January 2026 to current month/year
      final List<Widget> monthGrids = [];
      final currentYear = now.year;
      final currentMonth = now.month;

      for (int y = 2026; y <= currentYear; y++) {
        final startM = 1;
        final endM = (y == currentYear) ? currentMonth : 12;
        
        for (int m = startM; m <= endM; m++) {
          monthGrids.add(
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceXL),
              child: _buildMonthGrid(y, m, completions, habits),
            ),
          );
        }
      }
      return Column(children: monthGrids);
    }

    final yearNum = int.parse(_selectedYear);

    if (_selectedMonth == 'All') {
      // Show all 12 months for the selected year
      final List<Widget> monthGrids = [];
      final maxMonth = (yearNum == now.year) ? now.month : 12;

      for (int m = 1; m <= maxMonth; m++) {
        monthGrids.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spaceXL),
            child: _buildMonthGrid(yearNum, m, completions, habits),
          ),
        );
      }
      return Column(children: monthGrids);
    } else {
      // Show single selected month
      final monthNum = int.parse(_selectedMonth);
      return _buildMonthGrid(yearNum, monthNum, completions, habits);
    }
  }

  Widget _buildMonthGrid(int year, int month, Map<String, int> completedData, List<HabitModel> habits) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    
    // weekday is 1 (Mon) to 7 (Sun)
    final paddingStart = firstDay.weekday - 1;
    final totalCells = paddingStart + daysInMonth;
    final rowsCount = (totalCells / 7).ceil();

    final monthName = _getMonthName(month);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 4.0),
          child: Text(
            '$monthName $year',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: 240, // size flexible and compact width constraint
            child: Column(
              children: [
                // Day of Week Headers (Mon to Sun)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                    return SizedBox(
                      width: 24,
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                // Calendar Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4.0,
                    crossAxisSpacing: 4.0,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: rowsCount * 7,
                  itemBuilder: (context, index) {
                    if (index < paddingStart || index >= paddingStart + daysInMonth) {
                      return const SizedBox();
                    }

                    final dayNumber = index - paddingStart + 1;
                    final dayDate = DateTime(year, month, dayNumber);
                    
                    // Check if future day
                    final now = DateTime.now();
                    final todayMidnight = DateTime(now.year, now.month, now.day);
                    final isFuture = dayDate.isAfter(todayMidnight);

                    if (isFuture) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderSubtle, width: 0.5),
                        ),
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ),
                      );
                    }

                    final dayKey = AppDateUtils.toStorageKey(dayDate);
                    final completedCount = completedData[dayKey] ?? 0;

                    final dayOfWeek = dayDate.weekday;
                    final totalActiveOnDay = habits.where((h) {
                      final createdDate = AppDateUtils.stripTime(h.createdAt);
                      final isCreatedBeforeOrOn = !dayDate.isBefore(createdDate);
                      final isScheduledForDay = h.repeatDays == null ||
                          h.repeatDays!.isEmpty ||
                          h.repeatDays!.contains(dayOfWeek);
                      return isCreatedBeforeOrOn && isScheduledForDay;
                    }).length;

                    Color cellColor = Colors.transparent;
                    Color textColor = AppColors.textPrimary;
                    
                    if (completedCount > 0 && totalActiveOnDay > 0) {
                      final ratio = completedCount / totalActiveOnDay;
                      if (ratio >= 0.75) {
                        cellColor = AppColors.textPrimary;
                        textColor = AppColors.background; // black text on white background
                      } else if (ratio >= 0.50) {
                        cellColor = AppColors.textPrimary.withValues(alpha: 0.65);
                        textColor = AppColors.background;
                      } else {
                        cellColor = AppColors.textPrimary.withValues(alpha: 0.3);
                        textColor = AppColors.textPrimary;
                      }
                    }

                    return GestureDetector(
                      onTap: hapticLight(() {
                        HapticFeedback.lightImpact();
                        widget.onDayPressed?.call(dayDate);
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: cellColor == Colors.transparent
                                ? AppColors.border
                                : Colors.transparent,
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: cellColor != Colors.transparent ? FontWeight.bold : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.0),
        border: color == Colors.transparent
            ? Border.all(color: AppColors.border, width: 0.5)
            : null,
      ),
    );
  }
}
