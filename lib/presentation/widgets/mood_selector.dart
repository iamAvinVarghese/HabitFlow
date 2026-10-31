import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/mood_model.dart';

class MoodSelector extends StatelessWidget {
  final MoodLevel? selectedMood;
  final ValueChanged<MoodLevel> onMoodSelected;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: MoodLevel.values.map((mood) {
        final isSelected = selectedMood == mood;
        
        IconData icon = Icons.sentiment_neutral_rounded;
        String label = '';
        switch (mood) {
          case MoodLevel.terrible:
            icon = Icons.sentiment_very_dissatisfied_rounded;
            label = 'Terrible';
            break;
          case MoodLevel.bad:
            icon = Icons.sentiment_dissatisfied_rounded;
            label = 'Bad';
            break;
          case MoodLevel.neutral:
            icon = Icons.sentiment_neutral_rounded;
            label = 'Neutral';
            break;
          case MoodLevel.good:
            icon = Icons.sentiment_satisfied_rounded;
            label = 'Good';
            break;
          case MoodLevel.excellent:
            icon = Icons.sentiment_very_satisfied_rounded;
            label = 'Excellent';
            break;
        }

        return GestureDetector(
          onTap: hapticSelection(() => onMoodSelected(mood)),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textPrimary : AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.textPrimary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? AppColors.background : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
