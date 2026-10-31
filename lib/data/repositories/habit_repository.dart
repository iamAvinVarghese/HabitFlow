import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../../core/hive/hive_setup.dart';
import '../../core/utils/date_utils.dart';

class HabitRepository {
  Box<HabitModel> get _habitsBox => Hive.box<HabitModel>(HiveSetup.habitsBox);
  Box<HabitLogModel> get _logsBox =>
      Hive.box<HabitLogModel>(HiveSetup.habitLogsBox);

  final _uuid = const Uuid();

  // CRUD
  Future<void> addHabit(HabitModel habit) async {
    await _habitsBox.put(habit.id, habit);
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _habitsBox.put(habit.id, habit);
  }

  Future<void> deleteHabit(String id) async {
    await _habitsBox.delete(id);
    final toDelete = _habitsBox.values.where((h) => h.id == id).toList();
    for (final h in toDelete) {
      await h.delete();
    }
    // Delete associated logs
    final logsToDelete = _logsBox.values
        .where((log) => log.habitId == id)
        .map((log) => log.key)
        .toList();
    await _logsBox.deleteAll(logsToDelete);
  }

  List<HabitModel> getAllHabits() {
    return _habitsBox.values.toList();
  }

  List<HabitModel> getActiveHabits() {
    return _habitsBox.values
        .where((h) => !h.isArchived)
        .toList()
      ..sort((a, b) {
        // Favorites first
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  List<HabitModel> getArchivedHabits() {
    return _habitsBox.values.where((h) => h.isArchived).toList();
  }

  HabitModel? getHabitById(String id) {
    return _habitsBox.get(id);
  }

  // Completion
  Future<void> completeHabitToday(String habitId) async {
    final habit = _habitsBox.get(habitId);
    if (habit == null) return;

    final todayKey = AppDateUtils.toStorageKey(DateTime.now());
    if (!habit.completedDates.contains(todayKey)) {
      habit.completedDates.add(todayKey);
      await habit.save();

      // Log it
      final log = HabitLogModel(
        id: _uuid.v4(),
        habitId: habitId,
        date: DateTime.now(),
        count: 1,
        action: 'complete',
      );
      await _logsBox.put(log.id, log);
    }
  }

  Future<void> uncompleteHabitToday(String habitId) async {
    final habit = _habitsBox.get(habitId);
    if (habit == null) return;

    final todayKey = AppDateUtils.toStorageKey(DateTime.now());
    habit.completedDates.remove(todayKey);
    await habit.save();
  }

  Future<void> skipHabitToday(String habitId) async {
    final habit = _habitsBox.get(habitId);
    if (habit == null) return;

    final todayKey = AppDateUtils.toStorageKey(DateTime.now());
    if (!habit.skippedDates.contains(todayKey)) {
      habit.skippedDates.add(todayKey);
      await habit.save();

      final log = HabitLogModel(
        id: _uuid.v4(),
        habitId: habitId,
        date: DateTime.now(),
        count: 0,
        action: 'skip',
      );
      await _logsBox.put(log.id, log);
    }
  }

  // Archive / Favorite
  Future<void> toggleArchive(String habitId) async {
    final habit = _habitsBox.get(habitId);
    if (habit == null) return;
    habit.isArchived = !habit.isArchived;
    await habit.save();
  }

  Future<void> toggleFavorite(String habitId) async {
    final habit = _habitsBox.get(habitId);
    if (habit == null) return;
    habit.isFavorite = !habit.isFavorite;
    await habit.save();
  }

  // Duplicate
  Future<void> duplicateHabit(String habitId) async {
    final habit = _habitsBox.get(habitId);
    if (habit == null) return;

    final duplicate = HabitModel(
      id: _uuid.v4(),
      title: '${habit.title} (Copy)',
      category: habit.category,
      targetCount: habit.targetCount,
      isFavorite: false,
      isArchived: false,
      notes: habit.notes,
      reminderHour: habit.reminderHour,
      reminderMinute: habit.reminderMinute,
      color: habit.color,
    );
    await _habitsBox.put(duplicate.id, duplicate);
  }

  // Stats
  int getCurrentStreak(String habitId) {
    final habit = _habitsBox.get(habitId);
    if (habit == null) return 0;
    return AppDateUtils.calculateStreak(habit.completedDates);
  }

  int getLongestStreak(String habitId) {
    final habit = _habitsBox.get(habitId);
    if (habit == null) return 0;
    return AppDateUtils.calculateLongestStreak(habit.completedDates);
  }

  int getOverallCurrentStreak() {
    final habits = getActiveHabits();
    if (habits.isEmpty) return 0;

    // Max streak across all habits
    return habits
        .map((h) => AppDateUtils.calculateStreak(h.completedDates))
        .fold(0, (a, b) => a > b ? a : b);
  }

  int getOverallLongestStreak() {
    final habits = getActiveHabits();
    if (habits.isEmpty) return 0;

    return habits
        .map((h) => AppDateUtils.calculateLongestStreak(h.completedDates))
        .fold(0, (a, b) => a > b ? a : b);
  }

  double getTodayCompletionRate() {
    final habits = getActiveHabits();
    if (habits.isEmpty) return 0;
    final completed = habits.where((h) => h.isCompletedToday()).length;
    return completed / habits.length;
  }

  // Logs for analytics
  List<HabitLogModel> getLogsForHabit(String habitId) {
    return _logsBox.values.where((l) => l.habitId == habitId).toList();
  }

  Map<String, int> getWeeklyCompletions() {
    final now = DateTime.now();
    final result = <String, int>{};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = AppDateUtils.toStorageKey(date);
      final count = getActiveHabits()
          .where((h) => h.completedDates.contains(key))
          .length;
      result[key] = count;
    }

    return result;
  }

  Map<String, int> getMonthlyCompletions() {
    final now = DateTime.now();
    final result = <String, int>{};

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = AppDateUtils.toStorageKey(date);
      final count = getActiveHabits()
          .where((h) => h.completedDates.contains(key))
          .length;
      result[key] = count;
    }

    return result;
  }

  Future<void> clearAll() async {
    await _habitsBox.clear();
    await _logsBox.clear();
  }
}
