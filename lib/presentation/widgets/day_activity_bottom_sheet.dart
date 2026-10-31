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
import 'animated_checkmark.dart';

class DayActivityBottomSheet extends ConsumerWidget {
  final DateTime date;

  const DayActivityBottomSheet({
    super.key,
    required this.date,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Health':
        return Icons.favorite_rounded;
      case 'Fitness':
        return Icons.directions_run_rounded;
      case 'Study':
        return Icons.school_rounded;
      case 'Reading':
        return Icons.menu_book_rounded;
      case 'Coding':
        return Icons.code_rounded;
      case 'Work':
        return Icons.work_rounded;
      case 'Finance':
        return Icons.payments_rounded;
      case 'Personal':
        return Icons.person_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  void _toggleCompletion(WidgetRef ref, HabitModel habit, String dayKey) {
    final completedDates = List<String>.from(habit.completedDates);
    if (completedDates.contains(dayKey)) {
      completedDates.remove(dayKey);
    } else {
      completedDates.add(dayKey);
    }
    // Also remove from skipped if completed
    final skippedDates = List<String>.from(habit.skippedDates);
    if (skippedDates.contains(dayKey)) {
      skippedDates.remove(dayKey);
    }
    final updated = habit.copyWith(
      completedDates: completedDates,
      skippedDates: skippedDates,
    );
    ref.read(habitNotifierProvider.notifier).updateHabit(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeHabits = ref.watch(activeHabitsProvider);
    final archivedHabits = ref.watch(archivedHabitsProvider);
    final allHabits = [...activeHabits, ...archivedHabits];

    final dayDate = AppDateUtils.stripTime(date);
    final dayKey = AppDateUtils.toStorageKey(dayDate);
    final dayOfWeek = dayDate.weekday;

    // Filter habits active on this day
    final dayHabits = allHabits.where((h) {
      final createdDate = AppDateUtils.stripTime(h.createdAt);
      final isCreatedBeforeOrOn = !dayDate.isBefore(createdDate);
      final isCompletedOnDay = h.completedDates.contains(dayKey);

      final isScheduledForDay = h.repeatDays == null ||
          h.repeatDays!.isEmpty ||
          h.repeatDays!.contains(dayOfWeek);

      return (isCreatedBeforeOrOn && isScheduledForDay) || isCompletedOnDay;
    }).toList();

    final completed = dayHabits.where((h) => h.completedDates.contains(dayKey)).toList();
    final incomplete = dayHabits.where((h) => !h.completedDates.contains(dayKey)).toList();

    final formattedDate = AppDateUtils.formatDayMonth(date);
    final year = date.year;
    final isCurrentYear = year == DateTime.now().year;
    final titleText = isCurrentYear ? formattedDate : '$formattedDate, $year';

    final total = dayHabits.length;
    final completedCount = completed.length;
    final completionPercent = total > 0 ? (completedCount / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingPage,
        vertical: AppDimensions.spaceM,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),

          // Header: Date & Completion summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'No habits active'
                          : '$completedCount of $total completed ($completionPercent%)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: hapticLight(() => Navigator.pop(context)),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceL),

          // Main list content
          if (dayHabits.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                      Text(
                        'No Habits on this day',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Only habits active on this date are listed here.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: [
                  if (incomplete.isNotEmpty) ...[
                    _buildSectionHeader('INCOMPLETE', incomplete.length),
                    const SizedBox(height: AppDimensions.spaceS),
                    ...incomplete.map((h) => _buildHabitItem(context, ref, h, dayKey, false)),
                    const SizedBox(height: AppDimensions.spaceM),
                  ],
                  if (completed.isNotEmpty) ...[
                    _buildSectionHeader('COMPLETED', completed.length),
                    const SizedBox(height: AppDimensions.spaceS),
                    ...completed.map((h) => _buildHabitItem(context, ref, h, dayKey, true)),
                  ],
                  SizedBox(height: MediaQuery.of(context).padding.bottom + AppDimensions.spaceM),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(
    BuildContext context,
    WidgetRef ref,
    HabitModel habit,
    String dayKey,
    bool isCompleted,
  ) {
    final isSkipped = habit.skippedDates.contains(dayKey);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isCompleted ? AppColors.borderBright : AppColors.border,
          width: 0.8,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingCard,
          vertical: 4,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Icon(
              _getCategoryIcon(habit.category),
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                habit.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (habit.isArchived) ...[
              const SizedBox(width: 6),
              _buildBadge('Archived'),
            ],
            if (isSkipped) ...[
              const SizedBox(width: 6),
              _buildBadge('Skipped'),
            ],
          ],
        ),
        subtitle: Text(
          habit.category,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: AnimatedCheckmark(
          checked: isCompleted,
          size: 26,
          onTap: hapticSelection(() {
            HapticFeedback.mediumImpact();
            _toggleCompletion(ref, habit, dayKey);
          }),
        ),
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
