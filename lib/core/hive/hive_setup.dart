import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/habit_model.dart';
import '../../data/models/habit_log_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/mood_model.dart';
import '../../data/models/journal_model.dart';
import '../../data/models/pomodoro_model.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/special_day_model.dart';

class HiveSetup {
  static const String habitsBox = 'habits';
  static const String habitLogsBox = 'habit_logs';
  static const String tasksBox = 'tasks';
  static const String settingsBox = 'settings';
  static const String moodsBox = 'moods';
  static const String journalsBox = 'journals';
  static const String pomodorosBox = 'pomodoros';
  static const String achievementsBox = 'achievements';
  static const String goalsBox = 'goals';
  static const String specialDaysBox = 'special_days';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(HabitModelAdapter());
    Hive.registerAdapter(HabitLogModelAdapter());
    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(MoodLevelAdapter());
    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(PomodoroSessionAdapter());
    Hive.registerAdapter(AchievementBadgeAdapter());
    Hive.registerAdapter(GoalTypeAdapter());
    Hive.registerAdapter(GoalModelAdapter());
    Hive.registerAdapter(SpecialDayTypeAdapter());
    Hive.registerAdapter(SpecialDayModelAdapter());

    // Open boxes
    await Hive.openBox<HabitModel>(habitsBox);
    await Hive.openBox<HabitLogModel>(habitLogsBox);
    await Hive.openBox<TaskModel>(tasksBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox<MoodEntry>(moodsBox);
    await Hive.openBox<JournalEntry>(journalsBox);
    await Hive.openBox<PomodoroSession>(pomodorosBox);
    await Hive.openBox<AchievementBadge>(achievementsBox);
    await Hive.openBox<GoalModel>(goalsBox);
    await Hive.openBox<SpecialDayModel>(specialDaysBox);
  }
}
