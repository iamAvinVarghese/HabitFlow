import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/notification_service.dart';

final notificationHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return NotificationService.getNotificationHistory();
});

class HasNewNotificationsNotifier extends StateNotifier<bool> {
  HasNewNotificationsNotifier() : super(false) {
    check();
  }

  Future<void> check() async {
    state = await NotificationService.hasNewNotifications();
  }

  Future<void> markAsRead() async {
    await NotificationService.markNotificationsAsRead();
    state = false;
  }
}

final hasNewNotificationsProvider = StateNotifierProvider<HasNewNotificationsNotifier, bool>((ref) {
  return HasNewNotificationsNotifier();
});
