import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/special_day_model.dart';
import '../../data/repositories/special_day_repository.dart';
import '../../core/utils/notification_service.dart';

final specialDayRepositoryProvider = Provider<SpecialDayRepository>((ref) {
  return SpecialDayRepository();
});

class SpecialDayNotifier extends StateNotifier<List<SpecialDayModel>> {
  final SpecialDayRepository _repo;

  SpecialDayNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  void refresh() => _load();

  Future<void> add(SpecialDayModel model, {List<int>? customOffsets}) async {
    List<int> ids = [];
    try {
      ids = await NotificationService.scheduleSpecialDayReminders(
        id: model.id,
        title: model.title,
        emoji: model.emoji,
        date: model.date,
        reminderHour: model.reminderHour,
        reminderMinute: model.reminderMinute,
        type: model.type,
        customOffsets: customOffsets,
      );
    } catch (_) {
      // Notification scheduling failed — save data anyway
    }

    final updatedModel = model.copyWith(notificationIds: ids);
    await _repo.add(updatedModel);
    _load();
  }

  Future<void> update(SpecialDayModel model, {List<int>? customOffsets}) async {
    // Cancel old notifications (best-effort)
    if (model.notificationIds.isNotEmpty) {
      try {
        await NotificationService.cancelSpecialDayReminders(model.notificationIds);
      } catch (_) {}
    }

    // Reschedule notifications (best-effort)
    List<int> ids = [];
    try {
      ids = await NotificationService.scheduleSpecialDayReminders(
        id: model.id,
        title: model.title,
        emoji: model.emoji,
        date: model.date,
        reminderHour: model.reminderHour,
        reminderMinute: model.reminderMinute,
        type: model.type,
        customOffsets: customOffsets,
      );
    } catch (_) {
      // Notification scheduling failed — save data anyway
    }

    final updatedModel = model.copyWith(notificationIds: ids);
    await _repo.update(updatedModel);
    _load();
  }

  Future<void> delete(SpecialDayModel model) async {
    // Cancel all notifications (best-effort)
    if (model.notificationIds.isNotEmpty) {
      try {
        await NotificationService.cancelSpecialDayReminders(model.notificationIds);
      } catch (_) {}
    }
    await _repo.delete(model.id);
    _load();
  }
}

final specialDayNotifierProvider =
    StateNotifierProvider<SpecialDayNotifier, List<SpecialDayModel>>((ref) {
  final repo = ref.watch(specialDayRepositoryProvider);
  return SpecialDayNotifier(repo);
});
