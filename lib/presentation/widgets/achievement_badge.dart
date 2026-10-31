import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'package:intl/intl.dart';

class AchievementBadgeCard extends StatelessWidget {
  final String title;
  final String description;
  final String iconName;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool isMilestone;

  const AchievementBadgeCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconName,
    required this.isUnlocked,
    this.unlockedAt,
    this.isMilestone = false,
  });

  IconData _getIconData() {
    switch (iconName) {
      case 'check_circle_outline_rounded': return Icons.check_circle_outline_rounded;
      case 'local_fire_department_rounded': return Icons.local_fire_department_rounded;
      case 'emoji_events_rounded': return Icons.emoji_events_rounded;
      case 'shield_rounded': return Icons.shield_rounded;
      case 'auto_awesome_rounded': return Icons.auto_awesome_rounded;
      case 'playlist_add_check_rounded': return Icons.playlist_add_check_rounded;
      case 'task_alt_rounded': return Icons.task_alt_rounded;
      case 'timer_rounded': return Icons.timer_rounded;
      case 'book_rounded': return Icons.book_rounded;
      case 'mood_rounded': return Icons.mood_rounded;
      default: return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isUnlocked ? AppColors.borderBright : AppColors.border,
          width: isUnlocked ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.textPrimary : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              iconData,
              color: isUnlocked ? AppColors.background : AppColors.textDisabled,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (isMilestone)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: const Text(
                          'Milestone',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? AppColors.textSecondary : AppColors.textTertiary,
                  ),
                ),
                if (isUnlocked && unlockedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Unlocked ${DateFormat('MMM dd, yyyy').format(unlockedAt!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
