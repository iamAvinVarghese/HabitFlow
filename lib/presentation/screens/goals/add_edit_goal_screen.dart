import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/goal_model.dart';
import '../../../domain/providers/goal_providers.dart';
import '../../../domain/providers/habit_providers.dart';

class AddEditGoalScreen extends ConsumerStatefulWidget {
  const AddEditGoalScreen({super.key});

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetValueController = TextEditingController(text: '5');

  GoalType _selectedType = GoalType.daily;
  String? _associatedHabitId;
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _titleController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final targetVal = int.tryParse(_targetValueController.text.trim()) ?? 1;

    final newGoal = GoalModel(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      type: _selectedType,
      targetValue: targetVal,
      associatedHabitId: _associatedHabitId,
      deadline: _deadline,
    );

    await ref.read(goalNotifierProvider.notifier).addGoal(newGoal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(activeHabitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'New Goal',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: hapticMedium(_save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingPage),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text('Goal Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                const SizedBox(height: AppDimensions.spaceS),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Complete 20 study sessions',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                // Goal Type
                const Text('Goal Period', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                const SizedBox(height: AppDimensions.spaceS),
                Row(
                  children: GoalType.values.map((type) {
                    final isSelected = _selectedType == type;
                    final label = type.name[0].toUpperCase() + type.name.substring(1);
                    return Expanded(
                      child: GestureDetector(
                        onTap: hapticSelection(() {
                          setState(() {
                            _selectedType = type;
                            // Pre-fill deadline estimate
                            if (type == GoalType.daily) {
                              _deadline = DateTime.now().add(const Duration(days: 1));
                            } else if (type == GoalType.weekly) {
                              _deadline = DateTime.now().add(const Duration(days: 7));
                            } else {
                              _deadline = DateTime.now().add(const Duration(days: 30));
                            }
                          });
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.textPrimary : AppColors.card,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.background : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                // Target Value
                const Text('Target Completion Count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                const SizedBox(height: AppDimensions.spaceS),
                TextFormField(
                  controller: _targetValueController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 10',
                  ),
                  validator: (v) => v == null || int.tryParse(v) == null ? 'Valid target number is required' : null,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                // Link habit
                const Text('Link Habit (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                const SizedBox(height: AppDimensions.spaceS),
                DropdownButtonFormField<String>(
                  value: _associatedHabitId,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('None')),
                    ...habits.map((h) => DropdownMenuItem<String>(value: h.id, child: Text(h.title))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _associatedHabitId = val;
                    });
                  },
                ),
                const SizedBox(height: AppDimensions.spaceM),
                // Deadline Date Picker
                const Text('Goal Deadline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                const SizedBox(height: AppDimensions.spaceS),
                GestureDetector(
                  onTap: hapticLight(() async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _deadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _deadline = DateTime(date.year, date.month, date.day, 23, 59, 59);
                      });
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy-MM-dd').format(_deadline),
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hapticMedium(_save),
                    child: const Text('Add Goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
