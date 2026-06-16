// lib/screens/tasks/add_task_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../models/task_model.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();
  Priority _priority = Priority.medium;
  DateTime? _dueDate;
  Recurrence _recurrence = Recurrence.none;
  List<String> _tags = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(100.ms); // smooth feedback

    final task = Task(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      tags: _tags,
      recurrence: _recurrence,
    );
    ref.read(tasksProvider.notifier).addTask(task);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDateTime() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: BingoColors.emeraldGreen,
            onPrimary: Colors.white,
            surfaceTint: Colors.transparent,
          ),
          dialogBackgroundColor: BingoColors.cream,
        ),
        child: child!,
      ),
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: BingoColors.emeraldGreen,
            onPrimary: Colors.white,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: BingoColors.cream,
            hourMinuteTextColor: BingoColors.forestGreen,
            dayPeriodTextColor: BingoColors.forestGreen,
            dialHandColor: BingoColors.emeraldGreen,
            dialBackgroundColor: BingoColors.mistGreen,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;

    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time?.hour ?? now.hour, time?.minute ?? now.minute);
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      HapticFeedback.selectionClick();
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    HapticFeedback.lightImpact();
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final canSave = _titleController.text.trim().isNotEmpty && !_isSaving;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? BingoColors.darkCanopy : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? BingoColors.darkFern : BingoColors.pebble,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: BingoColors.emeraldGreen.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.playlist_add_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Text(
                  'New Task',
                  style: BingoTextStyles.headlineLarge.copyWith(
                    color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title field
            _InputField(
              controller: _titleController,
              hint: 'What needs to be done?',
              isDark: isDark,
              style: BingoTextStyles.headlineSmall.copyWith(fontSize: 18),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),

            // Description field
            _InputField(
              controller: _descController,
              hint: 'Add a note (optional)',
              isDark: isDark,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Priority label
            _SectionLabel(text: 'Priority', isDark: isDark),
            const SizedBox(height: 12),
            Row(
              children: Priority.values.map((p) {
                final colors = {
                  Priority.high: BingoColors.priorityHigh,
                  Priority.medium: BingoColors.priorityMed,
                  Priority.low: BingoColors.priorityLow,
                };
                final color = colors[p]!;
                final selected = _priority == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _priority = p);
                    },
                    child: AnimatedContainer(
                      duration: 200.ms,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? color : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? color : color.withOpacity(0.25),
                          width: selected ? 1.2 : 0.8,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]
                            : null,
                      ),
                      child: Text(
                        p.name[0].toUpperCase() + p.name.substring(1),
                        textAlign: TextAlign.center,
                        style: BingoTextStyles.labelLarge.copyWith(
                          color: selected ? Colors.white : color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Recurrence
            _SectionLabel(text: 'Repeat', isDark: isDark),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: Recurrence.values.map((r) {
                  final selected = _recurrence == r;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _recurrence = r);
                    },
                    child: AnimatedContainer(
                      duration: 200.ms,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? BingoColors.emeraldGreen
                            : (isDark ? BingoColors.darkFern : BingoColors.fog),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: selected
                              ? BingoColors.emeraldGreen
                              : (isDark ? BingoColors.mintGreen.withOpacity(0.2) : Colors.transparent),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            r == Recurrence.daily ? Icons.loop_rounded
                                : r == Recurrence.weekly ? Icons.weekend_rounded
                                : r == Recurrence.monthly ? Icons.calendar_month_rounded
                                : Icons.close_rounded,
                            size: 14,
                            color: selected ? Colors.white : (isDark ? BingoColors.mintGreen : BingoColors.bark),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _recurrenceLabel(r),
                            style: BingoTextStyles.labelLarge.copyWith(
                              color: selected ? Colors.white : (isDark ? BingoColors.mintGreen : BingoColors.bark),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Due date picker
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? BingoColors.darkFern : BingoColors.fog,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _dueDate != null
                        ? BingoColors.emeraldGreen.withOpacity(0.4)
                        : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black12 : Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BingoColors.emeraldGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: BingoColors.emeraldGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due date & time',
                            style: BingoTextStyles.labelSmall.copyWith(
                              color: isDark ? BingoColors.mintGreen.withOpacity(0.7) : BingoColors.stone,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dueDate == null
                                ? 'Not set'
                                : DateFormat('EEEE, MMM d • h:mm a').format(_dueDate!),
                            style: BingoTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _dueDate != null
                                  ? (isDark ? BingoColors.paleGreen : BingoColors.forestGreen)
                                  : (isDark ? BingoColors.mintGreen.withOpacity(0.5) : BingoColors.stone),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _dueDate = null);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? BingoColors.darkCanopy : BingoColors.pebble.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark ? BingoColors.mintGreen : BingoColors.stone,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tags section
            _SectionLabel(text: 'Tags', isDark: isDark),
            const SizedBox(height: 10),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) => GestureDetector(
                  onTap: () => _removeTag(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? BingoColors.darkFern : BingoColors.mistGreen,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark ? BingoColors.mintGreen.withOpacity(0.2) : BingoColors.leafGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#$tag',
                          style: BingoTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? BingoColors.mintGreen : BingoColors.leafGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.close_rounded, size: 12, color: isDark ? BingoColors.mintGreen.withOpacity(0.6) : BingoColors.stone),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InputField(
                    controller: _tagController,
                    hint: 'Add a tag...',
                    isDark: isDark,
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _addTag,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: BingoColors.emeraldGreen.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Save button with loading state
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BingoColors.emeraldGreen,
                  disabledBackgroundColor: BingoColors.emeraldGreen.withOpacity(0.5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                  shadowColor: BingoColors.emeraldGreen.withOpacity(0.4),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.grass_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Plant Task',
                            style: BingoTextStyles.headlineSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
  }

  String _recurrenceLabel(Recurrence r) {
    switch (r) {
      case Recurrence.none: return 'None';
      case Recurrence.daily: return 'Daily';
      case Recurrence.weekly: return 'Weekly';
      case Recurrence.monthly: return 'Monthly';
    }
  }
}

// Premium Input Field
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final int maxLines;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.maxLines = 1,
    this.style,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: (style ?? BingoTextStyles.bodyLarge).copyWith(
        color: isDark ? BingoColors.paleGreen : BingoColors.forestGreen,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: (style ?? BingoTextStyles.bodyLarge).copyWith(
          color: isDark ? BingoColors.mintGreen.withOpacity(0.4) : BingoColors.stone.withOpacity(0.6),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: isDark ? BingoColors.darkFern : BingoColors.fog,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: isDark ? BingoColors.darkFern : Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: BingoColors.emeraldGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: BingoTextStyles.labelLarge.copyWith(
        color: isDark ? BingoColors.mintGreen.withOpacity(0.7) : BingoColors.stone,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}