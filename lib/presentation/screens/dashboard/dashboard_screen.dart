import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/habit_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/providers/habit_providers.dart';
import '../../../domain/providers/task_providers.dart';
import '../../../domain/providers/mood_providers.dart';
import '../../../domain/providers/journal_providers.dart';
import '../../../domain/providers/pomodoro_providers.dart';
import '../../../domain/providers/achievement_providers.dart';
import '../../../domain/providers/goal_providers.dart';
import '../../../domain/providers/gamification_providers.dart';
import '../../widgets/circular_progress_ring.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/task_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/blinking_notification_icon.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _confirmDeleteHabit(BuildContext context, HabitModel habit, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Habit'),
        content: Text(
          'Are you sure you want to delete "${habit.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: hapticLight(() => Navigator.pop(ctx)),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: hapticMedium(() {
              Navigator.pop(ctx);
              ref.read(habitNotifierProvider.notifier).deleteHabit(habit.id);
            }),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    ref.read(habitNotifierProvider.notifier).refresh();
    ref.read(taskNotifierProvider.notifier).refresh();
    ref.read(moodNotifierProvider.notifier).refresh();
    ref.read(journalNotifierProvider.notifier).refresh();
    ref.read(pomodoroNotifierProvider.notifier).refresh();
    ref.read(goalNotifierProvider.notifier).refresh();
    ref.read(achievementNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Triggers auto-unlock checker on dashboard load
    ref.watch(gamificationEngineProvider);

    final habits = ref.watch(activeHabitsProvider);
    final completionRate = ref.watch(todayCompletionRateProvider);
    final currentStreak = ref.watch(currentStreakProvider);
    final longestStreak = ref.watch(longestStreakProvider);
    final activeTasks = ref.watch(activeTasksProvider);
    final completedTasks = ref.watch(completedTasksProvider);
    final pendingCount = ref.watch(pendingTaskCountProvider);
    final todayCompleted = ref.watch(todayCompletedTaskCountProvider);
    final productivity = ref.watch(productivityScoreProvider);

    // Premium gamification metrics
    final consistency = ref.watch(consistencyScoreProvider);
    final habitScore = ref.watch(habitScoreProvider);
    final unlockedBadges = ref.watch(achievementNotifierProvider);
    final activeGoals = ref.watch(activeGoalsProvider);

    final todayHabits = habits.take(5).toList();
    final todayTasksPreview = activeTasks.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
        onRefresh: () => _handleRefresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: AppColors.background,
              expandedHeight: 0,
              floating: true,
              snap: true,
              title: Text(
                AppStrings.appName,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.timeline_rounded, color: AppColors.textSecondary),
                  onPressed: hapticLight(() => context.push('/timeline')),
                  tooltip: 'Timeline',
                ),
                const BlinkingNotificationIcon(),
                IconButton(
                  icon: const Icon(Icons.flag_rounded, color: AppColors.textSecondary),
                  onPressed: hapticLight(() => context.push('/goals')),
                  tooltip: 'Goals',
                ),
                IconButton(
                  icon: const Icon(Icons.stars_rounded, color: AppColors.textSecondary),
                  onPressed: hapticLight(() => context.push('/achievements')),
                  tooltip: 'Achievements',
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingPage,
                0,
                AppDimensions.paddingPage,
                120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Greeting
                  _buildGreeting(),
                  const SizedBox(height: AppDimensions.spaceXL),

                  // Hero progress ring card
                  _buildHeroCard(completionRate, currentStreak),
                  const SizedBox(height: AppDimensions.spaceM),

                  // Gamification score cards row
                  _buildGamificationRow(consistency, habitScore),
                  const SizedBox(height: AppDimensions.spaceM),

                  // Streaks row
                  _buildStreaksRow(currentStreak, longestStreak),
                  const SizedBox(height: AppDimensions.spaceM),

                  // Quick links (Mood tracker, Pomodoro, Journal)
                  _buildQuickModulesSection(context),
                  const SizedBox(height: AppDimensions.spaceM),

                  // Active Goals Progress Row
                  if (activeGoals.isNotEmpty) ...[
                    _buildActiveGoalsSection(context, activeGoals),
                    const SizedBox(height: AppDimensions.spaceM),
                  ],

                  // Task stats row
                  _buildTaskStatsRow(pendingCount, todayCompleted, productivity),
                  const SizedBox(height: AppDimensions.spaceXL),

                  // Today's Habits
                  if (habits.isNotEmpty) ...[
                    _SectionHeader(
                      title: "Today's Habits",
                      actionLabel: 'See all',
                      onAction: () => context.go('/habits'),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    ...todayHabits.map((habit) => HabitCard(
                      habit: habit,
                      onEdit: () => context.push('/habits/edit/${habit.id}'),
                      onDelete: () => _confirmDeleteHabit(context, habit, ref),
                    )),
                    if (habits.length > 5) ...[
                      const SizedBox(height: AppDimensions.spaceS),
                      _MoreButton(
                        label: '+${habits.length - 5} more habits',
                        onTap: hapticLight(() => context.go('/habits')),
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spaceXL),
                  ],

                  // Today's Tasks
                  if (activeTasks.isNotEmpty || completedTasks.isNotEmpty) ...[
                    _SectionHeader(
                      title: "Today's Tasks",
                      actionLabel: 'See all',
                      onAction: () => context.go('/tasks'),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    ...todayTasksPreview.map((task) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                      child: TaskCard(
                        task: task,
                        onEdit: () => context.push('/tasks/edit/${task.id}'),
                        onDelete: () => ref.read(taskNotifierProvider.notifier).deleteTask(task.id),
                      ),
                    )),
                    if (activeTasks.length > 4) ...[
                      const SizedBox(height: AppDimensions.spaceS),
                      _MoreButton(
                        label: '+${activeTasks.length - 4} more tasks',
                        onTap: hapticLight(() => context.go('/tasks')),
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spaceXL),
                  ],

                  // Unlocked achievements display
                  if (unlockedBadges.isNotEmpty) ...[
                    _buildAchievementsTeaser(context, unlockedBadges),
                    const SizedBox(height: AppDimensions.spaceXL),
                  ],

                  // Empty state
                  if (habits.isEmpty && activeTasks.isEmpty)
                    _buildEmptyState(context),

                  // Recent Activity
                  _buildRecentActivity(habits, completedTasks),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final now = DateTime.now();
    final greeting = AppDateUtils.getGreeting();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(double completionRate, int streak) {
    final pct = (completionRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircularProgressRing(
            progress: completionRate,
            size: 110,
            strokeWidth: 9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$pct%',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                Text(
                  'done',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Progress',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pct == 100
                      ? 'All done!'
                      : pct == 0
                          ? 'Let\'s get started!'
                          : 'Keep going, you\'re doing great!',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                if (streak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 14, color: AppColors.textPrimary),
                        const SizedBox(width: 4),
                        Text(
                          '$streak day streak',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationRow(double consistency, int score) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Consistency',
            value: '${consistency.round()}%',
            icon: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: _MiniStatCard(
            label: 'Habit Score',
            value: '$score',
            icon: Icons.emoji_events_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStreaksRow(int current, int longest) {
    return Row(
      children: [
        Expanded(
          child: StreakBadge(
            value: current,
            label: 'Current\nStreak',
            icon: Icons.local_fire_department_rounded,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: StreakBadge(
            value: longest,
            label: 'Longest\nStreak',
            icon: Icons.workspace_premium_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickModulesSection(BuildContext context) {
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
            'Premium Tools',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickModuleItem(
                icon: Icons.timer_rounded,
                label: 'Pomodoro',
                onTap: hapticLight(() => context.push('/pomodoro')),
              ),
              _QuickModuleItem(
                icon: Icons.mood_rounded,
                label: 'Mood Log',
                onTap: hapticLight(() => context.push('/mood')),
              ),
              _QuickModuleItem(
                icon: Icons.book_rounded,
                label: 'Journal',
                onTap: hapticLight(() => context.push('/journal')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGoalsSection(BuildContext context, List activeGoals) {
    final firstGoal = activeGoals.first;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Goal Progress',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              GestureDetector(
                onTap: hapticLight(() => context.push('/goals')),
                child: Text(
                  'Manage',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            firstGoal.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: firstGoal.progressPercentage,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation(AppColors.textPrimary),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatsRow(int pending, int completed, double productivity) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Remaining',
            value: '$pending',
            icon: Icons.pending_outlined,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: _MiniStatCard(
            label: 'Completed',
            value: '$completed',
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(
          child: _MiniStatCard(
            label: 'Score',
            value: '${productivity.round()}%',
            icon: Icons.offline_bolt_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsTeaser(BuildContext context, List badges) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.textPrimary, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pro Badges', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${badges.length} unlocked milestones', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onPressed: hapticLight(() => context.push('/achievements')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.auto_awesome_rounded,
      title: 'Start your journey',
      description: 'Add a habit or task using the + button to begin tracking your progress.',
      action: ElevatedButton(
        onPressed: hapticLight(() => context.push('/habits/add')),
        child: const Text('Add a Habit'),
      ),
    );
  }

  Widget _buildRecentActivity(List habits, List completedTasks) {
    final hasActivity = completedTasks.isNotEmpty;
    if (!hasActivity) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: completedTasks.take(5).length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: AppColors.border,
            ),
            itemBuilder: (context, i) {
              final task = completedTasks[i];
              return ListTile(
                leading: const Icon(Icons.check_circle_rounded,
                    color: AppColors.textPrimary, size: 20),
                title: Text(
                  task.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.textTertiary,
                  ),
                ),
                trailing: Text(
                  task.completedAt != null
                      ? DateFormat('hh:mm a').format(task.completedAt!)
                      : '',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: hapticLight(onAction),
            child: Text(
              actionLabel!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _MoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MoreButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hapticLight(onTap),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickModuleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickModuleItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hapticLight(onTap),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
