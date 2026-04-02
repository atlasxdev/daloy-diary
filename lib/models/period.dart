import 'package:hive/hive.dart';

part 'period.g.dart';

/// Represents a single period (menstruation) event.
///
/// Each time the user starts their period, they create a Period.
/// When it ends, they update [endDate].
///
/// Example:
///   Period started April 1, ended April 5
///   → startDate = April 1, endDate = April 5
@HiveType(typeId: 0)
class Period extends HiveObject {
  /// The day the period started.
  @HiveField(0)
  DateTime startDate;

  /// The day the period ended (null if still ongoing).
  @HiveField(1)
  DateTime? endDate;

  /// Optional notes the user wants to attach.
  @HiveField(2)
  String? notes;

  Period({
    required this.startDate,
    this.endDate,
    this.notes,
  });

  /// How many days the period lasted.
  /// Returns null if the period hasn't ended yet.
  int? get durationDays {
    if (endDate == null) return null;
    return endDate!.difference(startDate).inDays + 1;
  }

  /// Whether the period is still ongoing (no end date set).
  bool get isOngoing => endDate == null;
}
