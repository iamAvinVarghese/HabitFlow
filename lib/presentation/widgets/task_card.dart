import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/task_model.dart';
import '../../domain/providers/task_providers.dart';
import 'animated_checkmark.dart';

class TaskCard extends ConsumerStatefulWidget {
  final TaskModel task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showDivider;

  const TaskCard({
    super.key,
    required this.task,
    this.onEdit,
    this.onDelete,
    this.showDivider = false,
  });

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: AppDimensions.animMedium,
      vsync: this,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Color get _priorityColor {
    switch (widget.task.priority) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }

  String get _priorityLabel {
    switch (widget.task.priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.isCompleted;
    final notifier = ref.read(taskNotifierProvider.notifier);

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onEdit?.call();
      },
      child: Dismissible(
        key: ValueKey(widget.task.id),
        background: _buildSwipeBackground(
          color: AppColors.surfaceVariant,
          icon: Icons.check_circle_rounded,
          label: 'Complete',
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _buildSwipeBackground(
          color: const Color(0xFF2A1010),
          icon: Icons.delete_rounded,
          label: 'Delete',
          alignment: Alignment.centerRight,
          iconColor: const Color(0xFFFF6B6B),
        ),
        onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {
            AppHaptics.success();
            notifier.completeTask(widget.task.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task completed! ✓'),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            AppHaptics.heavy();
            notifier.deleteTask(widget.task.id);
          }
        },
        child: Slidable(
          key: ValueKey('slide_${widget.task.id}'),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (context) {
                  AppHaptics.light();
                  notifier.togglePin(widget.task.id);
                },
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textPrimary,
                icon: widget.task.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusLarge),
                  bottomLeft: Radius.circular(AppDimensions.radiusLarge),
                ),
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
                  AppHaptics.light();
                  notifier.toggleArchive(widget.task.id);
                },
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.textSecondary,
                icon: Icons.archive_rounded,
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
          child: AnimatedOpacity(
            opacity: isCompleted ? 0.45 : 1.0,
            duration: AppDimensions.animMedium,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.borderSubtle
                      : AppColors.border,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingCard,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Priority indicator
                    Container(
                      width: 3,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.textDisabled
                            : _priorityColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (widget.task.isPinned) ...[
                                const Icon(Icons.push_pin,
                                    size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  widget.task.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: isCompleted
                                        ? AppColors.textTertiary
                                        : AppColors.textPrimary,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: AppColors.textTertiary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (widget.task.notes != null &&
                              widget.task.notes!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.task.notes!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                _priorityLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isCompleted
                                      ? AppColors.textDisabled
                                      : _priorityColor.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (!isCompleted &&
                                  widget.task.reminderTime != null &&
                                  widget.task.reminderTime!.isBefore(DateTime.now())) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'OVERDUE',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFFFF6B6B),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppDimensions.spaceS),

                    // Checkmark
                    AnimatedCheckmark(
                      checked: isCompleted,
                      onTap: () {
                        if (isCompleted) {
                          AppHaptics.light();
                          notifier.uncompleteTask(widget.task.id);
                        } else {
                          AppHaptics.success();
                          notifier.completeTask(widget.task.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
    Color iconColor = AppColors.textPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: iconColor,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
