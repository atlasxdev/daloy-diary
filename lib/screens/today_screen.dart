import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/gradient_header.dart';
import '../models/period.dart';
import '../models/cycle.dart';
import '../models/log_entry.dart';
import '../models/sexual_activity_log.dart';
import '../services/storage_service.dart';
import '../services/cycle_prediction_service.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _storage = StorageService();

  @override
  Widget build(BuildContext context) {
    final periods = _storage.getAllPeriods();
    final cycles = _storage.getAllCycles();
    final today = DateTime.now();
    final todayLogs = _storage.getLogsForDate(today);
    final todayActivity = _storage.getSexualActivityForDate(today);

    return GradientScaffold(
      title: 'Today',
      gradientHeight: 240,
      child: periods.isEmpty
          ? _buildEmptyState(context)
          : _buildDashboard(context, periods, cycles, todayLogs, todayActivity),
    );
  }

  // ── Empty state ──────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
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

  // ── Dashboard ────────────────────────────────────────────────

  Widget _buildDashboard(
    BuildContext context,
    List<Period> periods,
    List<Cycle> cycles,
    List<LogEntry> todayLogs,
    SexualActivityLog? todayActivity,
  ) {
    final today = _dateOnly(DateTime.now());
    final latestPeriod = periods.first;
    final avgCycleLen = CyclePredictionService.averageCycleLength(cycles);
    final avgPeriodLen = CyclePredictionService.averagePeriodLength(cycles);
    final nextPeriod = CyclePredictionService.predictNextPeriod(
      lastPeriodStart: latestPeriod.startDate,
      cycles: cycles,
    );

    final cycleDay =
        today.difference(_dateOnly(latestPeriod.startDate)).inDays + 1;
    final daysUntilNext = _dateOnly(nextPeriod).difference(today).inDays;

    final phase = _getCyclePhase(
      cycleDay: cycleDay,
      periodLength: avgPeriodLen,
      cycleLength: avgCycleLen,
      isOngoing: latestPeriod.isOngoing,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cycle status label.
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Cycle status',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),

          // ── Cycle ring card ──
          _buildCycleCard(context, cycleDay, avgCycleLen, phase),
          const SizedBox(height: 16),

          // ── 3 stat cards ──
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  context,
                  icon: Icons.today_outlined,
                  label: 'Today',
                  value: 'Day $cycleDay',
                  color: _phaseColor(context, phase),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStat(
                  context,
                  icon: Icons.egg_outlined,
                  label: 'Ovulation',
                  value: '~Day ${(avgCycleLen * 0.5).round()}',
                  color: AppTheme.fertileColor(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStat(
                  context,
                  icon: Icons.event_outlined,
                  label: 'Period',
                  value: daysUntilNext <= 0
                      ? 'Due'
                      : 'In $daysUntilNext d',
                  color: AppTheme.predictedColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Quick Log section ──
          _buildQuickLogSection(context),
          const SizedBox(height: 24),

          // ── Insight card ──
          _buildInsightCard(context, phase, daysUntilNext),
          const SizedBox(height: 16),

          // ── Today's logs ──
          _buildTodayLogs(context, todayLogs, todayActivity),
        ],
      ),
    );
  }

  // ── Cycle ring card (centered, prominent) ────────────────────

  Widget _buildCycleCard(
    BuildContext context,
    int cycleDay,
    int cycleLength,
    _CyclePhase phase,
  ) {
    final cs = Theme.of(context).colorScheme;
    final progress = (cycleDay / cycleLength).clamp(0.0, 1.0);
    final color = _phaseColor(context, phase);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            // Ring.
            SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: _CycleRingPainter(
                  progress: progress,
                  color: color,
                  trackColor: cs.outline.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$cycleDay',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: -2,
                        ),
                      ),
                      Text(
                        'of $cycleLength',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Phase label.
            Text(
              phase.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              phase.description,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mini stat card ───────────────────────────────────────────

  Widget _buildMiniStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Log section ────────────────────────────────────────

  Widget _buildQuickLogSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Log',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5),
              letterSpacing: -0.2,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _quickLogButton(
              icon: Icons.water_drop_outlined,
              label: 'Period',
              color: AppTheme.periodColor(context),
            ),
            _quickLogButton(
              icon: Icons.healing,
              label: 'Symptoms',
              color: AppTheme.periodColor(context),
            ),
            _quickLogButton(
              icon: Icons.emoji_emotions_outlined,
              label: 'Mood',
              color: AppTheme.moodColor(context),
            ),
            _quickLogButton(
              icon: Icons.favorite_outline,
              label: 'Intimacy',
              color: AppTheme.activityColor(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickLogButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0.5),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
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
                color: _phaseColor(context, phase).withValues(alpha: 0.12),
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

  // ── Today's logs ─────────────────────────────────────────────

  Widget _buildTodayLogs(BuildContext context, List<LogEntry> logs, SexualActivityLog? activity) {
    final cs = Theme.of(context).colorScheme;

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
              color: cs.onSurface.withValues(alpha: 0.5),
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (logs.isEmpty && activity == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Nothing logged today.\nTap the Log tab to add entries.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.4),
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
                  if (activity != null)
                    _buildActivityRow(context, activity),
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
        color = AppTheme.activityColor(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                Text(
                  log.type.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(BuildContext context, SexualActivityLog activity) {
    final color = AppTheme.activityColor(context);
    final label = activity.protectionType == ProtectionType.protected
        ? 'Protected'
        : 'Unprotected';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.favorite_outline, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Text(
                  'Sexual activity',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase logic ──────────────────────────────────────────────

  _CyclePhase _getCyclePhase({
    required int cycleDay,
    required int periodLength,
    required int cycleLength,
    required bool isOngoing,
  }) {
    if (isOngoing || cycleDay <= periodLength) return _CyclePhase.period;
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

// ── Phase enum ──────────────────────────────────────────────

enum _CyclePhase {
  period('Period', 'Menstruation phase'),
  follicular('Follicular', 'Building energy'),
  fertile('Fertile Window', 'Ovulation approaching'),
  luteal('Luteal', 'Winding down');

  final String label;
  final String description;
  const _CyclePhase(this.label, this.description);
}

// ── Ring painter ────────────────────────────────────────────

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
    final radius = (size.width - 12) / 2;
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CycleRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
