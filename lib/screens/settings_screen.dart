import 'package:flutter/material.dart';

import '../main.dart' show themeNotifier;
import '../models/log_entry.dart';
import '../models/notification_settings.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/cycle_prediction_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Appearance ──
          _sectionHeader('Appearance'),
          _groupCard([_themeRow()]),

          // ── Notifications master switch ──
          _sectionHeader('Notifications'),
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
                  _sectionHeader('Daily Period Reminders'),
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
                  _sectionHeader('Pre-Period Alerts'),
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
          _sectionHeader('Test'),
          _groupCard([
            ListTile(
              title: Text('Send Test Notification'),
              trailing: Icon(
                Icons.notifications_active_outlined,
                color: cs.primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                await NotificationService.showTestNotification();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ]),

          // ── Data (destructive) ──
          _sectionHeader('Data'),
          Card(
            color: cs.errorContainer,
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              title: Text(
                'Clear All Data',
                style: TextStyle(color: cs.onErrorContainer),
                textAlign: TextAlign.center,
              ),
              leading: Icon(Icons.delete_outline, color: cs.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: _showClearDataDialog,
            ),
          ),

          // ── About ──
          _sectionHeader('About'),
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

  // ── Building blocks ────────────────────────────────────────

  Widget _sectionHeader(String title) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Text(
        title,
        style: tt.labelLarge?.copyWith(color: cs.primary),
      ),
    );
  }

  Widget _groupCard(List<Widget> children) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.surfaceContainerHigh,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    final cs = Theme.of(context).colorScheme;

    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
      color: cs.outlineVariant,
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final tt = Theme.of(context).textTheme;

    return SwitchListTile.adaptive(
      title: Text(label, style: tt.bodyLarge),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _detailRow({
    required String label,
    required String detail,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListTile(
      title: Text(
        label,
        style: tt.bodyLarge?.copyWith(
          color: enabled ? cs.onSurface : cs.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            detail,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
          ],
        ],
      ),
      onTap: enabled ? onTap : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _stepperRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required bool enabled,
    required ValueChanged<int> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: tt.bodyLarge?.copyWith(
                color: enabled ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
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
                    style: tt.titleMedium?.copyWith(
                      color: cs.primary,
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
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? cs.primary : cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _themeRow() {
    final currentMode = _storage.getThemeMode();
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme', style: tt.bodyLarge),
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

  // ── Clear data dialog ────────────────────────────────────────

  void _showClearDataDialog() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        title: Text('Clear All Data?', style: tt.headlineSmall),
        content: Text(
          'This will permanently delete all periods, cycles, '
          'and log entries. This cannot be undone.',
          style: tt.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: const Text('Delete'),
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
        const SnackBar(
          content: Text('All data cleared.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
