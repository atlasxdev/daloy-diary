import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme.dart';
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

    return Scaffold(
      body: Stack(
        children: [
          // Gradient header background.
          _buildGradientHeader(context),
          // Scrollable content layered on top.
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title on gradient.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    'Hey there',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onPrimary,
                          letterSpacing: -0.5,
                        ),
                  ),
                ),
                // Content.
                Expanded(
                  child: periods.isEmpty
                      ? _buildEmptyState(context)
                      : _buildDashboard(
                          context, periods, cycles, todayLogs, todayActivity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    final gradient = AppTheme.getHeaderGradient(context);
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 0.8, 1.0],
          colors: [
            gradient.colors.first,
            gradient.colors.last,
            gradient.colors.last.withValues(alpha: 0.25),
            scaffoldBg,
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: cs.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Daloy Diary',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to the Calendar tab to log\nyour first period.',
              textAlign: TextAlign.center,
              style: tt.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cycle status label on gradient.
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Cycle status',
              style: tt.labelLarge?.copyWith(
                color: cs.onPrimary.withValues(alpha: 0.85),
              ),
            ),
          ),

          // ── Cycle ring card (overlaps gradient) ──
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
                  value: daysUntilNext <= 0 ? 'Due' : 'In $daysUntilNext d',
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

  // ── Cycle ring card ──────────────────────────────────────────

  Widget _buildCycleCard(
    BuildContext context,
    int cycleDay,
    int cycleLength,
    _CyclePhase phase,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = (cycleDay / cycleLength).clamp(0.0, 1.0);
    final color = _phaseColor(context, phase);

    return Card(
      color: cs.surfaceContainerHighest,
      elevation: 2,
      shadowColor: cs.shadow.withValues(alpha: 0.1),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: _CycleRingPainter(
                  progress: progress,
                  color: color,
                  trackColor: cs.outlineVariant.withValues(alpha: 0.25),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$cycleDay',
                        style: tt.displayLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          letterSpacing: -2,
                        ),
                      ),
                      Text(
                        'of $cycleLength',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              phase.label,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              phase.description,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
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
    final tt = Theme.of(context).textTheme;

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
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Log section ────────────────────────────────────────

  Widget _buildQuickLogSection(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Log',
            style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _quickLogCircle(
              context,
              icon: Icons.water_drop_outlined,
              label: 'Period',
              color: AppTheme.periodColor(context),
            ),
            _quickLogCircle(
              context,
              icon: Icons.healing,
              label: 'Symptoms',
              color: AppTheme.periodColor(context),
            ),
            _quickLogCircle(
              context,
              icon: Icons.emoji_emotions_outlined,
              label: 'Mood',
              color: AppTheme.moodColor(context),
            ),
            _quickLogCircle(
              context,
              icon: Icons.favorite_outline,
              label: 'Intimacy',
              color: AppTheme.activityColor(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickLogCircle(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.85),
                  color.withValues(alpha: 0.45),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: cs.onPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Insight card ─────────────────────────────────────────────

  Widget _buildInsightCard(
    BuildContext context,
    _CyclePhase phase,
    int daysUntilNext,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
      margin: EdgeInsets.zero,
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
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
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

  Widget _buildTodayLogs(
      BuildContext context, List<LogEntry> logs, SexualActivityLog? activity) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "Today's Logs",
            style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        if (logs.isEmpty && activity == null)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Nothing logged today.\nTap the Log tab to add entries.',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final log in logs) _buildLogRow(context, log),
                  if (activity != null) _buildActivityRow(context, activity),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogRow(BuildContext context, LogEntry log) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                  style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  log.type.name,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(BuildContext context, SexualActivityLog activity) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
                Text(
                  label,
                  style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Sexual activity',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
