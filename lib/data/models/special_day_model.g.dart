// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually crafted adapter for SpecialDayModel

part of 'special_day_model.dart';

class SpecialDayTypeAdapter extends TypeAdapter<SpecialDayType> {
  @override
  final int typeId = 11;

  @override
  SpecialDayType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SpecialDayType.oneTime;
      case 1:
        return SpecialDayType.yearly;
      case 2:
        return SpecialDayType.monthly;
      default:
        return SpecialDayType.yearly;
    }
  }

  @override
  void write(BinaryWriter writer, SpecialDayType obj) {
    switch (obj) {
      case SpecialDayType.oneTime:
        writer.writeByte(0);
        break;
      case SpecialDayType.yearly:
        writer.writeByte(1);
        break;
      case SpecialDayType.monthly:
        writer.writeByte(2);
        break;
    }
  }
}

class SpecialDayModelAdapter extends TypeAdapter<SpecialDayModel> {
  @override
  final int typeId = 12;

  @override
  SpecialDayModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpecialDayModel(
      id: fields[0] as String,
      title: fields[1] as String,
      emoji: fields[2] as String? ?? '🎉',
      type: fields[3] as SpecialDayType,
      date: fields[4] as DateTime,
      reminderHour: fields[5] as int? ?? 9,
      reminderMinute: fields[6] as int? ?? 0,
      color: fields[7] as int? ?? 0xFFFFFFFF,
      createdAt: fields[8] as DateTime?,
      notificationIds: (fields[9] as List?)?.cast<int>(),
      notes: fields[10] as String?,
      reminderOffsets: (fields[11] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, SpecialDayModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.reminderHour)
      ..writeByte(6)
      ..write(obj.reminderMinute)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.notificationIds)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.reminderOffsets);
  }
}
