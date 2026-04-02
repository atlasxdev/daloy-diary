import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/period.dart';
import '../models/cycle.dart';
import '../models/log_entry.dart';
import '../services/storage_service.dart';
import '../services/cycle_prediction_service.dart';

/// The "Today" tab — a quick-glance dashboard showing current
/// cycle status, phase, and today's logs.
///
/// HIG layout principles applied:
///   - Large, bold title at top
///   - Clear visual hierarchy: most important info largest
///   - Cards for grouping related info
///   - Generous whitespace between sections
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _storage = StorageService();

  @override
  Widget build(BuildContext context) {
    // Rebuild every time this tab becomes visible.
    final periods = _storage.getAllPeriods();
    final cycles = _storage.getAllCycles();
    final today = DateTime.now();
    final todayLogs = _storage.getLogsForDate(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: periods.isEmpty
            ? _buildEmptyState(context)
            : _buildDashboard(context, periods, cycles, todayLogs),
      ),
    );
  }

  // ── Empty state (no data yet) ────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Daloy Diary',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to the Calendar tab to log\nyour first period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main dashboard ───────────────────────────────────────────

  Widget _buildDashboard(
    BuildContext context,
    List<Period> periods,
    List<Cycle> cycles,
    List<LogEntry> todayLogs,
  ) {
    final today = _dateOnly(DateTime.now());
    final latestPeriod = periods.first;
    final avgCycleLen = CyclePredictionService.averageCycleLength(cycles);
    final avgPeriodLen = CyclePredictionService.averagePeriodLength(cycles);
    final nextPeriod = CyclePredictionService.predictNextPeriod(
      lastPeriodStart: latestPeriod.startDate,
      cycles: cycles,
    );

    // Calculate cycle day (1-indexed from last period start).
    final cycleDay =
        today.difference(_dateOnly(latestPeriod.startDate)).inDays + 1;

    // Days until next period.
    final daysUntilNext = _dateOnly(nextPeriod).difference(today).inDays;

    // Determine current phase.
    final phase = _getCyclePhase(
      cycleDay: cycleDay,
      periodLength: avgPeriodLen,
      cycleLength: avgCycleLen,
      isOngoing: latestPeriod.isOngoing,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Phase ring + cycle day ──
        _buildPhaseCard(context, cycleDay, avgCycleLen, phase),
        const SizedBox(height: 16),

        // ── Key stats row ──
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Next period',
                value: daysUntilNext <= 0 ? 'Due' : '$daysUntilNext',
                unit: daysUntilNext <= 0 ? '' : daysUntilNext == 1 ? 'day' : 'days',
                color: AppTheme.predictedColor(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Cycle length',
                value: '$avgCycleLen',
                unit: 'days avg',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Insight / phase message ──
        _buildInsightCard(context, phase, daysUntilNext),
        const SizedBox(height: 16),

        // ── Today's logs ──
        _buildTodayLogs(context, todayLogs),
      ],
    );
  }

  // ── Phase card with circular progress ────────────────────────

  Widget _buildPhaseCard(
    BuildContext context,
    int cycleDay,
    int cycleLength,
    _CyclePhase phase,
  ) {
    final progress = (cycleDay / cycleLength).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        child: Row(
          children: [
            // Circular progress ring.
            SizedBox(
              width: 88,
              height: 88,
              child: CustomPaint(
                painter: _CycleRingPainter(
                  progress: progress,
                  color: _phaseColor(context, phase),
                  trackColor: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$cycleDay',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _phaseColor(context, phase),
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'of $cycleLength',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Phase label.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day $cycleDay',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phase.label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _phaseColor(context, phase),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phase.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stat cards ───────────────────────────────────────────────

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -1,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Insight card ─────────────────────────────────────────────

  Widget _buildInsightCard(
    BuildContext context,
    _CyclePhase phase,
    int daysUntilNext,
  ) {
    String message;
    switch (phase) {
      case _CyclePhase.period:
        message = 'Take it easy — rest and stay hydrated.';
      case _CyclePhase.follicular:
        message = 'Energy is rising — great time for activity.';
      case _CyclePhase.fertile:
        message = 'Fertile window — be mindful if needed.';
      case _CyclePhase.luteal:
        if (daysUntilNext <= 3 && daysUntilNext > 0) {
          message = 'Period expected soon — prepare ahead.';
        } else {
          message = 'You may feel low energy — be kind to yourself.';
        }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _phaseColor(context, phase).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                color: _phaseColor(context, phase),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Today's logs section ─────────────────────────────────────

  Widget _buildTodayLogs(BuildContext context, List<LogEntry> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "Today's Logs",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (logs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Nothing logged today.\nTap the Log tab to add entries.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final log in logs)
                    _buildLogRow(context, log),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogRow(BuildContext context, LogEntry log) {
    IconData icon;
    Color color;
    switch (log.type) {
      case LogType.symptom:
        icon = Icons.healing;
        color = AppTheme.periodColor(context);
      case LogType.mood:
        icon = Icons.emoji_emotions_outlined;
        color = AppTheme.moodColor(context);
      case LogType.sexualActivity:
        icon = Icons.favorite_outline;
        color = AppTheme.moodColor(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  log.type.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cycle phase logic ────────────────────────────────────────

  _CyclePhase _getCyclePhase({
    required int cycleDay,
    required int periodLength,
    required int cycleLength,
    required bool isOngoing,
  }) {
    if (isOngoing || cycleDay <= periodLength) return _CyclePhase.period;

    // Approximate phases based on a standard cycle:
    // Follicular: after period ends → day ~13
    // Fertile window: ~day 12-16
    // Luteal: ~day 17 → end of cycle
    final follicularEnd = (cycleLength * 0.45).round();
    final fertileEnd = (cycleLength * 0.55).round();

    if (cycleDay <= follicularEnd) return _CyclePhase.follicular;
    if (cycleDay <= fertileEnd) return _CyclePhase.fertile;
    return _CyclePhase.luteal;
  }

  Color _phaseColor(BuildContext context, _CyclePhase phase) {
    switch (phase) {
      case _CyclePhase.period:
        return AppTheme.periodColor(context);
      case _CyclePhase.follicular:
        return AppTheme.fertileColor(context);
      case _CyclePhase.fertile:
        return AppTheme.fertileColor(context);
      case _CyclePhase.luteal:
        return AppTheme.moodColor(context);
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

// ── Cycle phase enum ─────────────────────────────────────────

enum _CyclePhase {
  period('Period', 'Menstruation phase'),
  follicular('Follicular', 'Building energy'),
  fertile('Fertile Window', 'Ovulation approaching'),
  luteal('Luteal', 'Winding down');

  final String label;
  final String description;
  const _CyclePhase(this.label, this.description);
}

// ── Circular progress ring painter ───────────────────────────

class _CycleRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _CycleRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 6.0;

    // Track (background ring).
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc.
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,          // Start from top
      2 * math.pi * progress, // Sweep angle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CycleRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
