// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'mood_model.dart';

class MoodLevelAdapter extends TypeAdapter<MoodLevel> {
  @override
  final int typeId = 4;

  @override
  MoodLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0: return MoodLevel.terrible;
      case 1: return MoodLevel.bad;
      case 2: return MoodLevel.neutral;
      case 3: return MoodLevel.good;
      case 4: return MoodLevel.excellent;
      default: return MoodLevel.neutral;
    }
  }

  @override
  void write(BinaryWriter writer, MoodLevel obj) {
    writer.writeByte(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 5;

  @override
  MoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoodEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      mood: fields[2] as MoodLevel,
      note: fields[3] as String?,
      tags: (fields[4] as List).cast<String>(),
      energyLevel: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.date)
      ..writeByte(2)..write(obj.mood)
      ..writeByte(3)..write(obj.note)
      ..writeByte(4)..write(obj.tags)
      ..writeByte(5)..write(obj.energyLevel);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
