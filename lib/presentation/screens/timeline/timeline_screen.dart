import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/providers/habit_providers.dart';
import '../../../domain/providers/task_providers.dart';
import '../../../domain/providers/mood_providers.dart';
import '../../../domain/providers/journal_providers.dart';
import '../../../domain/providers/pomodoro_providers.dart';

class TimelineItem {
  final DateTime timestamp;
  final String title;
  final String category; // 'habit', 'task', 'mood', 'journal', 'pomodoro'
  final String subtitle;
  final IconData icon;

  TimelineItem({
    required this.timestamp,
    required this.title,
    required this.category,
    required this.subtitle,
    required this.icon,
  });
}

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  List<TimelineItem> _generateTimeline(WidgetRef ref) {
    final List<TimelineItem> items = [];

    // 1. Habit completions
    final habits = ref.read(activeHabitsProvider);
    for (final habit in habits) {
      for (final dateStr in habit.completedDates) {
        try {
          final date = AppDateUtils.fromStorageKey(dateStr);
          items.add(
            TimelineItem(
              timestamp: DateTime(date.year, date.month, date.day, 12, 0), // assume mid-day
              title: 'Habit Completed',
              category: 'habit',
              subtitle: habit.title,
              icon: Icons.repeat_rounded,
            ),
          );
        } catch (_) {}
      }
    }

    // 2. Completed Tasks
    final completedTasks = ref.read(completedTasksProvider);
    for (final task in completedTasks) {
      final ts = task.completedAt ?? task.createdAt;
      items.add(
        TimelineItem(
          timestamp: ts,
          title: 'Task Completed',
          category: 'task',
          subtitle: task.title,
          icon: Icons.check_circle_outline_rounded,
        ),
      );
    }

    // 3. Mood logs
    final moods = ref.read(moodNotifierProvider);
    for (final mood in moods) {
      items.add(
        TimelineItem(
          timestamp: mood.date,
          title: 'Logged Mood',
          category: 'mood',
          subtitle: 'Felt ${mood.moodLabel} (Energy: ${mood.energyLevel}/5)',
          icon: Icons.mood_rounded,
        ),
      );
    }

    // 4. Journal Entries
    final journals = ref.read(journalNotifierProvider);
    for (final entry in journals) {
      items.add(
        TimelineItem(
          timestamp: entry.date,
          title: 'Journal Entry',
          category: 'journal',
          subtitle: entry.title,
          icon: Icons.book_rounded,
        ),
      );
    }

    // 5. Pomodoro sessions
    final pomodoros = ref.read(pomodoroNotifierProvider);
    for (final session in pomodoros) {
      if (session.isCompleted) {
        items.add(
          TimelineItem(
            timestamp: session.endTime,
            title: 'Pomodoro Completed',
            category: 'pomodoro',
            subtitle: '${session.durationMinutes} min Focus Session completed.',
            icon: Icons.timer_rounded,
          ),
        );
      }
    }

    // Sort descending by timestamp
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Triggers rebuild when items modify
    ref.watch(habitNotifierProvider);
    ref.watch(taskNotifierProvider);
    ref.watch(moodNotifierProvider);
    ref.watch(journalNotifierProvider);
    ref.watch(pomodoroNotifierProvider);

    final timelineItems = _generateTimeline(ref);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Timeline Feed',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      body: timelineItems.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingPage,
                vertical: AppDimensions.spaceM,
              ),
              itemCount: timelineItems.length,
              itemBuilder: (context, index) {
                final item = timelineItems[index];
                return _buildTimelineRow(context, item, index == timelineItems.length - 1);
              },
            ),
    );
  }

  Widget _buildTimelineRow(BuildContext context, TimelineItem item, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicator column
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 72,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppDimensions.spaceM),
        // Content card column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM dd, yyyy - hh:mm a').format(item.timestamp),
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timeline_rounded, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppDimensions.spaceM),
            const Text(
              'Timeline is empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete habits, tasks, or log moods to build your activity feed.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
