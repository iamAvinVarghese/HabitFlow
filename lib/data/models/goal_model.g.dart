// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'goal_model.dart';

class GoalTypeAdapter extends TypeAdapter<GoalType> {
  @override
  final int typeId = 9;

  @override
  GoalType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0: return GoalType.daily;
      case 1: return GoalType.weekly;
      case 2: return GoalType.monthly;
      default: return GoalType.daily;
    }
  }

  @override
  void write(BinaryWriter writer, GoalType obj) {
    writer.writeByte(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalModelAdapter extends TypeAdapter<GoalModel> {
  @override
  final int typeId = 10;

  @override
  GoalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalModel(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as GoalType,
      targetValue: fields[3] as int,
      currentValue: fields[4] as int,
      associatedHabitId: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      deadline: fields[7] as DateTime,
      isCompleted: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, GoalModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.type)
      ..writeByte(3)..write(obj.targetValue)
      ..writeByte(4)..write(obj.currentValue)
      ..writeByte(5)..write(obj.associatedHabitId)
      ..writeByte(6)..write(obj.createdAt)
      ..writeByte(7)..write(obj.deadline)
      ..writeByte(8)..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
