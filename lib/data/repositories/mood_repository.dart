import 'package:hive/hive.dart';
import '../../core/hive/hive_setup.dart';
import '../models/mood_model.dart';
import '../../core/utils/date_utils.dart';

class MoodRepository {
  Box<MoodEntry> get _moodsBox => Hive.box<MoodEntry>(HiveSetup.moodsBox);

  Future<void> addMoodEntry(MoodEntry entry) async {
    await _moodsBox.put(entry.id, entry);
  }

  Future<void> deleteMoodEntry(String id) async {
    await _moodsBox.delete(id);
  }

  List<MoodEntry> getAllMoodEntries() {
    final list = _moodsBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  MoodEntry? getMoodEntryForDate(DateTime date) {
    final targetKey = AppDateUtils.toStorageKey(date);
    for (final entry in _moodsBox.values) {
      if (AppDateUtils.toStorageKey(entry.date) == targetKey) {
        return entry;
      }
    }
    return null;
  }

  Map<String, double> getAverageMoodByDayOfWeek() {
    final entries = getAllMoodEntries();
    if (entries.isEmpty) return {};

    final counts = <int, int>{};
    final sums = <int, double>{};

    for (final entry in entries) {
      final weekday = entry.date.weekday;
      counts[weekday] = (counts[weekday] ?? 0) + 1;
      sums[weekday] = (sums[weekday] ?? 0.0) + entry.moodScore.toDouble();
    }

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <String, double>{};
    for (int i = 1; i <= 7; i++) {
      if (counts.containsKey(i)) {
        result[weekdays[i - 1]] = sums[i]! / counts[i]!;
      } else {
        result[weekdays[i - 1]] = 0.0;
      }
    }
    return result;
  }

  Future<void> clearAll() async {
    await _moodsBox.clear();
  }
}
