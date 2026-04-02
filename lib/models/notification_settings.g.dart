// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationSettingsAdapter extends TypeAdapter<NotificationSettings> {
  @override
  final int typeId = 4;

  @override
  NotificationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettings(
      notificationsEnabled: fields[0] as bool,
      dailyRemindersEnabled: fields[1] as bool,
      prePeriodAlertsEnabled: fields[2] as bool,
      reminderHour: fields[3] as int,
      reminderMinute: fields[4] as int,
      alertHour: fields[5] as int,
      alertMinute: fields[6] as int,
      prePeriodAlertDays: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.notificationsEnabled)
      ..writeByte(1)
      ..write(obj.dailyRemindersEnabled)
      ..writeByte(2)
      ..write(obj.prePeriodAlertsEnabled)
      ..writeByte(3)
      ..write(obj.reminderHour)
      ..writeByte(4)
      ..write(obj.reminderMinute)
      ..writeByte(5)
      ..write(obj.alertHour)
      ..writeByte(6)
      ..write(obj.alertMinute)
      ..writeByte(7)
      ..write(obj.prePeriodAlertDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
