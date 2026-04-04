import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/log_entry.dart';
import '../services/storage_service.dart';

class LogEntryScreen extends StatefulWidget {
  final DateTime date;

  const LogEntryScreen({super.key, required this.date});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _storage = StorageService();
  final _notesController = TextEditingController();

  static const _symptomOptions = [
    'Cramps', 'Headache', 'Bloating', 'Fatigue',
    'Back pain', 'Acne', 'Nausea', 'Breast tenderness',
  ];

  static const _moodOptions = [
    'Happy', 'Calm', 'Sad', 'Anxious',
    'Irritable', 'Energetic', 'Tired', 'Emotional',
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

  void _loadExistingLogs() {
    final logs = _storage.getLogsForDate(widget.date);
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

    final date = widget.date;
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    for (final symptom in _selectedSymptoms) {
      await _storage.addLogEntry(LogEntry(
        date: date, type: LogType.symptom, value: symptom, notes: notes,
      ));
    }

    for (final mood in _selectedMoods) {
      await _storage.addLogEntry(LogEntry(
        date: date, type: LogType.mood, value: mood, notes: notes,
      ));
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Log — ${_formatDate(widget.date)}'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Symptoms section ──
            Card(
              color: cs.surfaceContainerHigh,
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Symptoms',
                      Icons.healing,
                      AppTheme.periodColor(context),
                    ),
                    const SizedBox(height: 10),
                    _buildChipGroup(
                      options: _symptomOptions,
                      selected: _selectedSymptoms,
                      color: AppTheme.periodColor(context),
                      onToggle: (value) => setState(() {
                        _selectedSymptoms.contains(value)
                            ? _selectedSymptoms.remove(value)
                            : _selectedSymptoms.add(value);
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Mood section ──
            Card(
              color: cs.surfaceContainerHigh,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Mood',
                      Icons.emoji_emotions_outlined,
                      AppTheme.moodColor(context),
                    ),
                    const SizedBox(height: 10),
                    _buildChipGroup(
                      options: _moodOptions,
                      selected: _selectedMoods,
                      color: AppTheme.moodColor(context),
                      onToggle: (value) => setState(() {
                        _selectedMoods.contains(value)
                            ? _selectedMoods.remove(value)
                            : _selectedMoods.add(value);
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Notes ──
            Card(
              color: cs.surfaceContainerHigh,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Notes',
                      Icons.note_outlined,
                      cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Save button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildChipGroup({
    required List<String> options,
    required Set<String> selected,
    required Color color,
    required ValueChanged<String> onToggle,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          selectedColor: color.withValues(alpha: 0.2),
          backgroundColor: cs.surfaceContainerHighest,
          side: BorderSide(
            color: isSelected ? color : cs.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          labelStyle: tt.labelLarge?.copyWith(
            color: isSelected ? color : cs.onSurface,
          ),
          showCheckmark: false,
          onSelected: (_) => onToggle(option),
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
