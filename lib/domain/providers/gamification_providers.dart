import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'habit_providers.dart';
import 'task_providers.dart';
import 'mood_providers.dart';
import 'journal_providers.dart';
import 'pomodoro_providers.dart';
import 'achievement_providers.dart';
import '../../core/utils/date_utils.dart';

final consistencyScoreProvider = Provider<double>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  if (habits.isEmpty) return 0.0;

  final now = DateTime.now();
  final completedDaysInLast30 = <String>{};

  for (int i = 0; i < 30; i++) {
    final dayKey = AppDateUtils.toStorageKey(now.subtract(Duration(days: i)));
    for (final habit in habits) {
      if (habit.completedDates.contains(dayKey)) {
        completedDaysInLast30.add(dayKey);
        break;
      }
    }
  }

  return (completedDaysInLast30.length / 30.0) * 100.0;
});

final habitScoreProvider = Provider<int>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  int score = 0;
  for (final h in habits) {
    score += h.completedDates.length * 10;
    score -= h.skippedDates.length * 5;
  }
  return score.clamp(0, double.maxFinite.toInt());
});

// Auto unlocking achievement checker
final gamificationEngineProvider = Provider<void>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  final tasks = ref.watch(taskNotifierProvider);
  final moods = ref.watch(moodNotifierProvider);
  final journals = ref.watch(journalNotifierProvider);
  final pomodoros = ref.watch(pomodoroNotifierProvider);
  
  final achievementNotifier = ref.read(achievementNotifierProvider.notifier);

  // Check Habit accomplishments
  if (habits.any((h) => h.completedDates.isNotEmpty)) {
    achievementNotifier.unlockAchievement('first_habit');
  }

  final overallCurrentStreak = ref.read(currentStreakProvider);
  if (overallCurrentStreak >= 7) {
    achievementNotifier.unlockAchievement('streak_7');
  }
  if (overallCurrentStreak >= 30) {
    achievementNotifier.unlockAchievement('streak_30');
  }
  if (overallCurrentStreak >= 100) {
    achievementNotifier.unlockAchievement('streak_100');
  }
  if (overallCurrentStreak >= 365) {
    achievementNotifier.unlockAchievement('streak_365');
  }

  // Check Task accomplishments
  final completedTasksCount = tasks.where((t) => t.isCompleted).length;
  if (completedTasksCount >= 1) {
    achievementNotifier.unlockAchievement('first_task');
  }
  if (completedTasksCount >= 50) {
    achievementNotifier.unlockAchievement('tasks_50');
  }

  // Check Pomodoro accomplishments
  if (pomodoros.any((p) => p.isCompleted)) {
    achievementNotifier.unlockAchievement('pomodoro_first');
  }

  // Check Journal accomplishments
  if (journals.isNotEmpty) {
    achievementNotifier.unlockAchievement('journal_first');
  }

  // Check Mood accomplishments
  if (moods.isNotEmpty) {
    achievementNotifier.unlockAchievement('mood_first');
  }
});
