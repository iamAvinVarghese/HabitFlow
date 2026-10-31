import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

class GoalNotifier extends StateNotifier<List<GoalModel>> {
  final GoalRepository _repository;

  GoalNotifier(this._repository) : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getAllGoals();
  }

  void refresh() {
    _load();
  }

  Future<void> addGoal(GoalModel goal) async {
    await _repository.addGoal(goal);
    _load();
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _repository.updateGoal(goal);
    _load();
  }

  Future<void> deleteGoal(String id) async {
    await _repository.deleteGoal(id);
    _load();
  }

  Future<void> incrementGoalProgress(String associatedHabitId, {int value = 1}) async {
    await _repository.incrementGoalProgress(associatedHabitId, value: value);
    _load();
  }

  Future<void> decrementGoalProgress(String associatedHabitId, {int value = 1}) async {
    await _repository.decrementGoalProgress(associatedHabitId, value: value);
    _load();
  }
}

final goalNotifierProvider = StateNotifierProvider<GoalNotifier, List<GoalModel>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  return GoalNotifier(repo);
});

final activeGoalsProvider = Provider<List<GoalModel>>((ref) {
  ref.watch(goalNotifierProvider);
  final repo = ref.read(goalRepositoryProvider);
  return repo.getActiveGoals();
});

final completedGoalsProvider = Provider<List<GoalModel>>((ref) {
  ref.watch(goalNotifierProvider);
  final repo = ref.read(goalRepositoryProvider);
  return repo.getCompletedGoals();
});

final overdueGoalsProvider = Provider<List<GoalModel>>((ref) {
  ref.watch(goalNotifierProvider);
  final repo = ref.read(goalRepositoryProvider);
  return repo.getOverdueGoals();
});
