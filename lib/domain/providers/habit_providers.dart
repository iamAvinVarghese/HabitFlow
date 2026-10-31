import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/habit_model.dart';
import '../../data/repositories/habit_repository.dart';
import '../../core/utils/notification_service.dart';
import '../../core/utils/widget_service.dart';

// Repository provider
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

// Habit list state notifier
class HabitNotifier extends StateNotifier<List<HabitModel>> {
  final HabitRepository _repository;

  HabitNotifier(this._repository) : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getActiveHabits();
  }

  void refresh() {
    _load();
  }

  Future<void> addHabit(HabitModel habit) async {
    await _repository.addHabit(habit);
    if (habit.reminderHour != null && habit.reminderMinute != null) {
      await NotificationService.scheduleHabitReminder(
        id: habit.id.hashCode,
        habitName: habit.title,
        hour: habit.reminderHour!,
        minute: habit.reminderMinute!,
      );
    }
    _load();
    WidgetService.updateWidget();
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _repository.updateHabit(habit);
    await NotificationService.cancelNotification(habit.id.hashCode);
    if (habit.reminderHour != null && habit.reminderMinute != null) {
      await NotificationService.scheduleHabitReminder(
        id: habit.id.hashCode,
        habitName: habit.title,
        hour: habit.reminderHour!,
        minute: habit.reminderMinute!,
      );
    }
    _load();
    WidgetService.updateWidget();
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    await NotificationService.cancelNotification(id.hashCode);
    _load();
    WidgetService.updateWidget();
  }

  Future<void> completeToday(String id) async {
    await _repository.completeHabitToday(id);
    _load();
    WidgetService.updateWidget();
  }

  Future<void> uncompleteToday(String id) async {
    await _repository.uncompleteHabitToday(id);
    _load();
    WidgetService.updateWidget();
  }

  Future<void> skipToday(String id) async {
    await _repository.skipHabitToday(id);
    _load();
    WidgetService.updateWidget();
  }

  Future<void> toggleArchive(String id) async {
    await _repository.toggleArchive(id);
    _load();
    WidgetService.updateWidget();
  }

  Future<void> toggleFavorite(String id) async {
    await _repository.toggleFavorite(id);
    _load();
    WidgetService.updateWidget();
  }

  Future<void> duplicate(String id) async {
    await _repository.duplicateHabit(id);
    _load();
    WidgetService.updateWidget();
  }
}

final habitNotifierProvider =
    StateNotifierProvider<HabitNotifier, List<HabitModel>>((ref) {
  final repo = ref.watch(habitRepositoryProvider);
  return HabitNotifier(repo);
});

// Derived providers
final activeHabitsProvider = Provider<List<HabitModel>>((ref) {
  return ref.watch(habitNotifierProvider);
});

final todayHabitsProvider = Provider<List<HabitModel>>((ref) {
  return ref.watch(habitNotifierProvider);
});

final favoriteHabitsProvider = Provider<List<HabitModel>>((ref) {
  return ref.watch(habitNotifierProvider).where((h) => h.isFavorite).toList();
});

final habitsByCategoryProvider =
    Provider.family<List<HabitModel>, String>((ref, category) {
  return ref
      .watch(habitNotifierProvider)
      .where((h) => h.category == category)
      .toList();
});

final todayCompletionRateProvider = Provider<double>((ref) {
  ref.watch(habitNotifierProvider);
  final repo = ref.read(habitRepositoryProvider);
  return repo.getTodayCompletionRate();
});

final currentStreakProvider = Provider<int>((ref) {
  ref.watch(habitNotifierProvider);
  final repo = ref.read(habitRepositoryProvider);
  return repo.getOverallCurrentStreak();
});

final longestStreakProvider = Provider<int>((ref) {
  ref.watch(habitNotifierProvider);
  final repo = ref.read(habitRepositoryProvider);
  return repo.getOverallLongestStreak();
});

final weeklyCompletionsProvider = Provider<Map<String, int>>((ref) {
  ref.watch(habitNotifierProvider);
  final repo = ref.read(habitRepositoryProvider);
  return repo.getWeeklyCompletions();
});

final monthlyCompletionsProvider = Provider<Map<String, int>>((ref) {
  ref.watch(habitNotifierProvider);
  final repo = ref.read(habitRepositoryProvider);
  return repo.getMonthlyCompletions();
});

final archivedHabitsProvider = Provider<List<HabitModel>>((ref) {
  ref.watch(habitNotifierProvider);
  final repo = ref.read(habitRepositoryProvider);
  return repo.getArchivedHabits();
});

// Category filter
final selectedHabitCategoryProvider = StateProvider<String?>((ref) => null);

final filteredHabitsProvider = Provider<List<HabitModel>>((ref) {
  final habits = ref.watch(habitNotifierProvider);
  final category = ref.watch(selectedHabitCategoryProvider);

  final todayWeekday = DateTime.now().weekday;
  final activeToday = habits.where((h) {
    final isScheduled = h.repeatDays == null ||
        h.repeatDays!.isEmpty ||
        h.repeatDays!.contains(todayWeekday);
    return isScheduled || h.isCompletedToday();
  }).toList();

  if (category == null || category == 'All') return activeToday;
  return activeToday.where((h) => h.category == category).toList();
});

final allHabitCompletionsProvider = Provider<Map<String, int>>((ref) {
  final habits = ref.watch(habitNotifierProvider);
  final result = <String, int>{};
  for (final habit in habits) {
    for (final dateStr in habit.completedDates) {
      result[dateStr] = (result[dateStr] ?? 0) + 1;
    }
  }
  return result;
});
