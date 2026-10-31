import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  static String formatDayMonth(DateTime date) {
    return DateFormat('EEEE, MMMM d').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String toStorageKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static DateTime fromStorageKey(String key) {
    return DateFormat('yyyy-MM-dd').parse(key);
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static int calculateStreak(List<String> completedDateKeys) {
    if (completedDateKeys.isEmpty) return 0;

    final sorted = completedDateKeys
        .map((k) => fromStorageKey(k))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime current = stripTime(DateTime.now());

    for (final date in sorted) {
      if (isSameDay(date, current) ||
          isSameDay(date, current.subtract(const Duration(days: 1)))) {
        streak++;
        current = date;
      } else {
        break;
      }
    }

    return streak;
  }

  static int calculateLongestStreak(List<String> completedDateKeys) {
    if (completedDateKeys.isEmpty) return 0;

    final sorted = completedDateKeys
        .map((k) => fromStorageKey(k))
        .toList()
      ..sort();

    int longest = 1;
    int current = 1;

    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (diff > 1) {
        current = 1;
      }
    }

    return longest;
  }
}
