import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pomodoro_model.dart';
import '../../data/repositories/pomodoro_repository.dart';

final pomodoroRepositoryProvider = Provider<PomodoroRepository>((ref) {
  return PomodoroRepository();
});

class PomodoroNotifier extends StateNotifier<List<PomodoroSession>> {
  final PomodoroRepository _repository;

  PomodoroNotifier(this._repository) : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getAllSessions();
  }

  void refresh() {
    _load();
  }

  Future<void> saveSession(PomodoroSession session) async {
    await _repository.saveSession(session);
    _load();
  }

  Future<void> deleteSession(String id) async {
    await _repository.deleteSession(id);
    _load();
  }
}

final pomodoroNotifierProvider = StateNotifierProvider<PomodoroNotifier, List<PomodoroSession>>((ref) {
  final repo = ref.watch(pomodoroRepositoryProvider);
  return PomodoroNotifier(repo);
});

final totalFocusTimeMinutesProvider = Provider<int>((ref) {
  ref.watch(pomodoroNotifierProvider);
  final repo = ref.read(pomodoroRepositoryProvider);
  return repo.getTotalFocusTimeMinutes();
});

final completedPomodorosCountProvider = Provider<int>((ref) {
  ref.watch(pomodoroNotifierProvider);
  final repo = ref.read(pomodoroRepositoryProvider);
  return repo.getCompletedSessionCount();
});

final dailyFocusTimeLast7DaysProvider = Provider<Map<String, int>>((ref) {
  ref.watch(pomodoroNotifierProvider);
  final repo = ref.read(pomodoroRepositoryProvider);
  return repo.getDailyFocusTimeLast7Days();
});
