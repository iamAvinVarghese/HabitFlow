// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'pomodoro_model.dart';

class PomodoroSessionAdapter extends TypeAdapter<PomodoroSession> {
  @override
  final int typeId = 7;

  @override
  PomodoroSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroSession(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
      durationMinutes: fields[3] as int,
      isCompleted: fields[4] as bool,
      associatedHabitId: fields[5] as String?,
      associatedTaskId: fields[6] as String?,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroSession obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.startTime)
      ..writeByte(2)..write(obj.endTime)
      ..writeByte(3)..write(obj.durationMinutes)
      ..writeByte(4)..write(obj.isCompleted)
      ..writeByte(5)..write(obj.associatedHabitId)
      ..writeByte(6)..write(obj.associatedTaskId)
      ..writeByte(7)..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
