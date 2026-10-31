import 'package:hive/hive.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 0)
class HabitModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String category;

  @HiveField(3)
  late int targetCount;

  @HiveField(4)
  late List<String> completedDates; // 'yyyy-MM-dd' format

  @HiveField(5)
  late bool isFavorite;

  @HiveField(6)
  late bool isArchived;

  @HiveField(7)
  late String? notes;

  @HiveField(8)
  late int? reminderHour;

  @HiveField(9)
  late int? reminderMinute;

  @HiveField(10)
  late DateTime createdAt;

  @HiveField(11)
  late List<String> skippedDates; // 'yyyy-MM-dd' format

  @HiveField(12)
  late int color; // stored as int (0xFFFFFF for white by default)

  @HiveField(13)
  late List<int>? repeatDays; // stored as list of ints (1 = Mon, ..., 7 = Sun). null/empty means all days.

  HabitModel({
    required this.id,
    required this.title,
    required this.category,
    this.targetCount = 1,
    List<String>? completedDates,
    this.isFavorite = false,
    this.isArchived = false,
    this.notes,
    this.reminderHour,
    this.reminderMinute,
    DateTime? createdAt,
    List<String>? skippedDates,
    this.color = 0xFFFFFFFF,
    this.repeatDays,
  })  : completedDates = completedDates ?? [],
        skippedDates = skippedDates ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool isCompletedToday() {
    final todayKey = _todayKey();
    return completedDates.contains(todayKey);
  }

  bool isSkippedToday() {
    final todayKey = _todayKey();
    return skippedDates.contains(todayKey);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  HabitModel copyWith({
    String? id,
    String? title,
    String? category,
    int? targetCount,
    List<String>? completedDates,
    bool? isFavorite,
    bool? isArchived,
    String? notes,
    int? reminderHour,
    int? reminderMinute,
    DateTime? createdAt,
    List<String>? skippedDates,
    int? color,
    List<int>? repeatDays,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      targetCount: targetCount ?? this.targetCount,
      completedDates: completedDates ?? List.from(this.completedDates),
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      notes: notes ?? this.notes,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      createdAt: createdAt ?? this.createdAt,
      skippedDates: skippedDates ?? List.from(this.skippedDates),
      color: color ?? this.color,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'targetCount': targetCount,
    'completedDates': completedDates,
    'isFavorite': isFavorite,
    'isArchived': isArchived,
    'notes': notes,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'createdAt': createdAt.toIso8601String(),
    'skippedDates': skippedDates,
    'color': color,
    'repeatDays': repeatDays,
  };
}
