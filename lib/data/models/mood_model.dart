import 'package:hive/hive.dart';

part 'mood_model.g.dart';

@HiveType(typeId: 4)
enum MoodLevel {
  @HiveField(0)
  terrible,

  @HiveField(1)
  bad,

  @HiveField(2)
  neutral,

  @HiveField(3)
  good,

  @HiveField(4)
  excellent,
}

@HiveType(typeId: 5)
class MoodEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime date;

  @HiveField(2)
  late MoodLevel mood;

  @HiveField(3)
  late String? note;

  @HiveField(4)
  late List<String> tags;

  @HiveField(5)
  late int energyLevel; // 1-5

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    this.note,
    List<String>? tags,
    this.energyLevel = 3,
  }) : tags = tags ?? [];


  String get moodLabel {
    switch (mood) {
      case MoodLevel.terrible: return 'Terrible';
      case MoodLevel.bad: return 'Bad';
      case MoodLevel.neutral: return 'Neutral';
      case MoodLevel.good: return 'Good';
      case MoodLevel.excellent: return 'Excellent';
    }
  }

  int get moodScore {
    switch (mood) {
      case MoodLevel.terrible: return 1;
      case MoodLevel.bad: return 2;
      case MoodLevel.neutral: return 3;
      case MoodLevel.good: return 4;
      case MoodLevel.excellent: return 5;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'mood': mood.index,
    'note': note,
    'tags': tags,
    'energyLevel': energyLevel,
  };
}
