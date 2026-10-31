import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';

import '../hive/hive_setup.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/mood_model.dart';
import '../../data/models/journal_model.dart';
import '../../data/models/pomodoro_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/achievement_model.dart';

class BackupService {
  // JSON Backup Export
  Future<String> exportBackupToJson() async {
    final Map<String, dynamic> backupData = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': Hive.box<HabitModel>(HiveSetup.habitsBox).values.map((h) => h.toJson()).toList(),
      'tasks': Hive.box<TaskModel>(HiveSetup.tasksBox).values.map((t) => t.toJson()).toList(),
      'moods': Hive.box<MoodEntry>(HiveSetup.moodsBox).values.map((m) => m.toJson()).toList(),
      'journals': Hive.box<JournalEntry>(HiveSetup.journalsBox).values.map((j) => j.toJson()).toList(),
      'pomodoros': Hive.box<PomodoroSession>(HiveSetup.pomodorosBox).values.map((p) => p.toJson()).toList(),
      'goals': Hive.box<GoalModel>(HiveSetup.goalsBox).values.map((g) => g.toJson()).toList(),
      'achievements': Hive.box<AchievementBadge>(HiveSetup.achievementsBox).values.map((a) => a.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/habitflow_backup.json');
    await file.writeAsString(jsonString);
    return file.path;
  }

  // JSON Backup Import
  Future<bool> importBackupFromJson(String jsonContent) async {
    try {
      final Map<String, dynamic> backupData = json.decode(jsonContent);
      if (backupData['version'] != 1) return false;

      // Import Habits
      final habitsBox = Hive.box<HabitModel>(HiveSetup.habitsBox);
      await habitsBox.clear();
      final habitsList = backupData['habits'] as List;
      for (final item in habitsList) {
        final habit = HabitModel(
          id: item['id'],
          title: item['title'],
          category: item['category'],
          targetCount: item['targetCount'] ?? 1,
          completedDates: List<String>.from(item['completedDates'] ?? []),
          isFavorite: item['isFavorite'] ?? false,
          isArchived: item['isArchived'] ?? false,
          notes: item['notes'],
          reminderHour: item['reminderHour'],
          reminderMinute: item['reminderMinute'],
          createdAt: DateTime.parse(item['createdAt']),
          skippedDates: List<String>.from(item['skippedDates'] ?? []),
          color: item['color'] ?? 0xFFFFFFFF,
        );
        await habitsBox.put(habit.id, habit);
      }

      // Import Tasks
      final tasksBox = Hive.box<TaskModel>(HiveSetup.tasksBox);
      await tasksBox.clear();
      final tasksList = backupData['tasks'] as List;
      for (final item in tasksList) {
        final task = TaskModel(
          id: item['id'],
          title: item['title'],
          isCompleted: item['isCompleted'] ?? false,
          isPinned: item['isPinned'] ?? false,
          isArchived: item['isArchived'] ?? false,
          priority: TaskPriority.values[item['priority'] ?? 1],
          notes: item['notes'],
          reminderTime: item['reminderTime'] != null ? DateTime.parse(item['reminderTime']) : null,
          createdAt: DateTime.parse(item['createdAt']),
          completedAt: item['completedAt'] != null ? DateTime.parse(item['completedAt']) : null,
          notificationId: item['notificationId'],
        );
        await tasksBox.put(task.id, task);
      }

      // Import Moods
      final moodsBox = Hive.box<MoodEntry>(HiveSetup.moodsBox);
      await moodsBox.clear();
      final moodsList = backupData['moods'] as List;
      for (final item in moodsList) {
        final mood = MoodEntry(
          id: item['id'],
          date: DateTime.parse(item['date']),
          mood: MoodLevel.values[item['mood'] ?? 2],
          note: item['note'],
          tags: List<String>.from(item['tags'] ?? []),
          energyLevel: item['energyLevel'] ?? 3,
        );
        await moodsBox.put(mood.id, mood);
      }

      // Import Journals
      final journalsBox = Hive.box<JournalEntry>(HiveSetup.journalsBox);
      await journalsBox.clear();
      final journalsList = backupData['journals'] as List;
      for (final item in journalsList) {
        final journal = JournalEntry(
          id: item['id'],
          date: DateTime.parse(item['date']),
          title: item['title'],
          content: item['content'],
          tags: List<String>.from(item['tags'] ?? []),
          createdAt: DateTime.parse(item['createdAt']),
          updatedAt: item['updatedAt'] != null ? DateTime.parse(item['updatedAt']) : null,
          wordCount: item['wordCount'] ?? 0,
        );
        await journalsBox.put(journal.id, journal);
      }

      // Import Pomodoro
      final pomodoroBox = Hive.box<PomodoroSession>(HiveSetup.pomodorosBox);
      await pomodoroBox.clear();
      final pomodoroList = backupData['pomodoros'] as List;
      for (final item in pomodoroList) {
        final pomodoro = PomodoroSession(
          id: item['id'],
          startTime: DateTime.parse(item['startTime']),
          endTime: DateTime.parse(item['endTime']),
          durationMinutes: item['durationMinutes'],
          isCompleted: item['isCompleted'] ?? true,
          associatedHabitId: item['associatedHabitId'],
          associatedTaskId: item['associatedTaskId'],
          notes: item['notes'],
        );
        await pomodoroBox.put(pomodoro.id, pomodoro);
      }

      // Import Goals
      final goalsBox = Hive.box<GoalModel>(HiveSetup.goalsBox);
      await goalsBox.clear();
      final goalsList = backupData['goals'] as List;
      for (final item in goalsList) {
        final goal = GoalModel(
          id: item['id'],
          title: item['title'],
          type: GoalType.values[item['type'] ?? 0],
          targetValue: item['targetValue'],
          currentValue: item['currentValue'] ?? 0,
          associatedHabitId: item['associatedHabitId'],
          createdAt: DateTime.parse(item['createdAt']),
          deadline: DateTime.parse(item['deadline']),
          isCompleted: item['isCompleted'] ?? false,
        );
        await goalsBox.put(goal.id, goal);
      }

      // Import Achievements
      final achievementsBox = Hive.box<AchievementBadge>(HiveSetup.achievementsBox);
      await achievementsBox.clear();
      final achievementsList = backupData['achievements'] as List;
      for (final item in achievementsList) {
        final achievement = AchievementBadge(
          id: item['id'],
          title: item['title'],
          description: item['description'],
          unlockedAt: DateTime.parse(item['unlockedAt']),
          iconName: item['iconName'],
          isMilestone: item['isMilestone'] ?? false,
        );
        await achievementsBox.put(achievement.id, achievement);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // CSV Export for habits
  Future<String> exportHabitsToCsv() async {
    final habits = Hive.box<HabitModel>(HiveSetup.habitsBox).values.toList();
    final buffer = StringBuffer();
    buffer.writeln('ID,Title,Category,Daily Target,Completed Days,Is Favorite,Is Archived,Created At');
    
    for (final h in habits) {
      buffer.writeln('${h.id},"${h.title.replaceAll('"', '""')}",${h.category},${h.targetCount},${h.completedDates.length},${h.isFavorite},${h.isArchived},${h.createdAt.toIso8601String()}');
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/habitflow_habits.csv');
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  // CSV Export for tasks
  Future<String> exportTasksToCsv() async {
    final tasks = Hive.box<TaskModel>(HiveSetup.tasksBox).values.toList();
    final buffer = StringBuffer();
    buffer.writeln('ID,Title,Is Completed,Is Pinned,Is Archived,Priority,Notes,Created At,Completed At');
    
    for (final t in tasks) {
      buffer.writeln('${t.id},"${t.title.replaceAll('"', '""')}",${t.isCompleted},${t.isPinned},${t.isArchived},${t.priority.name},"${(t.notes ?? '').replaceAll('"', '""')}",${t.createdAt.toIso8601String()},${t.completedAt?.toIso8601String() ?? ''}');
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/habitflow_tasks.csv');
    await file.writeAsString(buffer.toString());
    return file.path;
  }
}
