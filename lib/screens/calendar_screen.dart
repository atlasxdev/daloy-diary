import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/theme.dart';
import '../models/period.dart';
import '../models/cycle.dart';
import '../models/log_entry.dart';
import '../models/sexual_activity_log.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/cycle_prediction_service.dart';
import 'log_entry_screen.dart';

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
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        final tt = Theme.of(context).textTheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  _formatDate(day),
                  style: tt.titleLarge,
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
                          FilterChip(
                            label: Text('Period day'),
                            selected: true,
                            selectedColor: AppTheme.periodColor(context)
                                .withValues(alpha: 0.2),
                            side: BorderSide(
                              color: AppTheme.periodColor(context),
                              width: 1.5,
                            ),
                            labelStyle: tt.labelMedium?.copyWith(
                              color: AppTheme.periodColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) {},
                          ),
                        if (_isPredictedDay(day))
                          FilterChip(
                            label: Text('Predicted'),
                            selected: true,
                            selectedColor: AppTheme.predictedColor(context)
                                .withValues(alpha: 0.2),
                            side: BorderSide(
                              color: AppTheme.predictedColor(context),
                              width: 1.5,
                            ),
                            labelStyle: tt.labelMedium?.copyWith(
                              color: AppTheme.predictedColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) {},
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

  Widget _buildLogsSummary(
      List<LogEntry> logs, SexualActivityLog? activityLog) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
        color: cs.surfaceContainerHighest,
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
                      style: tt.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Period start / end logic ─────────────────────────────────

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
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cs = Theme.of(context).colorScheme;
            final tt = Theme.of(context).textTheme;
            final color = AppTheme.activityColor(context);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  32 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      existing != null
                          ? 'Edit Sexual Activity'
                          : 'Log Sexual Activity',
                      style: tt.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(day),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Protection type selector.
                    Text(
                      'Protection',
                      style: tt.titleSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text('Protected'),
                              ],
                            ),
                            selected:
                                selectedType == ProtectionType.protected,
                            selectedColor: color.withValues(alpha: 0.2),
                            side: BorderSide(
                              color: selectedType == ProtectionType.protected
                                  ? color
                                  : cs.outlineVariant,
                              width: selectedType == ProtectionType.protected
                                  ? 1.5
                                  : 1,
                            ),
                            labelStyle: tt.labelLarge?.copyWith(
                              color: selectedType == ProtectionType.protected
                                  ? color
                                  : cs.onSurface,
                            ),
                            showCheckmark: false,
                            onSelected: (_) => setSheetState(() {
                              selectedType = ProtectionType.protected;
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.remove_circle_outline, size: 18),
                                const SizedBox(width: 8),
                                Text('Unprotected'),
                              ],
                            ),
                            selected:
                                selectedType == ProtectionType.unprotected,
                            selectedColor: color.withValues(alpha: 0.2),
                            side: BorderSide(
                              color:
                                  selectedType == ProtectionType.unprotected
                                      ? color
                                      : cs.outlineVariant,
                              width:
                                  selectedType == ProtectionType.unprotected
                                      ? 1.5
                                      : 1,
                            ),
                            labelStyle: tt.labelLarge?.copyWith(
                              color:
                                  selectedType == ProtectionType.unprotected
                                      ? color
                                      : cs.onSurface,
                            ),
                            showCheckmark: false,
                            onSelected: (_) => setSheetState(() {
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
                      style: tt.titleSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Optional notes...',
                        hintStyle: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button.
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: selectedType == null
                            ? null
                            : () async {
                                final nav = Navigator.of(context);
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
                                  nav.pop();
                                  setState(() {});
                                }
                              },
                        child: Text(existing != null ? 'Update' : 'Save'),
                      ),
                    ),

                    // Delete button (only when editing).
                    if (existing != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await _storage.deleteSexualActivityLog(existing);
                          if (mounted) {
                            nav.pop();
                            setState(() {});
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: cs.error,
                        ),
                        child: const Text('Delete'),
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

  Future<void> _openLogEntryScreen(DateTime day) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => LogEntryScreen(date: day)),
    );
    if (result == true) setState(() {});
  }

  String _formatDate(DateTime day) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[day.month]} ${day.day}, ${day.year}';
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TableCalendar(
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
                      color: cs.primary,
                      width: 2,
                    ),
                  ),
                  todayTextStyle: tt.titleSmall!.copyWith(
                    color: cs.primary,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: tt.titleSmall!.copyWith(
                    color: cs.onPrimary,
                  ),
                  defaultTextStyle: tt.bodyMedium!.copyWith(
                    color: cs.onSurface,
                  ),
                  weekendTextStyle: tt.bodyMedium!.copyWith(
                    color: cs.onSurface,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: tt.titleMedium!.copyWith(
                    color: cs.onSurface,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: cs.onSurfaceVariant,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: tt.labelMedium!.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  weekendStyle: tt.labelMedium!.copyWith(
                    color: cs.onSurfaceVariant,
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
            ),
          ),
          Divider(
            indent: 16,
            endIndent: 16,
            color: cs.outlineVariant,
          ),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isPeriod = _isPeriodDay(day);
    final isPredicted = _isPredictedDay(day);
    final hasLog = _hasLogs(day);
    final hasActivity = _hasSexualActivity(day);

    Color? bgColor;
    if (isSelected) {
      bgColor = cs.primary;
    } else if (isPeriod) {
      bgColor = AppTheme.periodLightColor(context);
    }

    Color textColor = cs.onSurface;
    if (isSelected) {
      textColor = cs.onPrimary;
    } else if (isPeriod) {
      textColor = AppTheme.periodColor(context);
    } else if (isToday) {
      textColor = cs.primary;
    }

    Border? border;
    if (isToday && !isSelected) {
      border = Border.all(color: cs.primary, width: 2);
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
            style: tt.titleSmall?.copyWith(
              color: textColor,
              fontWeight:
                  (isPeriod || isToday) ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          // Predicted: bottom-center.
          if (isPredicted && !isSelected)
            Positioned(
              bottom: 4,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.predictedColor(context),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          // Has logs: bottom-right.
          if (hasLog && !isSelected)
            Positioned(
              bottom: 4,
              right: 6,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.logDotColor(context),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          // Has activity: bottom-left.
          if (hasActivity && !isSelected)
            Positioned(
              bottom: 4,
              left: 6,
              child: Container(
                width: 4,
                height: 4,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ongoing = _ongoingPeriod;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          if (_periods.isEmpty)
            Text(
              'Tap a date to log your first period.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            )
          else ...[
            if (ongoing != null)
              _summaryRow(Icons.circle, AppTheme.periodColor(context),
                  'Period since ${_formatDate(ongoing.startDate)}')
            else
              _summaryRow(
                Icons.circle_outlined,
                cs.onSurfaceVariant,
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
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
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
