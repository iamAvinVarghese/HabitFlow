import 'package:hive/hive.dart';

part 'special_day_model.g.dart';

@HiveType(typeId: 11)
enum SpecialDayType {
  @HiveField(0)
  oneTime, // fires once on exact date

  @HiveField(1)
  yearly, // repeats every year on same month/day (birthdays, anniversaries)

  @HiveField(2)
  monthly, // repeats every month on same day (bills, subscriptions, renewals)
}

@HiveType(typeId: 12)
class SpecialDayModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String emoji;

  @HiveField(3)
  late SpecialDayType type;

  /// For oneTime: full date used. For yearly: only month and day are used. For monthly: only day is used.
  @HiveField(4)
  late DateTime date;

  /// Hour of day for the notification (default 9 AM)
  @HiveField(5)
  late int reminderHour;

  /// Minute of hour for the notification (default 0)
  @HiveField(6)
  late int reminderMinute;

  /// ARGB int color for the card accent
  @HiveField(7)
  late int color;

  @HiveField(8)
  late DateTime createdAt;

  /// IDs for the scheduled notifications
  @HiveField(9)
  late List<int> notificationIds;

  /// Optional quick note / description for this event
  @HiveField(10)
  late String? notes;

  /// The reminder day-offsets chosen by the user (e.g. [30, 7, 3, 1, 0])
  @HiveField(11)
  late List<int> reminderOffsets;

  SpecialDayModel({
    required this.id,
    required this.title,
    this.emoji = '🎉',
    this.type = SpecialDayType.yearly,
    required this.date,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.color = 0xFFFFFFFF,
    DateTime? createdAt,
    List<int>? notificationIds,
    this.notes,
    List<int>? reminderOffsets,
  })  : createdAt = createdAt ?? DateTime.now(),
        notificationIds = notificationIds ?? [],
        reminderOffsets = reminderOffsets ?? [7, 3, 1, 0];

  SpecialDayModel copyWith({
    String? id,
    String? title,
    String? emoji,
    SpecialDayType? type,
    DateTime? date,
    int? reminderHour,
    int? reminderMinute,
    int? color,
    DateTime? createdAt,
    List<int>? notificationIds,
    String? notes,
    List<int>? reminderOffsets,
  }) {
    return SpecialDayModel(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      date: date ?? this.date,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      notificationIds: notificationIds ?? List.from(this.notificationIds),
      notes: notes ?? this.notes,
      reminderOffsets: reminderOffsets ?? List.from(this.reminderOffsets),
    );
  }

  /// Returns days until the next occurrence. Returns 0 if today.
  int get daysUntilNext {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (type == SpecialDayType.oneTime) {
      final eventDay = DateTime(date.year, date.month, date.day);
      final diff = eventDay.difference(today).inDays;
      return diff < 0 ? -1 : diff;
    } else if (type == SpecialDayType.monthly) {
      int targetYear = now.year;
      int targetMonth = now.month;
      int daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
      int targetDay = date.day.clamp(1, daysInMonth);

      DateTime candidate = DateTime(targetYear, targetMonth, targetDay);
      if (candidate.isBefore(today)) {
        targetMonth++;
        if (targetMonth > 12) {
          targetMonth = 1;
          targetYear++;
        }
        daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        targetDay = date.day.clamp(1, daysInMonth);
        candidate = DateTime(targetYear, targetMonth, targetDay);
      }
      return candidate.difference(today).inDays;
    } else {
      // Yearly: find next occurrence
      DateTime candidate = DateTime(now.year, date.month, date.day);
      if (candidate.isBefore(today)) {
        candidate = DateTime(now.year + 1, date.month, date.day);
      }
      return candidate.difference(today).inDays;
    }
  }

  /// Returns true if the event has already passed (for one-time events).
  bool get isPast {
    if (type == SpecialDayType.yearly || type == SpecialDayType.monthly) return false;
    return DateTime(date.year, date.month, date.day)
        .isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'type': type.index,
        'date': date.toIso8601String(),
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
        'notificationIds': notificationIds,
        'notes': notes,
        'reminderOffsets': reminderOffsets,
      };
}
