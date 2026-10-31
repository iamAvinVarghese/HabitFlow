import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive/hive.dart';

import '../../main.dart';
import '../../data/models/special_day_model.dart';

class NotificationService {
  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'habitflow_channel',
    'HabitFlow Reminders',
    channelDescription: 'Daily habit and task reminders',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    playSound: true,
    enableVibration: true,
  );

  static const NotificationDetails _notificationDetails =
      NotificationDetails(android: _androidDetails);

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Register notification channel for Android explicitly to ensure notification bar gets them
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'habitflow_channel',
        'HabitFlow Reminders',
        description: 'Daily habit and task reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Failed to create Android notification channel: $e');
    }
    
    // Request permission on startup to ensure notifications are shown
    await requestPermissions();

    // Schedule default daily reminders
    await setupDefaultDailyReminders();
  }

  static Future<void> requestPermissions() async {
    try {
      // Request notification permissions using permission_handler for Android 13+
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Exact alarm permission (Android 12+)
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      // Fail silently
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> setupDefaultDailyReminders() async {
    // 1. 11 PM: Complete tasks reminder
    await flutterLocalNotificationsPlugin.zonedSchedule(
      9999,
      'HabitFlow Reminder',
      'Go Hero Check your tasks.',
      _nextInstanceOfTime(23, 0), // 23:00 is 11 PM
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 2. 7 AM: Good Morning Hero
    await flutterLocalNotificationsPlugin.zonedSchedule(
      9998,
      'Good Morning Hero',
      'Every sunrise is a new chance to become a better version of yourself.',
      _nextInstanceOfTime(7, 0), // 07:00 is 7 AM
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 3. 12 AM: Good Night Hero
    await flutterLocalNotificationsPlugin.zonedSchedule(
      9997,
      'Good Night Hero',
      'Good night! Rest well, tomorrow is another chance to achieve your dreams.',
      _nextInstanceOfTime(0, 0), // 00:00 is 12 AM (Midnight)
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    final scheduledTime = _nextInstanceOfTime(hour, minute);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'HabitFlow Reminder',
      'Time to complete: $habitName',
      scheduledTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Log this notification in our local history
    await logNotification(
      id: id,
      title: 'HabitFlow Reminder',
      body: 'Time to complete: $habitName',
      time: scheduledTime,
    );
  }

  static Future<void> scheduleTaskReminder({
    required int id,
    required String taskTitle,
    required DateTime reminderTime,
  }) async {
    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Task Reminder',
      taskTitle,
      tzTime,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Log this notification in our local history
    await logNotification(
      id: id,
      title: 'Task Reminder',
      body: taskTitle,
      time: reminderTime,
    );
  }

  static Future<void> schedulePomodoroReminder({
    required int seconds,
    required bool isBreak,
  }) async {
    final scheduledTime = DateTime.now().add(Duration(seconds: seconds));
    final title = isBreak ? 'Break Completed!' : 'Focus Completed!';
    final body = isBreak ? 'Time to get back to work, Hero.' : 'Take a break, you earned it!';

    await flutterLocalNotificationsPlugin.zonedSchedule(
      9996, // Fixed ID for Pomodoro reminders
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Log the Pomodoro completion event in our local history
    await logNotification(
      id: 9996,
      title: title,
      body: body,
      time: scheduledTime,
    );
  }

  static Future<void> cancelPomodoroReminder() async {
    await cancelNotification(9996);
  }

  // --- Special Day Reminders ---

  /// Schedules 4 notifications for a special day: 7d, 3d, 1d before and on the day.
  /// Returns the list of notification IDs assigned (4 ids).
  static Future<List<int>> scheduleSpecialDayReminders({
    required String id,
    required String title,
    required String emoji,
    required DateTime date,
    required int reminderHour,
    required int reminderMinute,
    required SpecialDayType type,
    List<int>? customOffsets,
  }) async {
    // Derive a stable base ID from the uuid hash to avoid conflicts
    int baseId = (id.hashCode.abs() % 10000) * 10 + 10000;

    final List<int> offsets = customOffsets != null && customOffsets.isNotEmpty
        ? (List<int>.from(customOffsets)..sort((a, b) => b.compareTo(a)))
        : [7, 3, 1, 0];

    final List<String> titles = offsets.map((off) {
      if (off == 0) return 'Today: $title';
      if (off == 1) return '$title — Tomorrow';
      return '$title — $off Days Away';
    }).toList();

    final List<int> ids = [];

    for (int i = 0; i < offsets.length; i++) {
      final notifId = baseId + i;
      ids.add(notifId);

      // Cancel any previously scheduled notification with this ID
      await flutterLocalNotificationsPlugin.cancel(notifId);

      // Compute target datetime
      late DateTime targetDt;
      final now = DateTime.now();

      if (type == SpecialDayType.yearly) {
        // Find the next occurrence of (month/day) offset by `offsets[i]` days
        DateTime eventThisYear = DateTime(now.year, date.month, date.day);
        final notifyDate = eventThisYear.subtract(Duration(days: offsets[i]));
        final notifyDt = DateTime(
          notifyDate.year,
          notifyDate.month,
          notifyDate.day,
          reminderHour,
          reminderMinute,
        );
        if (notifyDt.isBefore(now)) {
          final eventNextYear = DateTime(now.year + 1, date.month, date.day);
          final notifyDateNext = eventNextYear.subtract(Duration(days: offsets[i]));
          targetDt = DateTime(
            notifyDateNext.year,
            notifyDateNext.month,
            notifyDateNext.day,
            reminderHour,
            reminderMinute,
          );
        } else {
          targetDt = notifyDt;
        }
      } else if (type == SpecialDayType.monthly) {
        final daysInThisMonth = DateUtils.getDaysInMonth(now.year, now.month);
        final dayThisMonth = date.day.clamp(1, daysInThisMonth);
        final eventThisMonth = DateTime(now.year, now.month, dayThisMonth);
        final notifyDate = eventThisMonth.subtract(Duration(days: offsets[i]));
        final notifyDt = DateTime(
          notifyDate.year,
          notifyDate.month,
          notifyDate.day,
          reminderHour,
          reminderMinute,
        );

        if (notifyDt.isBefore(now)) {
          int nextMonth = now.month + 1;
          int nextYear = now.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear++;
          }
          final daysInNextMonth = DateUtils.getDaysInMonth(nextYear, nextMonth);
          final dayNextMonth = date.day.clamp(1, daysInNextMonth);
          final eventNextMonth = DateTime(nextYear, nextMonth, dayNextMonth);
          final notifyDateNext = eventNextMonth.subtract(Duration(days: offsets[i]));
          targetDt = DateTime(
            notifyDateNext.year,
            notifyDateNext.month,
            notifyDateNext.day,
            reminderHour,
            reminderMinute,
          );
        } else {
          targetDt = notifyDt;
        }
      } else {
        // One-time: exact date
        final eventDay = DateTime(date.year, date.month, date.day);
        final notifyDate = eventDay.subtract(Duration(days: offsets[i]));
        targetDt = DateTime(
          notifyDate.year,
          notifyDate.month,
          notifyDate.day,
          reminderHour,
          reminderMinute,
        );
      }

      final tzTime = tz.TZDateTime.from(targetDt, tz.local);
      if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) continue;

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'special_days_channel',
        'Special Day Reminders',
        channelDescription: 'Reminders for birthdays, anniversaries and special events',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );
      final notifDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notifId,
        titles[i],
        offsets[i] == 0
            ? 'Don\'t forget to celebrate today!'
            : 'Mark your calendar — $title is coming up!',
        tzTime,
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // For yearly events: repeat every year by re-scheduling on day match
      );

      await logNotification(
        id: notifId,
        title: titles[i],
        body: offsets[i] == 0
            ? 'Don\'t forget to celebrate today!'
            : 'Mark your calendar — $title is coming up!',
        time: targetDt,
      );
    }

    return ids;
  }

  static Future<void> cancelSpecialDayReminders(List<int> ids) async {
    for (final id in ids) {
      await cancelNotification(id);
    }
  }

  static Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    // Also remove from future logs if not yet fired
    await removeFutureLog(id);
  }

  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // --- Notification History & Unread Status Methods ---

  static Future<void> logNotification({
    required int id,
    required String title,
    required String body,
    required DateTime time,
  }) async {
    try {
      final box = Hive.box('settings');
      final List<dynamic> rawLogs = box.get('notification_logs', defaultValue: []);
      final List<Map<String, dynamic>> logs = List<Map<String, dynamic>>.from(
        rawLogs.map((e) => Map<String, dynamic>.from(e as Map)),
      );

      // Remove existing logs for the same ID to avoid duplicates
      logs.removeWhere((item) => item['id'] == id);

      logs.add({
        'id': id,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
      });

      // Maintain a maximum of 50 notifications in history
      if (logs.length > 50) {
        logs.removeAt(0);
      }

      await box.put('notification_logs', logs);
    } catch (e) {
      debugPrint('Failed to log notification: $e');
    }
  }

  static Future<void> removeFutureLog(int id) async {
    try {
      final box = Hive.box('settings');
      final List<dynamic> rawLogs = box.get('notification_logs', defaultValue: []);
      final List<Map<String, dynamic>> logs = List<Map<String, dynamic>>.from(
        rawLogs.map((e) => Map<String, dynamic>.from(e as Map)),
      );

      logs.removeWhere((item) {
        final time = DateTime.parse(item['time'] as String);
        return item['id'] == id && time.isAfter(DateTime.now());
      });

      await box.put('notification_logs', logs);
    } catch (e) {
      // Fail silently
    }
  }

  static Future<bool> hasNewNotifications() async {
    try {
      final box = Hive.box('settings');
      final String? lastReadStr = box.get('last_read_notifications');
      final DateTime lastRead = lastReadStr != null
          ? DateTime.parse(lastReadStr)
          : DateTime.now().subtract(const Duration(days: 7));

      final now = DateTime.now();

      // Check recurring daily reminders (7 AM, 11 PM, 12 AM)
      final dailyTimes = [
        DateTime(now.year, now.month, now.day, 7, 0),
        DateTime(now.year, now.month, now.day, 23, 0),
        DateTime(now.year, now.month, now.day, 0, 0),
      ];

      for (var dt in dailyTimes) {
        if (dt.isBefore(now) && dt.isAfter(lastRead)) {
          return true;
        }
        final yesterdayDt = dt.subtract(const Duration(days: 1));
        if (yesterdayDt.isBefore(now) && yesterdayDt.isAfter(lastRead)) {
          return true;
        }
      }

      // Check task/habit/pomodoro logs that have fired in the past
      final List<dynamic> rawLogs = box.get('notification_logs', defaultValue: []);
      for (var item in rawLogs) {
        final map = Map<String, dynamic>.from(item as Map);
        final time = DateTime.parse(map['time'] as String);
        if (time.isBefore(now) && time.isAfter(lastRead)) {
          return true;
        }
      }
    } catch (e) {
      // Fail silently
    }
    return false;
  }

  static Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    final List<Map<String, dynamic>> history = [];
    try {
      final box = Hive.box('settings');
      final now = DateTime.now();

      // 1. Generate daily reminders history for the last 2 days
      final List<DateTime> dailyReminders = [];
      for (int i = 0; i < 2; i++) {
        final day = now.subtract(Duration(days: i));
        dailyReminders.add(DateTime(day.year, day.month, day.day, 7, 0));  // 7 AM
        dailyReminders.add(DateTime(day.year, day.month, day.day, 23, 0)); // 11 PM
        dailyReminders.add(DateTime(day.year, day.month, day.day, 0, 0));  // 12 AM
      }

      for (var dt in dailyReminders) {
        if (dt.isBefore(now)) {
          String title = '';
          String body = '';
          if (dt.hour == 7) {
            title = 'Good Morning Hero';
            body = 'Every sunrise is a new chance to become a better version of yourself.';
          } else if (dt.hour == 23) {
            title = 'HabitFlow Reminder';
            body = 'Go Hero Check your tasks.';
          } else if (dt.hour == 0) {
            title = 'Good Night Hero';
            body = 'Good night! Rest well, tomorrow is another chance to achieve your dreams.';
          }

          history.add({
            'title': title,
            'body': body,
            'time': dt,
          });
        }
      }

      // 2. Fetch logged task/habit/pomodoro notifications that have fired
      final List<dynamic> rawLogs = box.get('notification_logs', defaultValue: []);
      for (var item in rawLogs) {
        final map = Map<String, dynamic>.from(item as Map);
        final time = DateTime.parse(map['time'] as String);
        if (time.isBefore(now)) {
          history.add({
            'title': map['title'] as String,
            'body': map['body'] as String,
            'time': time,
          });
        }
      }

      // Sort by time descending (newest first)
      history.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
    } catch (e) {
      // Fail silently
    }
    return history;
  }

  static Future<void> markNotificationsAsRead() async {
    try {
      final box = Hive.box('settings');
      await box.put('last_read_notifications', DateTime.now().toIso8601String());
    } catch (e) {
      // Fail silently
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
