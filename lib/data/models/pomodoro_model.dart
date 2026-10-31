import 'package:hive/hive.dart';

part 'pomodoro_model.g.dart';

@HiveType(typeId: 7)
class PomodoroSession extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime startTime;

  @HiveField(2)
  late DateTime endTime;

  @HiveField(3)
  late int durationMinutes;

  @HiveField(4)
  late bool isCompleted;

  @HiveField(5)
  late String? associatedHabitId;

  @HiveField(6)
  late String? associatedTaskId;

  @HiveField(7)
  late String? notes;

  PomodoroSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.isCompleted = true,
    this.associatedHabitId,
    this.associatedTaskId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'durationMinutes': durationMinutes,
    'isCompleted': isCompleted,
    'associatedHabitId': associatedHabitId,
    'associatedTaskId': associatedTaskId,
    'notes': notes,
  };
}
