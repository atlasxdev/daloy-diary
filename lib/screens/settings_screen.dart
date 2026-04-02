import 'package:flutter/material.dart';

import '../main.dart' show themeNotifier;
import '../models/log_entry.dart';
import '../models/notification_settings.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/cycle_prediction_service.dart';

/// Settings tab — HIG "grouped inset" list style.
///
/// HIG guidance applied:
///   - Grouped sections with uppercase gray headers
///   - Inset rounded-rect cards for each group
///   - Switches, disclosure indicators, and detail labels
///   - Destructive actions in red at the bottom
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();
  late NotificationSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = _storage.getNotificationSettings();
  }

  Future<void> _saveAndReschedule() async {
    await _storage.saveNotificationSettings(_settings);

    if (!_settings.notificationsEnabled) {
      await NotificationService.cancelAll();
      return;
    }

    final periods = _storage.getAllPeriods();
    final cycles = _storage.getAllCycles();

    if (periods.isEmpty) {
      await NotificationService.cancelAll();
      return;
    }

    await NotificationService.cancelAll();

    final latestPeriod = periods.first;
    final nextPeriod = CyclePredictionService.predictNextPeriod(
      lastPeriodStart: latestPeriod.startDate,
      cycles: cycles,
    );
    final avgPeriodLen = CyclePredictionService.averagePeriodLength(cycles);

    if (_settings.dailyRemindersEnabled && latestPeriod.isOngoing) {
      await NotificationService.scheduleDailyReminders(
        periodStartDate: latestPeriod.startDate,
        periodLengthDays: avgPeriodLen,
        reminderTime: TimeOfDay(
          hour: _settings.reminderHour,
          minute: _settings.reminderMinute,
        ),
      );
    }

    if (_settings.prePeriodAlertsEnabled) {
      await NotificationService.schedulePrePeriodAlerts(
        nextPeriodDate: nextPeriod,
        daysBefore: _settings.prePeriodAlertDays,
        alertTime: TimeOfDay(
          hour: _settings.alertHour,
          minute: _settings.alertMinute,
        ),
      );
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) {
    return showTimePicker(context: context, initialTime: initial);
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Appearance ──
          _sectionHeader('APPEARANCE'),
          _groupCard([
            _themeRow(),
          ]),

          // ── Notifications master switch ──
          _sectionHeader('NOTIFICATIONS'),
          _groupCard([
            _switchRow(
              label: 'Enable Notifications',
              value: _settings.notificationsEnabled,
              onChanged: (v) {
                setState(() => _settings.notificationsEnabled = v);
                _saveAndReschedule();
              },
            ),
          ]),

          // ── Daily reminders ──
          AnimatedOpacity(
            opacity: _settings.notificationsEnabled ? 1.0 : 0.35,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_settings.notificationsEnabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('DAILY PERIOD REMINDERS'),
                  _groupCard([
                    _switchRow(
                      label: 'Daily Reminders',
                      value: _settings.dailyRemindersEnabled,
                      onChanged: (v) {
                        setState(() => _settings.dailyRemindersEnabled = v);
                        _saveAndReschedule();
                      },
                    ),
                    _divider(),
                    _detailRow(
                      label: 'Reminder Time',
                      detail: _formatTime(
                          _settings.reminderHour, _settings.reminderMinute),
                      enabled: _settings.dailyRemindersEnabled,
                      onTap: () async {
                        final picked = await _pickTime(TimeOfDay(
                          hour: _settings.reminderHour,
                          minute: _settings.reminderMinute,
                        ));
                        if (picked != null) {
                          setState(() {
                            _settings.reminderHour = picked.hour;
                            _settings.reminderMinute = picked.minute;
                          });
                          _saveAndReschedule();
                        }
                      },
                    ),
                  ]),

                  // ── Pre-period alerts ──
                  _sectionHeader('PRE-PERIOD ALERTS'),
                  _groupCard([
                    _switchRow(
                      label: 'Pre-Period Alerts',
                      value: _settings.prePeriodAlertsEnabled,
                      onChanged: (v) {
                        setState(() => _settings.prePeriodAlertsEnabled = v);
                        _saveAndReschedule();
                      },
                    ),
                    _divider(),
                    _detailRow(
                      label: 'Alert Time',
                      detail: _formatTime(
                          _settings.alertHour, _settings.alertMinute),
                      enabled: _settings.prePeriodAlertsEnabled,
                      onTap: () async {
                        final picked = await _pickTime(TimeOfDay(
                          hour: _settings.alertHour,
                          minute: _settings.alertMinute,
                        ));
                        if (picked != null) {
                          setState(() {
                            _settings.alertHour = picked.hour;
                            _settings.alertMinute = picked.minute;
                          });
                          _saveAndReschedule();
                        }
                      },
                    ),
                    _divider(),
                    _stepperRow(
                      label: 'Days Before',
                      value: _settings.prePeriodAlertDays,
                      min: 1,
                      max: 7,
                      enabled: _settings.prePeriodAlertsEnabled,
                      onChanged: (v) {
                        setState(() => _settings.prePeriodAlertDays = v);
                        _saveAndReschedule();
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ),

          // ── Test ──
          _sectionHeader('TEST'),
          _groupCard([
            InkWell(
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                await NotificationService.showTestNotification();
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Test notification sent!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Send Test Notification',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ]),

          // ── Data ──
          _sectionHeader('DATA'),
          _groupCard([
            _destructiveRow(
              label: 'Clear All Data',
              onTap: _showClearDataDialog,
            ),
          ]),

          // ── About ──
          _sectionHeader('ABOUT'),
          _groupCard([
            _detailRow(
              label: 'Version',
              detail: '1.0.0',
              onTap: null,
            ),
          ]),
        ],
      ),
    );
  }

  // ── HIG-style building blocks ────────────────────────────────

  /// Uppercase gray section header (HIG grouped list style).
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.45),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Rounded card that wraps a group of rows.
  Widget _groupCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(children: children),
    );
  }

  /// Thin inset divider between rows.
  Widget _divider() {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 16,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
    );
  }

  /// Row with a switch on the right.
  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Row with a detail label on the right (like iOS disclosure style).
  Widget _detailRow({
    required String label,
    required String detail,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: enabled
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.35),
                ),
              ),
            ),
            Text(
              detail,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.25),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Row with +/- stepper controls.
  Widget _stepperRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required bool enabled,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.35),
              ),
            ),
          ),
          // HIG-style stepper: rounded rect with ─ value +
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stepperButton(
                  icon: Icons.remove,
                  enabled: enabled && value > min,
                  onTap: () => onChanged(value - 1),
                ),
                Container(
                  width: 36,
                  alignment: Alignment.center,
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                _stepperButton(
                  icon: Icons.add,
                  enabled: enabled && value < max,
                  onTap: () => onChanged(value + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.15),
        ),
      ),
    );
  }

  /// HIG-style segmented theme picker (System / Light / Dark).
  Widget _themeRow() {
    final currentMode = _storage.getThemeMode();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'system',
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined, size: 18),
                ),
                ButtonSegment(
                  value: 'light',
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                ),
                ButtonSegment(
                  value: 'dark',
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                ),
              ],
              selected: {currentMode},
              onSelectionChanged: (selected) {
                final mode = selected.first;
                _storage.saveThemeMode(mode);
                switch (mode) {
                  case 'light':
                    themeNotifier.value = ThemeMode.light;
                  case 'dark':
                    themeNotifier.value = ThemeMode.dark;
                  default:
                    themeNotifier.value = ThemeMode.system;
                }
                setState(() {});
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Red destructive row (like "Delete Account" in iOS Settings).
  Widget _destructiveRow({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.red.shade400,
            ),
          ),
        ),
      ),
    );
  }

  // ── Clear data dialog ────────────────────────────────────────

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all periods, cycles, '
          'and log entries. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    final periods = _storage.getAllPeriods();
    for (final p in periods) {
      await _storage.deletePeriod(p);
    }
    final cycles = _storage.getAllCycles();
    for (final c in cycles) {
      await c.delete();
    }
    for (final type in LogType.values) {
      final logs = _storage.getLogsByType(type);
      for (final l in logs) {
        await _storage.deleteLogEntry(l);
      }
    }

    await NotificationService.cancelAll();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All data cleared.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
