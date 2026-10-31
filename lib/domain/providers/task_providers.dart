import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../core/utils/notification_service.dart';
import '../../core/utils/widget_service.dart';

// Repository provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

// Task state notifier
class TaskNotifier extends StateNotifier<List<TaskModel>> {
  final TaskRepository _repository;

  TaskNotifier(this._repository) : super([]) {
    _load();
    _resetDaily();
  }

  void _load() {
    state = _repository.getAllTasks();
  }

  Future<void> _resetDaily() async {
    await _repository.resetCompletedTasksDaily();
    _load();
  }

  void refresh() {
    _load();
    _resetDaily();
  }

  Future<void> addTask(TaskModel task) async {
    await _repository.addTask(task);
    if (task.reminderTime != null && task.reminderTime!.isAfter(DateTime.now())) {
      await NotificationService.scheduleTaskReminder(
        id: task.id.hashCode,
        taskTitle: task.title,
        reminderTime: task.reminderTime!,
      );
    }
    _load();
    WidgetService.updateWidget();
  }

  Future<void> updateTask(TaskModel task) async {
    await _repository.updateTask(task);
    await NotificationService.cancelNotification(task.id.hashCode);
    if (task.reminderTime != null && task.reminderTime!.isAfter(DateTime.now())) {
      await NotificationService.scheduleTaskReminder(
        id: task.id.hashCode,
        taskTitle: task.title,
        reminderTime: task.reminderTime!,
      );
    }
    _load();
    WidgetService.updateWidget();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    await NotificationService.cancelNotification(id.hashCode);
    _load();
    WidgetService.updateWidget();
  }

  Future<void> completeTask(String id) async {
    await _repository.completeTask(id);
    _load();
    WidgetService.updateWidget();
  }

  Future<void> uncompleteTask(String id) async {
    await _repository.uncompleteTask(id);
    _load();
    WidgetService.updateWidget();
  }

  Future<void> togglePin(String id) async {
    await _repository.togglePin(id);
    _load();
    WidgetService.updateWidget();
  }

  Future<void> toggleArchive(String id) async {
    await _repository.toggleArchive(id);
    _load();
    WidgetService.updateWidget();
  }
}

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, List<TaskModel>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return TaskNotifier(repo);
});

// Derived task providers
final activeTasksProvider = Provider<List<TaskModel>>((ref) {
  final all = ref.watch(taskNotifierProvider);
  return all.where((t) => !t.isArchived && !t.isCompleted).toList()
    ..sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      final po = {TaskPriority.high: 0, TaskPriority.medium: 1, TaskPriority.low: 2};
      final diff = po[a.priority]!.compareTo(po[b.priority]!);
      if (diff != 0) return diff;
      return b.createdAt.compareTo(a.createdAt);
    });
});

final completedTasksProvider = Provider<List<TaskModel>>((ref) {
  final all = ref.watch(taskNotifierProvider);
  return all.where((t) => !t.isArchived && t.isCompleted).toList()
    ..sort((a, b) => (b.completedAt ?? b.createdAt)
        .compareTo(a.completedAt ?? a.createdAt));
});

final pinnedTasksProvider = Provider<List<TaskModel>>((ref) {
  final active = ref.watch(activeTasksProvider);
  return active.where((t) => t.isPinned).toList();
});

final archivedTasksProvider = Provider<List<TaskModel>>((ref) {
  final all = ref.watch(taskNotifierProvider);
  return all.where((t) => t.isArchived).toList();
});

// Search
final taskSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedTasksProvider = Provider<List<TaskModel>>((ref) {
  final query = ref.watch(taskSearchQueryProvider);
  final repo = ref.read(taskRepositoryProvider);
  if (query.isEmpty) return ref.watch(activeTasksProvider);
  return repo.searchTasks(query);
});

// Stats
final pendingTaskCountProvider = Provider<int>((ref) {
  ref.watch(taskNotifierProvider);
  final repo = ref.read(taskRepositoryProvider);
  return repo.getPendingCount();
});

final todayCompletedTaskCountProvider = Provider<int>((ref) {
  ref.watch(taskNotifierProvider);
  final repo = ref.read(taskRepositoryProvider);
  return repo.getTodayCompletedCount();
});

final productivityScoreProvider = Provider<double>((ref) {
  ref.watch(taskNotifierProvider);
  final repo = ref.read(taskRepositoryProvider);
  return repo.getProductivityScore();
});
