import 'package:hive/hive.dart';

part 'log_entry.g.dart';

/// The type of log the user is recording.
///
/// We use an enum so we can easily filter logs by type later
/// (e.g. "show me only symptom logs").
@HiveType(typeId: 3)
enum LogType {
  @HiveField(0)
  symptom,

  @HiveField(1)
  sexualActivity,

  @HiveField(2)
  mood,
}

/// A single daily log entry.
///
/// This is a flexible model — the user can log symptoms, sexual activity,
/// or mood for any given date. Each entry has a [type] and a [value].
///
/// Examples:
///   type: symptom,        value: "cramps",   date: April 2
///   type: sexualActivity,  value: "protected", date: April 3
///   type: mood,            value: "happy",     date: April 2
@HiveType(typeId: 2)
class LogEntry extends HiveObject {
  /// The date this log is for.
  @HiveField(0)
  DateTime date;

  /// What kind of log this is (symptom, sexual activity, or mood).
  @HiveField(1)
  LogType type;

  /// The actual value — e.g. "cramps", "protected", "tired".
  @HiveField(2)
  String value;

  /// Optional free-text notes.
  @HiveField(3)
  String? notes;

  LogEntry({
    required this.date,
    required this.type,
    required this.value,
    this.notes,
  });
}
