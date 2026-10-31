import 'package:hive/hive.dart';
import '../../core/hive/hive_setup.dart';
import '../models/pomodoro_model.dart';

class PomodoroRepository {
  Box<PomodoroSession> get _pomodoroBox =>
      Hive.box<PomodoroSession>(HiveSetup.pomodorosBox);

  Future<void> saveSession(PomodoroSession session) async {
    await _pomodoroBox.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    await _pomodoroBox.delete(id);
  }

  List<PomodoroSession> getAllSessions() {
    final list = _pomodoroBox.values.toList();
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  List<PomodoroSession> getSessionsForHabit(String habitId) {
    return _pomodoroBox.values
        .where((s) => s.associatedHabitId == habitId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  List<PomodoroSession> getSessionsForTask(String taskId) {
    return _pomodoroBox.values
        .where((s) => s.associatedTaskId == taskId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  int getTotalFocusTimeMinutes() {
    return _pomodoroBox.values
        .where((s) => s.isCompleted)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int getCompletedSessionCount() {
    return _pomodoroBox.values.where((s) => s.isCompleted).length;
  }

  Map<String, int> getDailyFocusTimeLast7Days() {
    final now = DateTime.now();
    final result = <String, int>{};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final sum = _pomodoroBox.values.where((s) {
        if (!s.isCompleted) return false;
        final sKey = '${s.startTime.year}-${s.startTime.month.toString().padLeft(2, '0')}-${s.startTime.day.toString().padLeft(2, '0')}';
        return sKey == dateKey;
      }).fold(0, (sum, s) => sum + s.durationMinutes);

      result[dateKey] = sum;
    }

    return result;
  }

  Future<void> clearAll() async {
    await _pomodoroBox.clear();
  }
}
