import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mood_model.dart';
import '../../data/repositories/mood_repository.dart';

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  return MoodRepository();
});

class MoodNotifier extends StateNotifier<List<MoodEntry>> {
  final MoodRepository _repository;

  MoodNotifier(this._repository) : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getAllMoodEntries();
  }

  void refresh() {
    _load();
  }

  Future<void> addMoodEntry(MoodEntry entry) async {
    await _repository.addMoodEntry(entry);
    _load();
  }

  Future<void> deleteMoodEntry(String id) async {
    await _repository.deleteMoodEntry(id);
    _load();
  }
}

final moodNotifierProvider = StateNotifierProvider<MoodNotifier, List<MoodEntry>>((ref) {
  final repo = ref.watch(moodRepositoryProvider);
  return MoodNotifier(repo);
});

final todayMoodEntryProvider = Provider<MoodEntry?>((ref) {
  ref.watch(moodNotifierProvider);
  final repo = ref.read(moodRepositoryProvider);
  return repo.getMoodEntryForDate(DateTime.now());
});

final averageMoodByDayOfWeekProvider = Provider<Map<String, double>>((ref) {
  ref.watch(moodNotifierProvider);
  final repo = ref.read(moodRepositoryProvider);
  return repo.getAverageMoodByDayOfWeek();
});
