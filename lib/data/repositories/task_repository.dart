import 'package:hive/hive.dart';

import '../models/task_model.dart';
import '../../core/hive/hive_setup.dart';
import '../../core/utils/date_utils.dart';

class TaskRepository {
  Box<TaskModel> get _tasksBox => Hive.box<TaskModel>(HiveSetup.tasksBox);

  Future<void> resetCompletedTasksDaily() async {
    final box = Hive.box(HiveSetup.settingsBox);
    final todayKey = AppDateUtils.toStorageKey(DateTime.now());
    final lastReset = box.get('last_task_reset_date');

    if (lastReset != todayKey) {
      final completedTasks = _tasksBox.values.where((t) => t.isCompleted).toList();
      for (final task in completedTasks) {
        task.isCompleted = false;
        task.completedAt = null;
        await task.save();
      }
      await box.put('last_task_reset_date', todayKey);
    }
  }


  // CRUD
  Future<void> addTask(TaskModel task) async {
    await _tasksBox.put(task.id, task);
  }

  Future<void> updateTask(TaskModel task) async {
    await _tasksBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
    final toDelete = _tasksBox.values.where((t) => t.id == id).toList();
    for (final t in toDelete) {
      await t.delete();
    }
  }

  List<TaskModel> getAllTasks() {
    return _tasksBox.values.toList();
  }

  List<TaskModel> getActiveTasks() {
    return _tasksBox.values
        .where((t) => !t.isArchived && !t.isCompleted)
        .toList()
      ..sort((a, b) {
        // Pinned first
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        // Then by priority
        final priorityOrder = {
          TaskPriority.high: 0,
          TaskPriority.medium: 1,
          TaskPriority.low: 2,
        };
        final aPri = priorityOrder[a.priority]!;
        final bPri = priorityOrder[b.priority]!;
        if (aPri != bPri) return aPri.compareTo(bPri);
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  List<TaskModel> getCompletedTasks() {
    return _tasksBox.values
        .where((t) => !t.isArchived && t.isCompleted)
        .toList()
      ..sort((a, b) =>
          (b.completedAt ?? b.createdAt)
              .compareTo(a.completedAt ?? a.createdAt));
  }

  List<TaskModel> getArchivedTasks() {
    return _tasksBox.values.where((t) => t.isArchived).toList();
  }

  List<TaskModel> searchTasks(String query) {
    if (query.isEmpty) return getActiveTasks();
    final q = query.toLowerCase();
    return _tasksBox.values
        .where((t) =>
            !t.isArchived &&
            (t.title.toLowerCase().contains(q) ||
                (t.notes?.toLowerCase().contains(q) ?? false)))
        .toList();
  }

  TaskModel? getTaskById(String id) {
    return _tasksBox.get(id);
  }

  // Actions
  Future<void> completeTask(String id) async {
    final task = _tasksBox.get(id);
    if (task == null) return;
    task.isCompleted = true;
    task.completedAt = DateTime.now();
    await task.save();
  }

  Future<void> uncompleteTask(String id) async {
    final task = _tasksBox.get(id);
    if (task == null) return;
    task.isCompleted = false;
    task.completedAt = null;
    await task.save();
  }

  Future<void> togglePin(String id) async {
    final task = _tasksBox.get(id);
    if (task == null) return;
    task.isPinned = !task.isPinned;
    await task.save();
  }

  Future<void> toggleArchive(String id) async {
    final task = _tasksBox.get(id);
    if (task == null) return;
    task.isArchived = !task.isArchived;
    await task.save();
  }

  // Stats
  int getTodayCompletedCount() {
    final now = DateTime.now();
    return _tasksBox.values.where((t) {
      if (t.completedAt == null) return false;
      final c = t.completedAt!;
      return c.year == now.year && c.month == now.month && c.day == now.day;
    }).length;
  }

  int getPendingCount() {
    return _tasksBox.values
        .where((t) => !t.isCompleted && !t.isArchived)
        .length;
  }

  double getProductivityScore() {
    final total = _tasksBox.values.where((t) => !t.isArchived).length;
    if (total == 0) return 0;
    final completed = _tasksBox.values.where((t) => t.isCompleted).length;
    return (completed / total) * 100;
  }

  Future<void> clearAll() async {
    await _tasksBox.clear();
  }
}
