// widget_service.dart
// Bridges HabitFlow's Hive data to the native Android home screen widget
// via the home_widget package (SharedPreferences under the hood).

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hive/hive.dart';

import '../../data/models/task_model.dart';
import '../../data/models/habit_model.dart';
import '../hive/hive_setup.dart';
import '../utils/date_utils.dart';

/// The Android AppWidgetProvider class name — must match the Kotlin class name.
const _kWidgetProviderName = 'HabitFlowWidgetProvider';

/// App group ID (used on iOS; ignored on Android — set to match your bundle).
const _kAppGroupId = 'com.habitflow.habitflow';

class WidgetService {
  /// Call once at app startup to configure the home_widget package.
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_kAppGroupId);
    } catch (e) {
      debugPrint('[WidgetService] init error: $e');
    }
  }

  /// Serializes current Hive data and pushes it to the widget.
  /// Safe to call frequently — does nothing if Hive boxes aren't open yet.
  static Future<void> updateWidget() async {
    // Only supported on Android/iOS — skip on web/desktop
    if (kIsWeb) return;

    try {
      if (!Hive.isBoxOpen(HiveSetup.tasksBox) ||
          !Hive.isBoxOpen(HiveSetup.habitsBox)) {
        return;
      }

      final tasksBox = Hive.box<TaskModel>(HiveSetup.tasksBox);
      final habitsBox = Hive.box<HabitModel>(HiveSetup.habitsBox);

      // ── Tasks ────────────────────────────────────────────────────────────
      final allTasks = tasksBox.values.where((t) => !t.isArchived).toList();

      // Sort: pinned first, then by priority
      allTasks.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        const po = {TaskPriority.high: 0, TaskPriority.medium: 1, TaskPriority.low: 2};
        return po[a.priority]!.compareTo(po[b.priority]!);
      });

      final pendingTasks =
          allTasks.where((t) => !t.isCompleted).take(6).toList();
      final completedTasks =
          allTasks.where((t) => t.isCompleted).take(3).toList();

      final tasksJson = json.encode([
        ...pendingTasks.map((t) => _serializeTask(t, false)),
        ...completedTasks.map((t) => _serializeTask(t, true)),
      ]);

      // ── Habits ───────────────────────────────────────────────────────────
      final todayWeekday = DateTime.now().weekday;
      final activeHabits = habitsBox.values
          .where((h) => !h.isArchived)
          .where((h) {
            final scheduled = h.repeatDays == null ||
                h.repeatDays!.isEmpty ||
                h.repeatDays!.contains(todayWeekday);
            return scheduled || h.isCompletedToday();
          })
          .toList();

      final completedHabits =
          activeHabits.where((h) => h.isCompletedToday()).length;
      final totalHabits = activeHabits.length;
      final completionPct =
          totalHabits == 0 ? 0 : (completedHabits * 100 ~/ totalHabits);

      // Calculate overall streak (max across all habits)
      int maxStreak = 0;
      for (final h in activeHabits) {
        final streak = AppDateUtils.calculateStreak(h.completedDates);
        if (streak > maxStreak) maxStreak = streak;
      }

      final habitsJson = json.encode(
        activeHabits.take(5).map((h) => _serializeHabit(h)).toList(),
      );

      // ── Save to SharedPreferences via home_widget ─────────────────────
      await Future.wait<bool?>([
        HomeWidget.saveWidgetData<String>('widget_tasks_json', tasksJson),
        HomeWidget.saveWidgetData<String>('widget_habits_json', habitsJson),
        HomeWidget.saveWidgetData<int>(
            'widget_pending_tasks', pendingTasks.length),
        HomeWidget.saveWidgetData<int>(
            'widget_completed_tasks', completedTasks.length),
        HomeWidget.saveWidgetData<int>('widget_total_habits', totalHabits),
        HomeWidget.saveWidgetData<int>(
            'widget_completed_habits', completedHabits),
        HomeWidget.saveWidgetData<int>(
            'widget_completion_pct', completionPct),
        HomeWidget.saveWidgetData<int>('widget_streak', maxStreak),
        HomeWidget.saveWidgetData<String>(
            'widget_last_updated', DateTime.now().toIso8601String()),
      ]);

      // ── Tell Android to redraw the widget ─────────────────────────────
      await HomeWidget.updateWidget(
        name: _kWidgetProviderName,
        androidName: _kWidgetProviderName,
      );
    } catch (e) {
      debugPrint('[WidgetService] updateWidget error: $e');
    }
  }

  // ─── Deep-link handling for widget clicks ────────────────────────────────

  /// Listens to home_widget launch and click events to handle deep links.
  static void setupClickListener(Function(String path) navigateTo) {
    if (kIsWeb) return;

    // Handle launch from widget when app was cold-started
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        _handleUri(uri, navigateTo);
      }
    });

    // Handle clicks when app was already in memory
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        _handleUri(uri, navigateTo);
      }
    });
  }

  static void _handleUri(Uri uri, Function(String path) navigateTo) {
    debugPrint('[WidgetService] Received deep link: $uri');
    final host = uri.host;
    final path = uri.path;
    final id = uri.queryParameters['id'];

    if (host == 'tasks' || path == '/tasks') {
      if (path.contains('/add')) {
        navigateTo('/tasks/add');
      } else {
        navigateTo('/tasks');
      }
    } else if (host == 'habits' || path == '/habits') {
      navigateTo('/habits');
    } else if (host == 'complete-task') {
      navigateTo('/tasks');
    } else if (host == 'complete-habit') {
      navigateTo('/habits');
    } else {
      navigateTo('/dashboard');
    }
  }

  // ─── Serialization helpers ──────────────────────────────────────────────

  static Map<String, dynamic> _serializeTask(TaskModel t, bool completed) {
    return {
      'id': t.id,
      'title': t.title,
      'priority': t.priority.index, // 0=high, 1=medium, 2=low
      'isCompleted': completed,
      'isPinned': t.isPinned,
      'reminderTime': t.reminderTime?.toIso8601String(),
    };
  }

  static Map<String, dynamic> _serializeHabit(HabitModel h) {
    return {
      'id': h.id,
      'title': h.title,
      'isCompletedToday': h.isCompletedToday(),
      'streak': AppDateUtils.calculateStreak(h.completedDates),
      'color': h.color,
    };
  }
}
