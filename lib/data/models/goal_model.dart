import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 9)
enum GoalType {
  @HiveField(0)
  daily,

  @HiveField(1)
  weekly,

  @HiveField(2)
  monthly,
}

@HiveType(typeId: 10)
class GoalModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late GoalType type;

  @HiveField(3)
  late int targetValue;

  @HiveField(4)
  late int currentValue;

  @HiveField(5)
  late String? associatedHabitId;

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  late DateTime deadline;

  @HiveField(8)
  late bool isCompleted;

  GoalModel({
    required this.id,
    required this.title,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    this.associatedHabitId,
    DateTime? createdAt,
    required this.deadline,
    this.isCompleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  GoalModel copyWith({
    String? id,
    String? title,
    GoalType? type,
    int? targetValue,
    int? currentValue,
    String? associatedHabitId,
    DateTime? createdAt,
    DateTime? deadline,
    bool? isCompleted,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      associatedHabitId: associatedHabitId ?? this.associatedHabitId,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.index,
    'targetValue': targetValue,
    'currentValue': currentValue,
    'associatedHabitId': associatedHabitId,
    'createdAt': createdAt.toIso8601String(),
    'deadline': deadline.toIso8601String(),
    'isCompleted': isCompleted,
  };
}
