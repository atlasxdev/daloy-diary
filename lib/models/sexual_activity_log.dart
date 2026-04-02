import 'package:hive/hive.dart';

part 'sexual_activity_log.g.dart';

/// Whether protection was used during sexual activity.
@HiveType(typeId: 5)
enum ProtectionType {
  @HiveField(0)
  protected,

  @HiveField(1)
  unprotected,
}

/// A single sexual activity log entry for a specific date.
///
/// Each entry records whether protection was used and allows
/// optional free-text notes. One entry per date.
@HiveType(typeId: 6)
class SexualActivityLog extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  ProtectionType protectionType;

  @HiveField(2)
  String? notes;

  SexualActivityLog({
    required this.date,
    required this.protectionType,
    this.notes,
  });
}
