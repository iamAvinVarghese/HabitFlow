import 'package:hive/hive.dart';

part 'achievement_model.g.dart';

@HiveType(typeId: 8)
class AchievementBadge extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late DateTime unlockedAt;

  @HiveField(4)
  late String iconName; // e.g. 'fire', 'trophy'

  @HiveField(5)
  late bool isMilestone;

  AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.unlockedAt,
    required this.iconName,
    this.isMilestone = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'unlockedAt': unlockedAt.toIso8601String(),
    'iconName': iconName,
    'isMilestone': isMilestone,
  };
}
