import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../services/storage_service.dart';

/// Screen where the user logs symptoms, mood, and sexual activity
/// for a specific date.
///
/// How it works:
///   1. User taps a date on the calendar → "Log symptoms & mood"
///   2. This screen opens, showing chip selectors for each category
///   3. User taps the chips that apply, optionally adds notes
///   4. Taps "Save" → entries saved to Hive → returns to calendar
class LogEntryScreen extends StatefulWidget {
  final DateTime date;

  const LogEntryScreen({super.key, required this.date});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _storage = StorageService();
  final _notesController = TextEditingController();

  // ── Predefined options ──────────────────────────────────────
  // These are the chip labels the user can tap. Each one becomes
  // a LogEntry with the matching LogType.

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

  // Track which chips the user has selected.
  // We use Sets so a chip can only be selected once.
  final Set<String> _selectedSymptoms = {};
  final Set<String> _selectedMoods = {};
  String? _selectedSexualActivity;

  // Existing logs for this date (loaded from Hive on init).
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

  /// Load any previously saved logs for this date and pre-select
  /// their chips, so the user sees what they already logged.
  void _loadExistingLogs() {
    final logs = _storage.getLogsForDate(widget.date);

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

  /// Save all selected chips as LogEntry records.
  ///
  /// Strategy: delete all existing logs for this date, then create
  /// fresh ones from the current selection. This is simpler than
  /// trying to diff what changed.
  Future<void> _save() async {
    // Delete old logs for this date.
    for (final log in _existingLogs) {
      await _storage.deleteLogEntry(log);
    }

    final date = widget.date;
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    // Save each selected symptom.
    for (final symptom in _selectedSymptoms) {
      await _storage.addLogEntry(LogEntry(
        date: date,
        type: LogType.symptom,
        value: symptom,
        notes: notes,
      ));
    }

    // Save each selected mood.
    for (final mood in _selectedMoods) {
      await _storage.addLogEntry(LogEntry(
        date: date,
        type: LogType.mood,
        value: mood,
        notes: notes,
      ));
    }

    // Save sexual activity (only one option allowed).
    if (_selectedSexualActivity != null) {
      await _storage.addLogEntry(LogEntry(
        date: date,
        type: LogType.sexualActivity,
        value: _selectedSexualActivity!,
        notes: notes,
      ));
    }

    // Go back to the calendar. The "true" tells the calendar
    // that data changed and it should refresh.
    if (mounted) Navigator.pop(context, true);
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Log — ${_formatDate(widget.date)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Symptoms section ──
            _buildSectionHeader('Symptoms', Icons.healing, Colors.red.shade300),
            const SizedBox(height: 8),
            _buildChipGroup(
              options: _symptomOptions,
              selected: _selectedSymptoms,
              color: Colors.red.shade100,
              selectedColor: Colors.red.shade300,
              onToggle: (value) {
                setState(() {
                  if (_selectedSymptoms.contains(value)) {
                    _selectedSymptoms.remove(value);
                  } else {
                    _selectedSymptoms.add(value);
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // ── Mood section ──
            _buildSectionHeader('Mood', Icons.emoji_emotions, Colors.amber),
            const SizedBox(height: 8),
            _buildChipGroup(
              options: _moodOptions,
              selected: _selectedMoods,
              color: Colors.amber.shade100,
              selectedColor: Colors.amber.shade400,
              onToggle: (value) {
                setState(() {
                  if (_selectedMoods.contains(value)) {
                    _selectedMoods.remove(value);
                  } else {
                    _selectedMoods.add(value);
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // ── Sexual activity section ──
            _buildSectionHeader(
              'Sexual Activity',
              Icons.favorite,
              Colors.purple.shade300,
            ),
            const SizedBox(height: 8),
            _buildSingleSelectChipGroup(
              options: _sexualActivityOptions,
              selected: _selectedSexualActivity,
              color: Colors.purple.shade100,
              selectedColor: Colors.purple.shade300,
              onSelect: (value) {
                setState(() {
                  // Tap again to deselect.
                  _selectedSexualActivity =
                      _selectedSexualActivity == value ? null : value;
                });
              },
            ),

            const SizedBox(height: 24),

            // ── Notes ──
            _buildSectionHeader('Notes', Icons.note, Colors.grey),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Optional notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Save button ──
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI building blocks ───────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  /// A group of multi-select chips (user can pick many).
  Widget _buildChipGroup({
    required List<String> options,
    required Set<String> selected,
    required Color color,
    required Color selectedColor,
    required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onToggle(option),
          backgroundColor: color,
          selectedColor: selectedColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
          ),
        );
      }).toList(),
    );
  }

  /// A group of single-select chips (user picks only one).
  Widget _buildSingleSelectChipGroup({
    required List<String> options,
    required String? selected,
    required Color color,
    required Color selectedColor,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelect(option),
          backgroundColor: color,
          selectedColor: selectedColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime day) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[day.month]} ${day.day}, ${day.year}';
  }
}
