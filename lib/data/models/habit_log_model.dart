import 'package:hive/hive.dart';

part 'habit_log_model.g.dart';

@HiveType(typeId: 1)
class HabitLogModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String habitId;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late int count;

  @HiveField(4)
  late String action; // 'complete', 'skip'

  HabitLogModel({
    required this.id,
    required this.habitId,
    required this.date,
    this.count = 1,
    this.action = 'complete',
  });
}
