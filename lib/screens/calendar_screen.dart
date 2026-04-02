import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/theme.dart';
import '../core/gradient_header.dart';
import '../models/period.dart';
import '../models/cycle.dart';
import '../models/log_entry.dart';
import '../models/sexual_activity_log.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/cycle_prediction_service.dart';
import 'log_entry_screen.dart';

/// Calendar tab — month view with color-coded days.
///
/// HIG calendar guidance:
///   - Clean grid with generous cell spacing
///   - Semantic color only (not decorative)
///   - Tapping a day shows a contextual action sheet
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _storage = StorageService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Period> _periods = [];
  List<Cycle> _cycles = [];
  DateTime? _nextPredictedPeriod;
  int _avgPeriodLength = CyclePredictionService.defaultPeriodLength;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final periods = _storage.getAllPeriods();
    final cycles = _storage.getAllCycles();

    DateTime? nextPredicted;
    int avgPeriodLen = CyclePredictionService.defaultPeriodLength;

    if (periods.isNotEmpty) {
      nextPredicted = CyclePredictionService.predictNextPeriod(
        lastPeriodStart: periods.first.startDate,
        cycles: cycles,
      );
      avgPeriodLen = CyclePredictionService.averagePeriodLength(cycles);
    }

    setState(() {
      _periods = periods;
      _cycles = cycles;
      _nextPredictedPeriod = nextPredicted;
      _avgPeriodLength = avgPeriodLen;
    });
  }

  // ── Day checks ───────────────────────────────────────────────

  bool _isPeriodDay(DateTime day) {
    for (final period in _periods) {
      final start = _dateOnly(period.startDate);
      final end = period.endDate != null ? _dateOnly(period.endDate!) : start;
      if (!day.isBefore(start) && !day.isAfter(end)) return true;
    }
    return false;
  }

  bool _isPredictedDay(DateTime day) {
    if (_nextPredictedPeriod == null) return false;
    if (_isPeriodDay(day)) return false;
    final predStart = _dateOnly(_nextPredictedPeriod!);
    final predEnd = predStart.add(Duration(days: _avgPeriodLength - 1));
    return !day.isBefore(predStart) && !day.isAfter(predEnd);
  }

  Period? get _ongoingPeriod {
    for (final period in _periods) {
      if (period.isOngoing) return period;
    }
    return null;
  }

  bool _hasLogs(DateTime day) => _storage.getLogsForDate(day).isNotEmpty;

  bool _hasSexualActivity(DateTime day) =>
      _storage.getSexualActivityForDate(day) != null;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ── User actions ─────────────────────────────────────────────

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _showDayActions(selectedDay);
  }

  void _showDayActions(DateTime day) {
    final ongoingPeriod = _ongoingPeriod;
    final isPeriod = _isPeriodDay(day);
    final logsForDay = _storage.getLogsForDate(day);
    final activityLog = _storage.getSexualActivityForDate(day);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date header.
                Text(
                  _formatDate(day),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Status chips.
                if (isPeriod || _isPredictedDay(day))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (isPeriod)
                          _statusChip(
                            'Period day',
                            AppTheme.periodColor(context),
                          ),
                        if (_isPredictedDay(day))
                          _statusChip(
                            'Predicted',
                            AppTheme.predictedColor(context),
                          ),
                      ],
                    ),
                  ),

                // Existing logs summary.
                if (logsForDay.isNotEmpty || activityLog != null) ...[
                  _buildLogsSummary(logsForDay, activityLog),
                  const SizedBox(height: 12),
                ],

                // Period actions.
                if (ongoingPeriod != null)
                  _actionButton(
                    icon: Icons.stop_circle_outlined,
                    label: 'End period on this day',
                    color: AppTheme.periodColor(context),
                    onTap: () {
                      Navigator.pop(context);
                      _endPeriod(ongoingPeriod, day);
                    },
                  )
                else if (!isPeriod)
                  _actionButton(
                    icon: Icons.play_circle_outlined,
                    label: 'Start period on this day',
                    color: AppTheme.periodColor(context),
                    onTap: () {
                      Navigator.pop(context);
                      _startPeriod(day);
                    },
                  ),

                const SizedBox(height: 8),

                // Log button.
                _actionButton(
                  icon: Icons.edit_note,
                  label: logsForDay.isNotEmpty
                      ? 'Edit symptoms & mood'
                      : 'Log symptoms & mood',
                  color: AppTheme.moodColor(context),
                  filled: false,
                  onTap: () {
                    Navigator.pop(context);
                    _openLogEntryScreen(day);
                  },
                ),

                const SizedBox(height: 8),

                // Sexual activity button.
                _actionButton(
                  icon: Icons.favorite_outline,
                  label: activityLog != null
                      ? 'Edit sexual activity'
                      : 'Log sexual activity',
                  color: AppTheme.activityColor(context),
                  filled: false,
                  onTap: () {
                    Navigator.pop(context);
                    _showSexualActivitySheet(day, existing: activityLog);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = true,
  }) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(backgroundColor: color),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _buildLogsSummary(List<LogEntry> logs, SexualActivityLog? activityLog) {
    final symptoms =
        logs.where((l) => l.type == LogType.symptom).map((l) => l.value);
    final moods =
        logs.where((l) => l.type == LogType.mood).map((l) => l.value);

    final items = <_LogSummaryItem>[
      if (symptoms.isNotEmpty)
        _LogSummaryItem(Icons.healing, AppTheme.periodColor(context),
            symptoms.join(', ')),
      if (moods.isNotEmpty)
        _LogSummaryItem(Icons.emoji_emotions_outlined,
            AppTheme.moodColor(context), moods.join(', ')),
      if (activityLog != null)
        _LogSummaryItem(
          Icons.favorite_outline,
          AppTheme.activityColor(context),
          activityLog.protectionType == ProtectionType.protected
              ? 'Protected'
              : 'Unprotected',
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(item.icon, size: 15, color: item.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.text,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Period start / end logic (unchanged) ─────────────────────

  Future<void> _startPeriod(DateTime day) async {
    final previousPeriod = _periods.isNotEmpty ? _periods.first : null;
    final newPeriod = Period(startDate: _dateOnly(day));
    await _storage.addPeriod(newPeriod);

    if (previousPeriod != null) {
      final prevCycles = _cycles.where(
        (c) => _dateOnly(c.startDate) == _dateOnly(previousPeriod.startDate),
      );
      if (prevCycles.isNotEmpty) {
        final prevCycle = prevCycles.first;
        prevCycle.cycleLength = _dateOnly(day)
            .difference(_dateOnly(previousPeriod.startDate))
            .inDays;
        await _storage.updateCycle(prevCycle);
      }
    }

    final newCycle = Cycle(startDate: _dateOnly(day));
    await _storage.addCycle(newCycle);

    _loadData();
    await _rescheduleNotifications(currentPeriodStart: _dateOnly(day));
  }

  Future<void> _endPeriod(Period period, DateTime day) async {
    period.endDate = _dateOnly(day);
    await _storage.updatePeriod(period);

    final matchingCycles = _cycles.where(
      (c) => _dateOnly(c.startDate) == _dateOnly(period.startDate),
    );
    if (matchingCycles.isNotEmpty) {
      final cycle = matchingCycles.first;
      cycle.periodLength = period.durationDays;
      await _storage.updateCycle(cycle);
    }

    _loadData();
    await _rescheduleNotifications(currentPeriodStart: null);
  }

  Future<void> _rescheduleNotifications({DateTime? currentPeriodStart}) async {
    final settings = _storage.getNotificationSettings();
    if (!settings.notificationsEnabled) {
      await NotificationService.cancelAll();
      return;
    }

    final periods = _storage.getAllPeriods();
    final cycles = _storage.getAllCycles();
    if (periods.isEmpty) {
      await NotificationService.cancelAll();
      return;
    }

    final nextPeriod = CyclePredictionService.predictNextPeriod(
      lastPeriodStart: periods.first.startDate,
      cycles: cycles,
    );
    final avgPeriodLen = CyclePredictionService.averagePeriodLength(cycles);

    await NotificationService.cancelAll();

    if (settings.dailyRemindersEnabled && currentPeriodStart != null) {
      await NotificationService.scheduleDailyReminders(
        periodStartDate: currentPeriodStart,
        periodLengthDays: avgPeriodLen,
        reminderTime: TimeOfDay(
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
        ),
      );
    }
    if (settings.prePeriodAlertsEnabled) {
      await NotificationService.schedulePrePeriodAlerts(
        nextPeriodDate: nextPeriod,
        daysBefore: settings.prePeriodAlertDays,
        alertTime: TimeOfDay(
          hour: settings.alertHour,
          minute: settings.alertMinute,
        ),
      );
    }
  }

  void _showSexualActivitySheet(DateTime day, {SexualActivityLog? existing}) {
    var selectedType = existing?.protectionType;
    final notesController =
        TextEditingController(text: existing?.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cs = Theme.of(context).colorScheme;
            final color = AppTheme.activityColor(context);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  4,
                  24,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing != null
                          ? 'Edit Sexual Activity'
                          : 'Log Sexual Activity',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(day),
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Protection type selector.
                    Text(
                      'Protection',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _protectionChip(
                            label: 'Protected',
                            icon: Icons.shield_outlined,
                            isSelected:
                                selectedType == ProtectionType.protected,
                            color: color,
                            onTap: () => setSheetState(() {
                              selectedType = ProtectionType.protected;
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _protectionChip(
                            label: 'Unprotected',
                            icon: Icons.remove_circle_outline,
                            isSelected:
                                selectedType == ProtectionType.unprotected,
                            color: color,
                            onTap: () => setSheetState(() {
                              selectedType = ProtectionType.unprotected;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Notes field.
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Optional notes...',
                        hintStyle: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.3),
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: cs.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: cs.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: color),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button.
                    FilledButton(
                      onPressed: selectedType == null
                          ? null
                          : () async {
                              final notes =
                                  notesController.text.trim().isNotEmpty
                                      ? notesController.text.trim()
                                      : null;

                              if (existing != null) {
                                existing.protectionType = selectedType!;
                                existing.notes = notes;
                                await _storage
                                    .updateSexualActivityLog(existing);
                              } else {
                                await _storage.addSexualActivityLog(
                                  SexualActivityLog(
                                    date: _dateOnly(day),
                                    protectionType: selectedType!,
                                    notes: notes,
                                  ),
                                );
                              }

                              if (mounted) {
                                Navigator.pop(context);
                                setState(() {});
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                      ),
                      child: Text(existing != null ? 'Update' : 'Save'),
                    ),

                    // Delete button (only when editing).
                    if (existing != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          await _storage
                              .deleteSexualActivityLog(existing);
                          if (mounted) {
                            Navigator.pop(context);
                            setState(() {});
                          }
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: cs.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _protectionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : cs.outline.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : cs.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLogEntryScreen(DateTime day) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => LogEntryScreen(date: day)),
    );
    if (result == true) setState(() {});
  }

  String _formatDate(DateTime day) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[day.month]} ${day.day}, ${day.year}';
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      title: 'Calendar',
      gradientHeight: 160,
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _selectedDay != null && isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.periodColor(context),
                  width: 1.5,
                ),
              ),
              todayTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              selectedDecoration: BoxDecoration(
                color: AppTheme.periodColor(context),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              defaultTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              weekendTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              weekendStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, isToday: false),
              todayBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, isToday: true),
              selectedBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, isToday: false, isSelected: true),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          Expanded(child: _buildSummary()),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day, {
    required bool isToday,
    bool isSelected = false,
  }) {
    final isPeriod = _isPeriodDay(day);
    final isPredicted = _isPredictedDay(day);
    final hasLog = _hasLogs(day);
    final hasActivity = _hasSexualActivity(day);

    Color? bgColor;
    if (isSelected) {
      bgColor = AppTheme.periodColor(context);
    } else if (isPeriod) {
      bgColor = AppTheme.periodLightColor(context);
    }

    Color textColor = Theme.of(context).colorScheme.onSurface;
    if (isSelected) textColor = Colors.white;
    if (isPeriod && !isSelected) {
      textColor = AppTheme.periodColor(context);
    }

    Border? border;
    if (isToday && !isSelected) {
      border = Border.all(color: AppTheme.periodColor(context), width: 1.5);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: (isPeriod || isToday) ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (isPredicted && !isSelected)
            Positioned(
              bottom: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.predictedColor(context),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (hasLog && !isSelected)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.logDotColor(context),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (hasActivity && !isSelected)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.activityColor(context),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final ongoing = _ongoingPeriod;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
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
          const SizedBox(height: 10),
          if (_periods.isEmpty)
            Text(
              'Tap a date to log your first period.',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            )
          else ...[
            if (ongoing != null)
              _summaryRow(Icons.circle, AppTheme.periodColor(context),
                  'Period since ${_formatDate(ongoing.startDate)}')
            else
              _summaryRow(
                Icons.circle_outlined,
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                'No active period',
              ),
            const SizedBox(height: 6),
            _summaryRow(
              Icons.autorenew,
              AppTheme.moodColor(context),
              'Average cycle: ${CyclePredictionService.averageCycleLength(_cycles)} days',
            ),
            if (_nextPredictedPeriod != null) ...[
              const SizedBox(height: 6),
              _summaryRow(
                Icons.event_outlined,
                AppTheme.predictedColor(context),
                'Next: ${_formatDate(_nextPredictedPeriod!)}',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _LogSummaryItem {
  final IconData icon;
  final Color color;
  final String text;
  const _LogSummaryItem(this.icon, this.color, this.text);
}
