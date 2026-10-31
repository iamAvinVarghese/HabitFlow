import 'package:hive/hive.dart';
import '../../core/hive/hive_setup.dart';
import '../models/journal_model.dart';
import '../../core/utils/date_utils.dart';

class JournalRepository {
  Box<JournalEntry> get _journalsBox => Hive.box<JournalEntry>(HiveSetup.journalsBox);

  Future<void> saveJournalEntry(JournalEntry entry) async {
    await _journalsBox.put(entry.id, entry);
  }

  Future<void> deleteJournalEntry(String id) async {
    await _journalsBox.delete(id);
  }

  List<JournalEntry> getAllJournalEntries() {
    final list = _journalsBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  JournalEntry? getJournalEntryForDate(DateTime date) {
    final targetKey = AppDateUtils.toStorageKey(date);
    for (final entry in _journalsBox.values) {
      if (AppDateUtils.toStorageKey(entry.date) == targetKey) {
        return entry;
      }
    }
    return null;
  }

  List<JournalEntry> searchJournalEntries(String query) {
    if (query.isEmpty) return getAllJournalEntries();
    final lowercaseQuery = query.toLowerCase();
    return _journalsBox.values
        .where((entry) =>
            entry.title.toLowerCase().contains(lowercaseQuery) ||
            entry.content.toLowerCase().contains(lowercaseQuery) ||
            entry.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> clearAll() async {
    await _journalsBox.clear();
  }
}
