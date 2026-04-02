import '../models/cycle.dart';

/// CyclePredictionService calculates when the next period is expected.
///
/// Per docs/notifications.md, the prediction formula is:
///   average_cycle_length = average(last 3-6 cycles)
///   next_period_date = last_period_start + average_cycle_length
///
/// This service is used by NotificationService to know
/// WHEN to schedule pre-period alerts.
class CyclePredictionService {
  // If the user has no history yet, assume a 28-day cycle.
  // 28 days is the medical "textbook" average.
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;

  /// Calculate the average cycle length from the user's history.
  ///
  /// [cycles] — list of past cycles (must have cycleLength set).
  /// [maxCycles] — how many recent cycles to average (default: 6).
  ///
  /// Returns the default (28) if there's no usable history.
  static int averageCycleLength(List<Cycle> cycles, {int maxCycles = 6}) {
    // Filter to cycles that have a known length (completed cycles only).
    final completedCycles =
        cycles.where((c) => c.cycleLength != null).toList();

    if (completedCycles.isEmpty) return defaultCycleLength;

    // Sort newest first, then take only the most recent ones.
    completedCycles.sort((a, b) => b.startDate.compareTo(a.startDate));
    final recentCycles = completedCycles.take(maxCycles).toList();

    // Calculate the average.
    final totalDays =
        recentCycles.fold<int>(0, (sum, c) => sum + c.cycleLength!);
    return (totalDays / recentCycles.length).round();
  }

  /// Calculate the average period length from the user's history.
  static int averagePeriodLength(List<Cycle> cycles, {int maxCycles = 6}) {
    final withPeriodLength =
        cycles.where((c) => c.periodLength != null).toList();

    if (withPeriodLength.isEmpty) return defaultPeriodLength;

    withPeriodLength.sort((a, b) => b.startDate.compareTo(a.startDate));
    final recent = withPeriodLength.take(maxCycles).toList();

    final totalDays =
        recent.fold<int>(0, (sum, c) => sum + c.periodLength!);
    return (totalDays / recent.length).round();
  }

  /// Predict the start date of the next period.
  ///
  /// [lastPeriodStart] — when the most recent period started.
  /// [cycles] — the user's cycle history.
  ///
  /// Returns a DateTime for the predicted next period start.
  static DateTime predictNextPeriod({
    required DateTime lastPeriodStart,
    required List<Cycle> cycles,
  }) {
    final avgLength = averageCycleLength(cycles);
    return lastPeriodStart.add(Duration(days: avgLength));
  }
}
