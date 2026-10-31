import 'dart:async';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:habitflow/core/utils/notification_service.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/pomodoro_model.dart';
import '../../../domain/providers/pomodoro_providers.dart';
import '../../../domain/providers/habit_providers.dart';
import '../../../domain/providers/task_providers.dart';
import '../../widgets/circular_progress_ring.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  // Timer settings
  int _workMinutes = 25;
  int _breakMinutes = 5;
  bool _isBreak = false;

  // Running state
  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;

  // Associated IDs
  String? _associatedHabitId;
  String? _associatedTaskId;
  final _notesController = TextEditingController();

  int get _totalDurationSeconds => (_isBreak ? _breakMinutes : _workMinutes) * 60;

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isRunning = true;
    });

    NotificationService.schedulePomodoroReminder(
      seconds: _secondsRemaining,
      isBreak: _isBreak,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timerCompleted();
      }
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;
    HapticFeedback.lightImpact();
    _timer?.cancel();
    NotificationService.cancelPomodoroReminder();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    NotificationService.cancelPomodoroReminder();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _totalDurationSeconds;
    });
  }

  void _timerCompleted() async {
    _timer?.cancel();
    HapticFeedback.vibrate();
    NotificationService.cancelPomodoroReminder();

    if (!_isBreak) {
      // Save session
      final newSession = PomodoroSession(
        id: const Uuid().v4(),
        startTime: DateTime.now().subtract(Duration(minutes: _workMinutes)),
        endTime: DateTime.now(),
        durationMinutes: _workMinutes,
        isCompleted: true,
        associatedHabitId: _associatedHabitId,
        associatedTaskId: _associatedTaskId,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      await ref.read(pomodoroNotifierProvider.notifier).saveSession(newSession);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Great job staying focused! Session saved.'),
          ),
        );
      }
    }

    setState(() {
      _isBreak = !_isBreak;
      _secondsRemaining = _totalDurationSeconds;
      _isRunning = false;
    });
  }

  void _changeDurationPreset(int work, int brk) {
    _timer?.cancel();
    setState(() {
      _workMinutes = work;
      _breakMinutes = brk;
      _isBreak = false;
      _isRunning = false;
      _secondsRemaining = work * 60;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(activeHabitsProvider);
    final tasks = ref.watch(activeTasksProvider);

    final progress = _secondsRemaining / _totalDurationSeconds;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pomodoro Focus',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.spaceL),
              // Preset Selectors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PresetButton(
                    label: '25 / 5',
                    isSelected: _workMinutes == 25 && _breakMinutes == 5,
                    onTap: hapticMedium(() => _changeDurationPreset(25, 5)),
                  ),
                  _PresetButton(
                    label: '50 / 10',
                    isSelected: _workMinutes == 50 && _breakMinutes == 10,
                    onTap: hapticMedium(() => _changeDurationPreset(50, 10)),
                  ),
                  _PresetButton(
                    label: 'Custom',
                    isSelected: _workMinutes != 25 && _workMinutes != 50,
                    onTap: hapticMedium(_showCustomPresetDialog),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceXXL),

              // Progress circle
              Center(
                child: CircularProgressRing(
                  progress: progress,
                  size: 240,
                  strokeWidth: 12,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isBreak ? 'Break Time' : 'Focus Mode',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(_secondsRemaining),
                        style: GoogleFonts.shareTechMono(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXXL),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: hapticMedium(_resetTimer),
                    icon: const Icon(Icons.replay_rounded, size: 28),
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.spaceXL),
                  GestureDetector(
                    onTap: hapticLight(_isRunning ? _pauseTimer : _startTimer),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: AppColors.background,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceXL),
                  IconButton(
                    onPressed: hapticLight(() {
                      HapticFeedback.lightImpact();
                      _timerCompleted();
                    }),
                    icon: const Icon(Icons.skip_next_rounded, size: 28),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceXXL),

              // Association selectors
              _buildAssociationSection(habits, tasks),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssociationSection(List habits, List tasks) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Associate Session',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          // Habit selector
          DropdownButtonFormField<String>(
            value: _associatedHabitId,
            hint: const Text('Link to Habit (Optional)'),
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
          const SizedBox(height: AppDimensions.spaceS),
          // Task selector
          DropdownButtonFormField<String>(
            value: _associatedTaskId,
            hint: const Text('Link to Task (Optional)'),
            dropdownColor: AppColors.card,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('None')),
              ...tasks.map((t) => DropdownMenuItem<String>(value: t.id, child: Text(t.title))),
            ],
            onChanged: (val) {
              setState(() {
                _associatedTaskId = val;
              });
            },
          ),
          const SizedBox(height: AppDimensions.spaceM),
          // Session notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Add session notes (Optional)',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomPresetDialog() {
    int minutes = _workMinutes;
    int brk = _breakMinutes;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Custom Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: '$minutes',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Focus Duration (minutes)'),
              onChanged: (val) {
                minutes = int.tryParse(val) ?? 25;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: '$brk',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Break Duration (minutes)'),
              onChanged: (val) {
                brk = int.tryParse(val) ?? 5;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: hapticLight(() => Navigator.pop(ctx)),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: hapticMedium(() {
              Navigator.pop(ctx);
              _changeDurationPreset(minutes, brk);
            }),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hapticLight(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
