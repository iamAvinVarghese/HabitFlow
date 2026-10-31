import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/journal_model.dart';
import '../../data/repositories/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  final JournalRepository _repository;

  JournalNotifier(this._repository) : super([]) {
    _load();
  }

  void _load() {
    state = _repository.getAllJournalEntries();
  }

  void refresh() {
    _load();
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    await _repository.saveJournalEntry(entry);
    _load();
  }

  Future<void> deleteJournalEntry(String id) async {
    await _repository.deleteJournalEntry(id);
    _load();
  }
}

final journalNotifierProvider = StateNotifierProvider<JournalNotifier, List<JournalEntry>>((ref) {
  final repo = ref.watch(journalRepositoryProvider);
  return JournalNotifier(repo);
});

final todayJournalEntryProvider = Provider<JournalEntry?>((ref) {
  ref.watch(journalNotifierProvider);
  final repo = ref.read(journalRepositoryProvider);
  return repo.getJournalEntryForDate(DateTime.now());
});

final journalSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedJournalsProvider = Provider<List<JournalEntry>>((ref) {
  final query = ref.watch(journalSearchQueryProvider);
  final repo = ref.read(journalRepositoryProvider);
  if (query.isEmpty) return ref.watch(journalNotifierProvider);
  return repo.searchJournalEntries(query);
});
