import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/achievement_model.dart';
import '../../data/repositories/achievement_repository.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository();
});

class AchievementNotifier extends StateNotifier<List<AchievementBadge>> {
  final AchievementRepository _repository;

  AchievementNotifier(this._repository) : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getUnlockedAchievements();
  }

  void refresh() {
    _load();
  }

  Future<void> unlockAchievement(String id) async {
    await _repository.unlockAchievement(id);
    _load();
  }
}

final achievementNotifierProvider = StateNotifierProvider<AchievementNotifier, List<AchievementBadge>>((ref) {
  final repo = ref.watch(achievementRepositoryProvider);
  return AchievementNotifier(repo);
});

final allAchievementsWithStatusProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(achievementNotifierProvider);
  final repo = ref.read(achievementRepositoryProvider);
  return repo.getAllAchievementsWithStatus();
});
