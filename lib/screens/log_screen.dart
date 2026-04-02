import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/log_entry.dart';
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

  static const _sexualActivityOptions = [
    'Protected',
    'Unprotected',
    'No activity',
  ];

  final Set<String> _selectedSymptoms = {};
  final Set<String> _selectedMoods = {};
  String? _selectedSexualActivity;

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
    String? sexActivity;

    for (final log in logs) {
      switch (log.type) {
        case LogType.symptom:
          symptoms.add(log.value);
        case LogType.mood:
          moods.add(log.value);
        case LogType.sexualActivity:
          sexActivity = log.value;
      }
    }

    setState(() {
      _existingLogs = logs;
      _selectedSymptoms.addAll(symptoms);
      _selectedMoods.addAll(moods);
      _selectedSexualActivity = sexActivity;
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
    if (_selectedSexualActivity != null) {
      await _storage.addLogEntry(LogEntry(
        date: _today,
        type: LogType.sexualActivity,
        value: _selectedSexualActivity!,
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
            _sectionLabel('Sexual Activity', Icons.favorite_outline,
                AppTheme.moodColor(context)),
            const SizedBox(height: 10),
            _singleChipGroup(
              options: _sexualActivityOptions,
              selected: _selectedSexualActivity,
              baseColor: AppTheme.moodColor(context),
              onSelect: (v) => setState(() {
                _selectedSexualActivity =
                    _selectedSexualActivity == v ? null : v;
              }),
            ),

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

  Widget _singleChipGroup({
    required List<String> options,
    required String? selected,
    required Color baseColor,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelect(option),
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
