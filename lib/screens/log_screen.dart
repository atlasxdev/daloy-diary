import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/log_entry.dart';
import '../models/sexual_activity_log.dart';
import '../services/storage_service.dart';

/// The "Log" tab — a quick-entry screen for today's date.
///
/// Unlike LogEntryScreen (which opens for any date from the calendar),
/// this tab is always for TODAY. It's designed for rapid input:
/// tap chips, hit save, done.
///
/// HIG guidance applied:
///   - Grouped sections with clear labels
///   - Rounded chip selectors (not checkboxes)
///   - Large tap targets
///   - Success feedback via snackbar
class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _storage = StorageService();
  final _notesController = TextEditingController();

  static const _symptomOptions = [
    'Cramps',
    'Headache',
    'Bloating',
    'Fatigue',
    'Back pain',
    'Acne',
    'Nausea',
    'Breast tenderness',
  ];

  static const _moodOptions = [
    'Happy',
    'Calm',
    'Sad',
    'Anxious',
    'Irritable',
    'Energetic',
    'Tired',
    'Emotional',
  ];

  final Set<String> _selectedSymptoms = {};
  final Set<String> _selectedMoods = {};

  List<LogEntry> _existingLogs = [];

  @override
  void initState() {
    super.initState();
    _loadExistingLogs();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _loadExistingLogs() {
    final logs = _storage.getLogsForDate(_today);
    final symptoms = <String>{};
    final moods = <String>{};

    for (final log in logs) {
      switch (log.type) {
        case LogType.symptom:
          symptoms.add(log.value);
        case LogType.mood:
          moods.add(log.value);
        case LogType.sexualActivity:
          break;
      }
    }

    setState(() {
      _existingLogs = logs;
      _selectedSymptoms.addAll(symptoms);
      _selectedMoods.addAll(moods);
    });
  }

  Future<void> _save() async {
    for (final log in _existingLogs) {
      await _storage.deleteLogEntry(log);
    }

    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    for (final symptom in _selectedSymptoms) {
      await _storage.addLogEntry(LogEntry(
        date: _today,
        type: LogType.symptom,
        value: symptom,
        notes: notes,
      ));
    }
    for (final mood in _selectedMoods) {
      await _storage.addLogEntry(LogEntry(
        date: _today,
        type: LogType.mood,
        value: mood,
        notes: notes,
      ));
    }
    // Reload to reflect saved state.
    _existingLogs = _storage.getLogsForDate(_today);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Log')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date indicator.
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Today — ${_formatDate(_today)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Symptoms.
            _sectionLabel('Symptoms', Icons.healing, AppTheme.periodColor(context)),
            const SizedBox(height: 10),
            _chipGroup(
              options: _symptomOptions,
              selected: _selectedSymptoms,
              baseColor: AppTheme.periodColor(context),
              onToggle: (v) => setState(() {
                _selectedSymptoms.contains(v)
                    ? _selectedSymptoms.remove(v)
                    : _selectedSymptoms.add(v);
              }),
            ),

            const SizedBox(height: 28),

            // Mood.
            _sectionLabel('Mood', Icons.emoji_emotions_outlined, AppTheme.moodColor(context)),
            const SizedBox(height: 10),
            _chipGroup(
              options: _moodOptions,
              selected: _selectedMoods,
              baseColor: AppTheme.moodColor(context),
              onToggle: (v) => setState(() {
                _selectedMoods.contains(v)
                    ? _selectedMoods.remove(v)
                    : _selectedMoods.add(v);
              }),
            ),

            const SizedBox(height: 28),

            // Sexual activity.
            _buildSexualActivitySection(),

            const SizedBox(height: 28),

            // Notes.
            _sectionLabel('Notes', Icons.note_outlined, cs.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Optional notes...',
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
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
                  borderSide: BorderSide(color: cs.primary),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save button.
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sexual activity section ─────────────────────────────────

  Widget _buildSexualActivitySection() {
    final activity = _storage.getSexualActivityForDate(_today);
    final color = AppTheme.activityColor(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Sexual Activity', Icons.favorite_outline, color),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _showSexualActivitySheet(existing: activity),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: activity != null
                  ? color.withValues(alpha: 0.1)
                  : cs.outline.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activity != null
                    ? color.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  activity != null
                      ? Icons.favorite
                      : Icons.add_circle_outline,
                  size: 18,
                  color: activity != null
                      ? color
                      : cs.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activity != null
                        ? (activity.protectionType ==
                                ProtectionType.protected
                            ? 'Protected'
                            : 'Unprotected')
                        : 'Tap to log sexual activity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          activity != null ? FontWeight.w600 : FontWeight.w400,
                      color: activity != null
                          ? color
                          : cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (activity?.notes != null && activity!.notes!.isNotEmpty)
                  Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: cs.onSurface.withValues(alpha: 0.3),
                  ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSexualActivitySheet({SexualActivityLog? existing}) {
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
                                    date: _today,
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

  // ── UI building blocks ───────────────────────────────────────

  Widget _sectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _chipGroup({
    required List<String> options,
    required Set<String> selected,
    required Color baseColor,
    required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onToggle(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? baseColor.withValues(alpha: 0.2)
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected ? baseColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? baseColor
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime day) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[day.month]} ${day.day}, ${day.year}';
  }
}
