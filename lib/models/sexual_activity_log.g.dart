// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sexual_activity_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SexualActivityLogAdapter extends TypeAdapter<SexualActivityLog> {
  @override
  final int typeId = 6;

  @override
  SexualActivityLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SexualActivityLog(
      date: fields[0] as DateTime,
      protectionType: fields[1] as ProtectionType,
      notes: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SexualActivityLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.protectionType)
      ..writeByte(2)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SexualActivityLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProtectionTypeAdapter extends TypeAdapter<ProtectionType> {
  @override
  final int typeId = 5;

  @override
  ProtectionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProtectionType.protected;
      case 1:
        return ProtectionType.unprotected;
      default:
        return ProtectionType.protected;
    }
  }

  @override
  void write(BinaryWriter writer, ProtectionType obj) {
    switch (obj) {
      case ProtectionType.protected:
        writer.writeByte(0);
        break;
      case ProtectionType.unprotected:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProtectionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
