import 'package:hive/hive.dart';
import '../../core/hive/hive_setup.dart';
import '../models/achievement_model.dart';

class AchievementRepository {
  Box<AchievementBadge> get _box =>
      Hive.box<AchievementBadge>(HiveSetup.achievementsBox);

  // Predefined badges
  static final List<AchievementBadge> predefinedBadges = [
    AchievementBadge(
      id: 'first_habit',
      title: 'First Step',
      description: 'Completed your very first habit log.',
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
      iconName: 'check_circle_outline_rounded',
    ),
    AchievementBadge(
      id: 'streak_7',
      title: 'Consistency Starter',
      description: 'Reached a 7-day habit streak.',
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
      iconName: 'local_fire_department_rounded',
      isMilestone: true,
    ),
    AchievementBadge(
      id: 'streak_30',
      title: 'Habit Builder',
      description: 'Reached a 30-day habit streak.',
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
      iconName: 'emoji_events_rounded',
      isMilestone: true,
    ),
    AchievementBadge(
      id: 'streak_100',
      title: 'Centurion',
      description: 'Reached a 100-day habit streak.',
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
      iconName: 'shield_rounded',
      isMilestone: true,
    ),
    AchievementBadge(
      id: 'streak_365',
      title: 'Year of Flow',
      description: 'Reached a 365-day habit streak.',
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
      iconName: 'auto_awesome_rounded',
      isMilestone: true,
    ),
    AchievementBadge(
      id: 'first_task',
      title: 'Getting Things Done',
      description: 'Completed your first daily task.',
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
      iconName: 'playlist_add_check_rounded',
    ),
    AchievementBadge(
      id: 'tasks_50',
      title: 'Task Slayer',
      description: 'Completed 50 daily tasks.',
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
      iconName: 'task_alt_rounded',
    ),
    AchievementBadge(
      id: 'pomodoro_first',
      title: 'Deep Focus',
      description: 'Completed your first Pomodoro session.',
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
      iconName: 'timer_rounded',
    ),
    AchievementBadge(
      id: 'journal_first',
      title: 'Self Reflector',
      description: 'Wrote your first daily journal entry.',
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
      iconName: 'book_rounded',
    ),
    AchievementBadge(
      id: 'mood_first',
      title: 'Mindful Moment',
      description: 'Tracked your mood for the first time.',
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
      iconName: 'mood_rounded',
    ),
  ];

  Future<void> unlockAchievement(String id) async {
    if (_box.containsKey(id)) return; // already unlocked

    final predefined = predefinedBadges.firstWhere((b) => b.id == id);
    final badge = AchievementBadge(
      id: predefined.id,
      title: predefined.title,
      description: predefined.description,
      unlockedAt: DateTime.now(),
      iconName: predefined.iconName,
      isMilestone: predefined.isMilestone,
    );
    await _box.put(badge.id, badge);
  }

  bool isUnlocked(String id) {
    return _box.containsKey(id);
  }

  List<AchievementBadge> getUnlockedAchievements() {
    return _box.values.toList()..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
  }

  List<Map<String, dynamic>> getAllAchievementsWithStatus() {
    return predefinedBadges.map((badge) {
      final unlocked = _box.get(badge.id);
      return {
        'id': badge.id,
        'title': badge.title,
        'description': badge.description,
        'iconName': badge.iconName,
        'isMilestone': badge.isMilestone,
        'isUnlocked': unlocked != null,
        'unlockedAt': unlocked?.unlockedAt,
      };
    }).toList();
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
