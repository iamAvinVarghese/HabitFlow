import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/habit_model.dart';
import '../../domain/providers/habit_providers.dart';
import 'animated_checkmark.dart';

class HabitCard extends ConsumerStatefulWidget {
  final HabitModel habit;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppDimensions.animMedium,
      vsync: this,
      value: 1.0,
    );
    _fadeAnim = Tween(begin: 1.0, end: 0.45).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.habit.isCompletedToday() != oldWidget.habit.isCompletedToday()) {
      if (widget.habit.isCompletedToday()) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  IconData get _categoryIcon {
    switch (widget.habit.category) {
      case 'Health': return Icons.favorite_rounded;
      case 'Fitness': return Icons.directions_run_rounded;
      case 'Study': return Icons.school_rounded;
      case 'Reading': return Icons.menu_book_rounded;
      case 'Coding': return Icons.code_rounded;
      case 'Work': return Icons.work_rounded;
      case 'Finance': return Icons.payments_rounded;
      case 'Personal': return Icons.person_rounded;
      default: return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.habit.isCompletedToday();
    final isSkipped = widget.habit.isSkippedToday();
    final notifier = ref.read(habitNotifierProvider.notifier);

    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) => Opacity(
        opacity: _fadeAnim.value,
        child: child,
      ),
      child: Slidable(
        key: ValueKey(widget.habit.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                AppHaptics.light();
                notifier.toggleFavorite(widget.habit.id);
              },
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.textPrimary,
              icon: widget.habit.isFavorite ? Icons.star : Icons.star_border,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusLarge),
                bottomLeft: Radius.circular(AppDimensions.radiusLarge),
              ),
            ),
            SlidableAction(
              onPressed: (context) {
                AppHaptics.light();
                notifier.skipToday(widget.habit.id);
              },
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.textSecondary,
              icon: Icons.skip_next_rounded,
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                AppHaptics.light();
                widget.onEdit?.call();
              },
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.textPrimary,
              icon: Icons.edit_rounded,
            ),
            SlidableAction(
              onPressed: (context) {
                AppHaptics.heavy();
                widget.onDelete?.call();
              },
              backgroundColor: const Color(0xFF2A1010),
              foregroundColor: const Color(0xFFFF6B6B),
              icon: Icons.delete_rounded,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppDimensions.radiusLarge),
                bottomRight: Radius.circular(AppDimensions.radiusLarge),
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: hapticLight(widget.onTap),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spaceS),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(
                color: isCompleted
                    ? AppColors.borderBright
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingCard),
              child: Row(
                children: [
                  // Category badge
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Icon(
                        _categoryIcon,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceM),

                  // Title + info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.habit.isFavorite) ...[
                              const Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                widget.habit.title,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? AppColors.textTertiary
                                      : AppColors.textPrimary,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.habit.category,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceS),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AppColors.textDisabled,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceS),
                            Text(
                              isSkipped ? 'Skipped' : '${widget.habit.completedDates.length} days',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isSkipped
                                    ? AppColors.textTertiary
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Checkmark
                  AnimatedCheckmark(
                    checked: isCompleted,
                    onTap: () {
                      if (isCompleted) {
                        AppHaptics.light();
                        notifier.uncompleteToday(widget.habit.id);
                      } else {
                        AppHaptics.success();
                        notifier.completeToday(widget.habit.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
