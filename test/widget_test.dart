import 'package:flutter_test/flutter_test.dart';

import 'package:daloy_diary/services/cycle_prediction_service.dart';
import 'package:daloy_diary/models/cycle.dart';

void main() {
  group('CyclePredictionService', () {
    test('returns default 28-day cycle when no history', () {
      final result = CyclePredictionService.averageCycleLength([]);
      expect(result, 28);
    });

    test('averages the last few completed cycles', () {
      final cycles = [
        Cycle(startDate: DateTime(2026, 3, 1), cycleLength: 30),
        Cycle(startDate: DateTime(2026, 2, 1), cycleLength: 28),
        Cycle(startDate: DateTime(2026, 1, 1), cycleLength: 26),
      ];
      // (30 + 28 + 26) / 3 = 28
      expect(CyclePredictionService.averageCycleLength(cycles), 28);
    });

    test('predicts next period from last start + average', () {
      final cycles = [
        Cycle(startDate: DateTime(2026, 3, 1), cycleLength: 30),
      ];
      final predicted = CyclePredictionService.predictNextPeriod(
        lastPeriodStart: DateTime(2026, 3, 1),
        cycles: cycles,
      );
      expect(predicted, DateTime(2026, 3, 31));
    });
  });
}
