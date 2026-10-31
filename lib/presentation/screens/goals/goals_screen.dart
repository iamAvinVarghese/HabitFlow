import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../domain/providers/goal_providers.dart';
import '../../widgets/goal_progress_card.dart';
import '../../widgets/empty_state.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoals = ref.watch(activeGoalsProvider);
    final completedGoals = ref.watch(completedGoalsProvider);
    final overdueGoals = ref.watch(overdueGoalsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Productivity Goals',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: hapticLight(() => context.push('/goals/add')),
            ),
          ],
          bottom: const TabBar(
            dividerColor: Colors.transparent,
            indicatorColor: AppColors.textPrimary,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textTertiary,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Overdue'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGoalList(context, ref, activeGoals, 'No active goals', 'Create daily/weekly/monthly goals to stay on target.'),
            _buildGoalList(context, ref, completedGoals, 'No completed goals', 'Finish your active goals to see them listed here.'),
            _buildGoalList(context, ref, overdueGoals, 'No overdue goals', 'You are doing great staying on schedule!'),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalList(
    BuildContext context,
    WidgetRef ref,
    List goals,
    String emptyTitle,
    String emptyDesc,
  ) {
    if (goals.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.flag_rounded,
          title: emptyTitle,
          description: emptyDesc,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingPage),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
          child: GoalProgressCard(
            goal: goal,
            onDelete: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.card,
                  title: const Text('Delete Goal'),
                  content: const Text('Are you sure you want to delete this goal?'),
                  actions: [
                    TextButton(
                      onPressed: hapticLight(() => Navigator.pop(ctx)),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: hapticMedium(() {
                        ref.read(goalNotifierProvider.notifier).deleteGoal(goal.id);
                        Navigator.pop(ctx);
                      }),
                      child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B))),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
