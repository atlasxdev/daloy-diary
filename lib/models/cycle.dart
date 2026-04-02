import 'package:hive/hive.dart';

part 'cycle.g.dart';

/// Represents one full menstrual cycle.
///
/// A "cycle" is measured from the START of one period to the START of the next.
/// This is the standard medical definition.
///
/// Example:
///   Period started March 1 → next period started March 29
///   → cycleLength = 28 days, periodLength = 5 days
@HiveType(typeId: 1)
class Cycle extends HiveObject {
  /// The start date of this cycle (= start of the period).
  @HiveField(0)
  DateTime startDate;

  /// Total cycle length in days (start-to-start of next period).
  /// Null if the next period hasn't started yet (current cycle).
  @HiveField(1)
  int? cycleLength;

  /// How many days the period lasted within this cycle.
  @HiveField(2)
  int? periodLength;

  Cycle({
    required this.startDate,
    this.cycleLength,
    this.periodLength,
  });
}
