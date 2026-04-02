// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogEntryAdapter extends TypeAdapter<LogEntry> {
  @override
  final int typeId = 2;

  @override
  LogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogEntry(
      date: fields[0] as DateTime,
      type: fields[1] as LogType,
      value: fields[2] as String,
      notes: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LogEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.value)
      ..writeByte(3)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LogTypeAdapter extends TypeAdapter<LogType> {
  @override
  final int typeId = 3;

  @override
  LogType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LogType.symptom;
      case 1:
        return LogType.sexualActivity;
      case 2:
        return LogType.mood;
      default:
        return LogType.symptom;
    }
  }

  @override
  void write(BinaryWriter writer, LogType obj) {
    switch (obj) {
      case LogType.symptom:
        writer.writeByte(0);
        break;
      case LogType.sexualActivity:
        writer.writeByte(1);
        break;
      case LogType.mood:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
