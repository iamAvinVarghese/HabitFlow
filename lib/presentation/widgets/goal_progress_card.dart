import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/goal_model.dart';
import 'package:intl/intl.dart';

class GoalProgressCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GoalProgressCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onDelete,
  });

  String _getGoalTypeLabel() {
    switch (goal.type) {
      case GoalType.daily: return 'Daily';
      case GoalType.weekly: return 'Weekly';
      case GoalType.monthly: return 'Monthly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercentage;
    final isOverdue = !goal.isCompleted && goal.deadline.isBefore(DateTime.now());

    return GestureDetector(
      onTap: hapticLight(onTap),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingCard),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(
            color: goal.isCompleted ? AppColors.borderBright : AppColors.border,
            width: goal.isCompleted ? 1.2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    _getGoalTypeLabel(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Expanded(
                  child: Text(
                    goal.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: goal.isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                      decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFFF6B6B)),
                    onPressed: hapticMedium(onDelete),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  '${goal.currentValue} / ${goal.targetValue}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation(AppColors.textPrimary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deadline: ${DateFormat('MMM dd, yyyy').format(goal.deadline)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isOverdue ? const Color(0xFFFF6B6B) : AppColors.textTertiary,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (goal.isCompleted)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 12, color: AppColors.textPrimary),
                      SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  )
                else if (isOverdue)
                  const Text(
                    'Overdue',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
