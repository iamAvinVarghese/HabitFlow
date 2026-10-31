import 'package:hive/hive.dart';
import '../../core/hive/hive_setup.dart';
import '../models/goal_model.dart';

class GoalRepository {
  Box<GoalModel> get _box => Hive.box<GoalModel>(HiveSetup.goalsBox);

  Future<void> addGoal(GoalModel goal) async {
    await _box.put(goal.id, goal);
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _box.put(goal.id, goal);
  }

  Future<void> deleteGoal(String id) async {
    await _box.delete(id);
  }

  List<GoalModel> getAllGoals() {
    return _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<GoalModel> getActiveGoals() {
    final now = DateTime.now();
    return _box.values
        .where((g) => !g.isCompleted && g.deadline.isAfter(now))
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  List<GoalModel> getCompletedGoals() {
    return _box.values
        .where((g) => g.isCompleted)
        .toList()
      ..sort((a, b) => b.deadline.compareTo(a.deadline));
  }

  List<GoalModel> getOverdueGoals() {
    final now = DateTime.now();
    return _box.values
        .where((g) => !g.isCompleted && g.deadline.isBefore(now))
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  Future<void> incrementGoalProgress(String associatedHabitId, {int value = 1}) async {
    final activeGoals = _box.values.where((g) => g.associatedHabitId == associatedHabitId && !g.isCompleted);
    for (final goal in activeGoals) {
      goal.currentValue += value;
      if (goal.currentValue >= goal.targetValue) {
        goal.isCompleted = true;
      }
      await goal.save();
    }
  }

  Future<void> decrementGoalProgress(String associatedHabitId, {int value = 1}) async {
    final activeGoals = _box.values.where((g) => g.associatedHabitId == associatedHabitId);
    for (final goal in activeGoals) {
      if (goal.isCompleted) {
        // If it was completed, mark incomplete again since value decreased
        goal.isCompleted = false;
      }
      goal.currentValue = (goal.currentValue - value).clamp(0, goal.targetValue);
      await goal.save();
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
