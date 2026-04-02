import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/gradient_header.dart';
import '../models/log_entry.dart';
import '../models/sexual_activity_log.dart';
import '../services/storage_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _storage = StorageService();
  final _notesController = TextEditingController();

  // Current active category (controls which chip group is visible).
  int _activeCategory = 0;

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
        date: _today, type: LogType.symptom, value: symptom, notes: notes,
      ));
    }
    for (final mood in _selectedMoods) {
      await _storage.addLogEntry(LogEntry(
        date: _today, type: LogType.mood, value: mood, notes: notes,
      ));
    }
    _existingLogs = _storage.getLogsForDate(_today);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GradientScaffold(
      title: 'Tracking',
      gradientHeight: 180,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category icon row ──
            _buildCategoryRow(),
            const SizedBox(height: 20),

            // ── Active category content ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildCategoryContent(),
            ),

            const SizedBox(height: 24),

            // ── Notes ──
            _sectionLabel('Notes', Icons.note_outlined,
                cs.onSurface.withValues(alpha: 0.4)),
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
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Save button ──
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

  // ── Category icon row (reference: circular icons at top) ────

  Widget _buildCategoryRow() {
    final categories = [
      _CategoryDef(Icons.healing, 'Symptoms', AppTheme.periodColor(context)),
      _CategoryDef(Icons.emoji_emotions_outlined, 'Mood', AppTheme.moodColor(context)),
      _CategoryDef(Icons.favorite_outline, 'Intimacy', AppTheme.activityColor(context)),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < categories.length; i++)
          _buildCategoryIcon(categories[i], i),
      ],
    );
  }

  Widget _buildCategoryIcon(_CategoryDef cat, int index) {
    final isActive = _activeCategory == index;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = index),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cat.color.withValues(alpha: 0.85),
                        cat.color.withValues(alpha: 0.5),
                      ],
                    )
                  : null,
              color: isActive
                  ? null
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              cat.icon,
              size: 24,
              color: isActive
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cat.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? cat.color
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category content switcher ────────────────────────────────

  Widget _buildCategoryContent() {
    switch (_activeCategory) {
      case 0:
        return _buildChipSection(
          key: const ValueKey('symptoms'),
          label: 'Symptoms',
          icon: Icons.healing,
          color: AppTheme.periodColor(context),
          options: _symptomOptions,
          selected: _selectedSymptoms,
          onToggle: (v) => setState(() {
            _selectedSymptoms.contains(v)
                ? _selectedSymptoms.remove(v)
                : _selectedSymptoms.add(v);
          }),
        );
      case 1:
        return _buildChipSection(
          key: const ValueKey('mood'),
          label: 'Mood',
          icon: Icons.emoji_emotions_outlined,
          color: AppTheme.moodColor(context),
          options: _moodOptions,
          selected: _selectedMoods,
          onToggle: (v) => setState(() {
            _selectedMoods.contains(v)
                ? _selectedMoods.remove(v)
                : _selectedMoods.add(v);
          }),
        );
      case 2:
        return _buildSexualActivitySection(key: const ValueKey('activity'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChipSection({
    required Key key,
    required String label,
    required IconData icon,
    required Color color,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label, icon, color),
        const SizedBox(height: 10),
        _chipGroup(options: options, selected: selected, baseColor: color, onToggle: onToggle),
      ],
    );
  }

  // ── Sexual activity section ─────────────────────────────────

  Widget _buildSexualActivitySection({required Key key}) {
    final activity = _storage.getSexualActivityForDate(_today);
    final color = AppTheme.activityColor(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      key: key,
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
                  activity != null ? Icons.favorite : Icons.add_circle_outline,
                  size: 18,
                  color: activity != null
                      ? color
                      : cs.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activity != null
                        ? (activity.protectionType == ProtectionType.protected
                            ? 'Protected'
                            : 'Unprotected')
                        : 'Tap to log sexual activity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: activity != null ? FontWeight.w600 : FontWeight.w400,
                      color: activity != null
                          ? color
                          : cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (activity?.notes != null && activity!.notes!.isNotEmpty)
                  Icon(Icons.note_outlined, size: 16,
                      color: cs.onSurface.withValues(alpha: 0.3)),
                Icon(Icons.chevron_right, size: 18,
                    color: cs.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSexualActivitySheet({SexualActivityLog? existing}) {
    var selectedType = existing?.protectionType;
    final notesController = TextEditingController(text: existing?.notes ?? '');

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
                    24, 4, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing != null ? 'Edit Sexual Activity' : 'Log Sexual Activity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600, letterSpacing: -0.3),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text('Protection',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: cs.onSurface, letterSpacing: -0.2)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _protectionChip(
                            label: 'Protected', icon: Icons.shield_outlined,
                            isSelected: selectedType == ProtectionType.protected,
                            color: color,
                            onTap: () => setSheetState(
                                () => selectedType = ProtectionType.protected),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _protectionChip(
                            label: 'Unprotected', icon: Icons.remove_circle_outline,
                            isSelected: selectedType == ProtectionType.unprotected,
                            color: color,
                            onTap: () => setSheetState(
                                () => selectedType = ProtectionType.unprotected),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Notes',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: cs.onSurface, letterSpacing: -0.2)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController, maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Optional notes...',
                        hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
                        filled: true, fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: color),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: selectedType == null
                          ? null
                          : () async {
                              final notes = notesController.text.trim().isNotEmpty
                                  ? notesController.text.trim() : null;
                              if (existing != null) {
                                existing.protectionType = selectedType!;
                                existing.notes = notes;
                                await _storage.updateSexualActivityLog(existing);
                              } else {
                                await _storage.addSexualActivityLog(SexualActivityLog(
                                  date: _today, protectionType: selectedType!, notes: notes,
                                ));
                              }
                              if (mounted) { Navigator.pop(context); setState(() {}); }
                            },
                      style: FilledButton.styleFrom(backgroundColor: color),
                      child: Text(existing != null ? 'Update' : 'Save'),
                    ),
                    if (existing != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          await _storage.deleteSexualActivityLog(existing);
                          if (mounted) { Navigator.pop(context); setState(() {}); }
                        },
                        child: Text('Delete',
                            style: TextStyle(color: cs.error, fontWeight: FontWeight.w500)),
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
    required String label, required IconData icon,
    required bool isSelected, required Color color, required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15)
              : cs.outline.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18,
                color: isSelected ? color : cs.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : cs.onSurface)),
          ],
        ),
      ),
    );
  }

  // ── Shared UI building blocks ────────────────────────────────

  Widget _sectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.2)),
      ],
    );
  }

  Widget _chipGroup({
    required List<String> options, required Set<String> selected,
    required Color baseColor, required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 8, runSpacing: 8,
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
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? baseColor : Colors.transparent, width: 1.5),
            ),
            child: Text(option, style: TextStyle(fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? baseColor
                    : Theme.of(context).colorScheme.onSurface)),
          ),
        );
      }).toList(),
    );
  }

}

class _CategoryDef {
  final IconData icon;
  final String label;
  final Color color;
  const _CategoryDef(this.icon, this.label, this.color);
}
