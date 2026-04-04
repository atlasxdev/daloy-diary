import 'package:flutter/material.dart';

import '../core/theme.dart';
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
        const SnackBar(
          content: Text('Saved'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 112,
            pinned: true,
            centerTitle: false,
            scrolledUnderElevation: 3,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Tracking',
                style: tt.titleLarge?.copyWith(color: cs.onSurface),
              ),
              titlePadding:
                  const EdgeInsetsDirectional.only(start: 16, bottom: 16),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.list(
              children: [
                // ── Category selector ──
                _buildCategoryRow(),
                const SizedBox(height: 20),

                // ── Active category content (in card) ──
                Card(
                  color: cs.surfaceContainerHigh,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _buildCategoryContent(),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Notes (in card) ──
                Card(
                  color: cs.surfaceContainerHigh,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Notes', Icons.note_outlined,
                            cs.onSurfaceVariant),
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
                              borderSide:
                                  BorderSide(color: cs.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: cs.outlineVariant),
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
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Category selector (FilledButton.tonal row) ────────────────

  Widget _buildCategoryRow() {
    final categories = [
      _CategoryDef(Icons.healing, 'Symptoms', AppTheme.periodColor(context)),
      _CategoryDef(
          Icons.emoji_emotions_outlined, 'Mood', AppTheme.moodColor(context)),
      _CategoryDef(
          Icons.favorite_outline, 'Intimacy', AppTheme.activityColor(context)),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int i = 0; i < categories.length; i++)
          _buildCategoryButton(categories[i], i),
      ],
    );
  }

  Widget _buildCategoryButton(_CategoryDef cat, int index) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isActive = _activeCategory == index;

    return FilledButton.tonal(
      onPressed: () => setState(() => _activeCategory = index),
      style: FilledButton.styleFrom(
        backgroundColor:
            isActive ? cat.color.withValues(alpha: 0.15) : cs.surfaceContainerHighest,
        foregroundColor: isActive ? cat.color : cs.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isActive
              ? BorderSide(color: cat.color, width: 1.5)
              : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cat.icon, size: 18),
          const SizedBox(width: 8),
          Text(
            cat.label,
            style: tt.labelLarge?.copyWith(
              color: isActive ? cat.color : cs.onSurfaceVariant,
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
        _chipGroup(
            options: options,
            selected: selected,
            baseColor: color,
            onToggle: onToggle),
      ],
    );
  }

  // ── Sexual activity section ─────────────────────────────────

  Widget _buildSexualActivitySection({required Key key}) {
    final activity = _storage.getSexualActivityForDate(_today);
    final color = AppTheme.activityColor(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activity != null ? color : cs.outlineVariant,
                width: activity != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  activity != null
                      ? Icons.favorite
                      : Icons.add_circle_outline,
                  size: 18,
                  color: activity != null ? color : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activity != null
                        ? (activity.protectionType == ProtectionType.protected
                            ? 'Protected'
                            : 'Unprotected')
                        : 'Tap to log sexual activity',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight:
                          activity != null ? FontWeight.w600 : FontWeight.w400,
                      color: activity != null ? color : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                if (activity?.notes != null && activity!.notes!.isNotEmpty)
                  Icon(Icons.note_outlined,
                      size: 16, color: cs.onSurfaceVariant),
                Icon(Icons.chevron_right,
                    size: 18, color: cs.onSurfaceVariant),
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
                    32 + MediaQuery.of(context).viewInsets.bottom),
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
                    const SizedBox(height: 20),
                    Text(
                      'Protection',
                      style: tt.titleSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
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
                              color:
                                  selectedType == ProtectionType.protected
                                      ? color
                                      : cs.outlineVariant,
                              width:
                                  selectedType == ProtectionType.protected
                                      ? 1.5
                                      : 1,
                            ),
                            labelStyle: tt.labelLarge?.copyWith(
                              color:
                                  selectedType == ProtectionType.protected
                                      ? color
                                      : cs.onSurface,
                            ),
                            showCheckmark: false,
                            onSelected: (_) => setSheetState(
                                () => selectedType = ProtectionType.protected),
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
                            onSelected: (_) => setSheetState(() =>
                                selectedType = ProtectionType.unprotected),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Notes',
                      style: tt.titleSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
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
                                      date: _today,
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

  // ── Shared UI building blocks ────────────────────────────────

  Widget _sectionLabel(String title, IconData icon, Color color) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
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
          selectedColor: baseColor.withValues(alpha: 0.2),
          backgroundColor: cs.surfaceContainerHighest,
          side: BorderSide(
            color: isSelected ? baseColor : cs.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          labelStyle: tt.labelLarge?.copyWith(
            color: isSelected ? baseColor : cs.onSurface,
          ),
          showCheckmark: false,
          onSelected: (_) => onToggle(option),
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
