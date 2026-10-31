import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 2)
enum TaskPriority {
  @HiveField(0)
  high,

  @HiveField(1)
  medium,

  @HiveField(2)
  low,
}

@HiveType(typeId: 3)
class TaskModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late bool isCompleted;

  @HiveField(3)
  late bool isPinned;

  @HiveField(4)
  late bool isArchived;

  @HiveField(5)
  late TaskPriority priority;

  @HiveField(6)
  late String? notes;

  @HiveField(7)
  late DateTime? reminderTime;

  @HiveField(8)
  late DateTime createdAt;

  @HiveField(9)
  late DateTime? completedAt;

  @HiveField(10)
  late int? notificationId;

  TaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.isPinned = false,
    this.isArchived = false,
    this.priority = TaskPriority.medium,
    this.notes,
    this.reminderTime,
    DateTime? createdAt,
    this.completedAt,
    this.notificationId,
  }) : createdAt = createdAt ?? DateTime.now();

  TaskModel copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    bool? isPinned,
    bool? isArchived,
    TaskPriority? priority,
    String? notes,
    DateTime? reminderTime,
    DateTime? createdAt,
    DateTime? completedAt,
    int? notificationId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'isPinned': isPinned,
    'isArchived': isArchived,
    'priority': priority.index,
    'notes': notes,
    'reminderTime': reminderTime?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'notificationId': notificationId,
  };
}
