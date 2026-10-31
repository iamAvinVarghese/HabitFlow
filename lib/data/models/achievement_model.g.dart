// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'achievement_model.dart';

class AchievementBadgeAdapter extends TypeAdapter<AchievementBadge> {
  @override
  final int typeId = 8;

  @override
  AchievementBadge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AchievementBadge(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      unlockedAt: fields[3] as DateTime,
      iconName: fields[4] as String,
      isMilestone: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AchievementBadge obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.description)
      ..writeByte(3)..write(obj.unlockedAt)
      ..writeByte(4)..write(obj.iconName)
      ..writeByte(5)..write(obj.isMilestone);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementBadgeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
