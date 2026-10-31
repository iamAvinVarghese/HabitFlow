import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/task_model.dart';
import '../../../domain/providers/task_providers.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final String? taskId;

  const AddEditTaskScreen({super.key, this.taskId});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  bool _isPinned = false;
  DateTime? _reminderTime;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTask());
    }
  }

  void _loadTask() {
    final task = ref.read(taskRepositoryProvider).getTaskById(widget.taskId!);
    if (task == null) return;
    _titleController.text = task.title;
    _notesController.text = task.notes ?? '';
    setState(() {
      _priority = task.priority;
      _isPinned = task.isPinned;
      _reminderTime = task.reminderTime;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(taskNotifierProvider.notifier);
    final uuid = const Uuid();

    if (_isEditing) {
      final existing =
          ref.read(taskRepositoryProvider).getTaskById(widget.taskId!);
      if (existing == null) return;
      final updated = existing.copyWith(
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        priority: _priority,
        isPinned: _isPinned,
        reminderTime: _reminderTime,
      );
      await notifier.updateTask(updated);
    } else {
      final task = TaskModel(
        id: uuid.v4(),
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        priority: _priority,
        isPinned: _isPinned,
        reminderTime: _reminderTime,
      );
      await notifier.addTask(task);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: hapticLight(() => Navigator.pop(context)),
        ),
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: hapticMedium(_save),
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingPage),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _FieldLabel(label: 'Task Title'),
              const SizedBox(height: AppDimensions.spaceS),
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'What do you need to do?',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Priority
              _FieldLabel(label: 'Priority'),
              const SizedBox(height: AppDimensions.spaceS),
              _buildPrioritySelector(),
              const SizedBox(height: AppDimensions.spaceL),

              // Notes
              _FieldLabel(label: 'Notes (optional)'),
              const SizedBox(height: AppDimensions.spaceS),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Add more details...',
                ),
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Options
              _buildOptionsSection(),
              const SizedBox(height: AppDimensions.spaceXXL),

              // Save
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hapticMedium(_save),
                  child: Text(
                    _isEditing ? 'Update Task' : 'Add Task',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: TaskPriority.values.map((p) {
        final selected = _priority == p;
        final label = p.name[0].toUpperCase() + p.name.substring(1);
        final color = p == TaskPriority.high
            ? AppColors.priorityHigh
            : p == TaskPriority.medium
                ? AppColors.priorityMedium
                : AppColors.priorityLow;

        return Expanded(
          child: GestureDetector(
            onTap: hapticSelection(() => setState(() => _priority = p)),
            child: AnimatedContainer(
              duration: AppDimensions.animFast,
              margin: const EdgeInsets.only(right: AppDimensions.spaceS),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.surfaceVariant,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.background : color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.background
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.push_pin_rounded,
                color: AppColors.textSecondary),
            title: Text(
              'Pin Task',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            trailing: Switch(
              value: _isPinned,
              onChanged: (v) => setState(() => _isPinned = v),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.alarm_rounded,
                color: AppColors.textSecondary),
            title: Text(
              'Reminder',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            subtitle: _reminderTime != null
                ? Text(
                    DateFormat('MMM d, hh:mm a').format(_reminderTime!),
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textTertiary),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_reminderTime != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textTertiary),
                    onPressed: hapticLight(() => setState(() => _reminderTime = null)),
                  ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary),
              ],
            ),
            onTap: hapticLight(_pickReminder),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: AppColors.background,
            surface: AppColors.card,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: AppColors.background,
            surface: AppColors.card,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );

    if (time == null) return;

    setState(() {
      _reminderTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }
}
