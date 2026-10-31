import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/habit_model.dart';
import '../../../domain/providers/habit_providers.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final String? habitId;

  const AddEditHabitScreen({super.key, this.habitId});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Health';
  int _targetCount = 1;
  bool _isFavorite = false;
  int? _reminderHour;
  int? _reminderMinute;
  bool _hasReminder = false;
  bool _isSpecificDays = false;
  List<int> _selectedDays = [];

  bool get _isEditing => widget.habitId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadHabit());
    }
  }

  void _loadHabit() {
    final habit = ref.read(habitRepositoryProvider).getHabitById(widget.habitId!);
    if (habit == null) return;
    _titleController.text = habit.title;
    _notesController.text = habit.notes ?? '';
    setState(() {
      _selectedCategory = habit.category;
      _targetCount = habit.targetCount;
      _isFavorite = habit.isFavorite;
      _reminderHour = habit.reminderHour;
      _reminderMinute = habit.reminderMinute;
      _hasReminder = habit.reminderHour != null;
      _isSpecificDays = habit.repeatDays != null && habit.repeatDays!.isNotEmpty;
      _selectedDays = habit.repeatDays != null ? List<int>.from(habit.repeatDays!) : [];
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

    final notifier = ref.read(habitNotifierProvider.notifier);
    final uuid = const Uuid();

    if (_isEditing) {
      final existing = ref.read(habitRepositoryProvider).getHabitById(widget.habitId!);
      if (existing == null) return;
      final updated = existing.copyWith(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        targetCount: _targetCount,
        isFavorite: _isFavorite,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        reminderHour: _hasReminder ? _reminderHour : null,
        reminderMinute: _hasReminder ? _reminderMinute : null,
        repeatDays: _isSpecificDays ? _selectedDays : [],
      );
      await notifier.updateHabit(updated);
    } else {
      final habit = HabitModel(
        id: uuid.v4(),
        title: _titleController.text.trim(),
        category: _selectedCategory,
        targetCount: _targetCount,
        isFavorite: _isFavorite,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        reminderHour: _hasReminder ? _reminderHour : null,
        reminderMinute: _hasReminder ? _reminderMinute : null,
        repeatDays: _isSpecificDays ? _selectedDays : [],
      );
      await notifier.addHabit(habit);
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
          _isEditing ? 'Edit Habit' : 'New Habit',
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
              // Title field
              _FieldLabel(label: 'Habit Name'),
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
                  hintText: 'e.g. Read for 30 minutes',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Category
              _FieldLabel(label: 'Category'),
              const SizedBox(height: AppDimensions.spaceS),
              _buildCategoryGrid(),
              const SizedBox(height: AppDimensions.spaceL),

              // Target count
              _FieldLabel(label: 'Daily Target'),
              const SizedBox(height: AppDimensions.spaceS),
              _buildTargetCounter(),
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
                  hintText: 'Add a note or motivation...',
                ),
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Options
              _buildOptionsSection(),
              const SizedBox(height: AppDimensions.spaceL),

              // Reminder
              if (_hasReminder) _buildReminderPicker(),

              const SizedBox(height: AppDimensions.spaceXXL),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: hapticMedium(_save),
                  child: Text(
                    _isEditing ? 'Update Habit' : 'Create Habit',
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

  Widget _buildCategoryGrid() {
    return Wrap(
      spacing: AppDimensions.spaceS,
      runSpacing: AppDimensions.spaceS,
      children: AppStrings.categories.map((cat) {
        final selected = _selectedCategory == cat;
        return GestureDetector(
          onTap: hapticSelection(() => setState(() => _selectedCategory = cat)),
          child: AnimatedContainer(
            duration: AppDimensions.animFast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              cat,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.background : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetCounter() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: hapticLight(() {
              if (_targetCount > 1) setState(() => _targetCount--);
            }),
            icon: const Icon(Icons.remove_rounded, color: AppColors.textPrimary),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$_targetCount × per day',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: hapticLight(() => setState(() => _targetCount++)),
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
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
            leading: const Icon(Icons.star_rounded, color: AppColors.textSecondary),
            title: Text(
              'Mark as Favorite',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            trailing: Switch(
              value: _isFavorite,
              onChanged: (v) => setState(() => _isFavorite = v),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.notifications_rounded,
                color: AppColors.textSecondary),
            title: Text(
              'Daily Reminder',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            trailing: Switch(
              value: _hasReminder,
              onChanged: (v) {
                setState(() {
                  _hasReminder = v;
                  if (v && _reminderHour == null) {
                    _reminderHour = 8;
                    _reminderMinute = 0;
                  }
                });
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.calendar_month_rounded,
                color: AppColors.textSecondary),
            title: Text(
              'Specific Days Only',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            trailing: Switch(
              value: _isSpecificDays,
              onChanged: (v) {
                setState(() {
                  _isSpecificDays = v;
                  if (v && _selectedDays.isEmpty) {
                    _selectedDays = [DateTime.now().weekday];
                  }
                });
              },
            ),
          ),
          if (_isSpecificDays) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingCard,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWeekdayButton(1, 'M'),
                  _buildWeekdayButton(2, 'T'),
                  _buildWeekdayButton(3, 'W'),
                  _buildWeekdayButton(4, 'T'),
                  _buildWeekdayButton(5, 'F'),
                  _buildWeekdayButton(6, 'S'),
                  _buildWeekdayButton(7, 'S'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekdayButton(int day, String label) {
    final isSelected = _selectedDays.contains(day);
    return GestureDetector(
      onTap: hapticSelection(() {
        setState(() {
          if (_selectedDays.contains(day)) {
            if (_selectedDays.length > 1) {
              _selectedDays.remove(day);
            }
          } else {
            _selectedDays.add(day);
          }
        });
      }),
      child: AnimatedContainer(
        duration: AppDimensions.animFast,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceVariant,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.background : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: 'Reminder Time'),
        const SizedBox(height: AppDimensions.spaceS),
        GestureDetector(
          onTap: hapticLight(() async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: _reminderHour ?? 8,
                minute: _reminderMinute ?? 0,
              ),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.accent,
                      onPrimary: AppColors.background,
                      surface: AppColors.card,
                      onSurface: AppColors.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (time != null) {
              setState(() {
                _reminderHour = time.hour;
                _reminderMinute = time.minute;
              });
            }
          }),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingCard),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: AppColors.textSecondary, size: 20),
                const SizedBox(width: AppDimensions.spaceM),
                Text(
                  _reminderHour != null
                      ? TimeOfDay(
                              hour: _reminderHour!, minute: _reminderMinute!)
                          .format(context)
                      : 'Tap to set time',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
      ],
    );
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
