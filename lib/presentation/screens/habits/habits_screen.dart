import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/habit_model.dart';
import '../../../domain/providers/habit_providers.dart';
import '../../widgets/day_activity_bottom_sheet.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/habit_heatmap.dart';
import '../../widgets/skeleton_loader.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  bool _showArchived = false;
  bool _isLoading = false;

  final _categories = ['All', ...AppStrings.categories];

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });
    // Simulate loading for premium skeleton animation
    await Future.delayed(const Duration(milliseconds: 400));
    ref.read(habitNotifierProvider.notifier).refresh();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(filteredHabitsProvider);
    final archivedHabits = ref.watch(archivedHabitsProvider);
    final weeklyData = ref.watch(weeklyCompletionsProvider);
    final notifier = ref.read(habitNotifierProvider.notifier);

    // Apply local category filter
    final filtered = _selectedCategory == 'All'
        ? habits
        : habits.where((h) => h.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: AppColors.background,
            floating: true,
            snap: true,
            title: Text(
              'Habits',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showArchived ? Icons.archive : Icons.archive_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: hapticLight(() => setState(() => _showArchived = !_showArchived)),
                tooltip: 'Archived',
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
                onPressed: hapticLight(() => context.push('/habits/add')),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: _buildCategoryFilter(),
            ),
          ),
        ],
        body: RefreshIndicator(
          color: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          onRefresh: _refresh,
          child: _showArchived
              ? _buildArchivedList(archivedHabits, notifier)
              : _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(AppDimensions.paddingPage),
                      child: SkeletonListLoader(itemCount: 4),
                    )
                  : _buildActiveView(filtered, weeklyData, notifier),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingPage, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.spaceS),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = _selectedCategory == cat;
          return GestureDetector(
            onTap: hapticSelection(() {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedCategory = cat;
              });
            }),
            child: AnimatedContainer(
              duration: AppDimensions.animFast,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.background : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveView(List<HabitModel> habits, Map<String, int> weeklyData, HabitNotifier notifier) {
    if (habits.isEmpty) {
      return _buildEmptyState();
    }

    final favorites = habits.where((h) => h.isFavorite).toList();
    final others = habits.where((h) => !h.isFavorite).toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppDimensions.paddingPage),
          sliver: SliverToBoxAdapter(
            child: HabitHeatmap(
              completedData: weeklyData,
              totalHabits: habits.length,
              onDayPressed: (date) => _showDayActivity(context, date),
            ),
          ),
        ),
        if (favorites.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage),
            sliver: SliverToBoxAdapter(
              child: _CategoryHeader(title: 'Favorites', count: favorites.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage, vertical: 8),
            sliver: SliverReorderableList(
              itemCount: favorites.length,
              onReorder: (oldIdx, newIdx) {
                HapticFeedback.mediumImpact();
                // Simulating local drag & drop task sorting order
                setState(() {
                  if (newIdx > oldIdx) newIdx -= 1;
                  final item = favorites.removeAt(oldIdx);
                  favorites.insert(newIdx, item);
                });
              },
              itemBuilder: (context, idx) {
                final h = favorites[idx];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey('fav_${h.id}'),
                  index: idx,
                  child: _buildHabitTile(h, notifier),
                );
              },
            ),
          ),
        ],
        if (others.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage),
            sliver: SliverToBoxAdapter(
              child: _CategoryHeader(title: 'All Habits', count: others.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage, vertical: 8),
            sliver: SliverReorderableList(
              itemCount: others.length,
              onReorder: (oldIdx, newIdx) {
                HapticFeedback.mediumImpact();
                setState(() {
                  if (newIdx > oldIdx) newIdx -= 1;
                  final item = others.removeAt(oldIdx);
                  others.insert(newIdx, item);
                });
              },
              itemBuilder: (context, idx) {
                final h = others[idx];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey('other_${h.id}'),
                  index: idx,
                  child: _buildHabitTile(h, notifier),
                );
              },
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildHabitTile(HabitModel habit, HabitNotifier notifier) {
    return Padding(
      key: ValueKey(habit.id),
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
      child: HabitCard(
        habit: habit,
        onTap: hapticLight(() => _showHabitDetail(habit)),
        onEdit: () => context.push('/habits/edit/${habit.id}'),
        onDelete: () => _confirmDelete(habit, notifier),
      ),
    );
  }

  Widget _buildArchivedList(
      List<HabitModel> habits, HabitNotifier notifier) {
    if (habits.isEmpty) {
      return Center(
        child: Text(
          'No archived habits',
          style: GoogleFonts.inter(color: AppColors.textTertiary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingPage,
        AppDimensions.spaceM,
        AppDimensions.paddingPage,
        120,
      ),
      children: habits.map((habit) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spaceS),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingCard, vertical: 4),
            title: Text(
              habit.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            subtitle: Text(
              habit.category,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textTertiary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.unarchive_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: hapticSelection(() => notifier.toggleArchive(habit.id)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded,
                      color: Color(0xFFFF6B6B), size: 20),
                  onPressed: hapticMedium(() => _confirmDelete(habit, notifier)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.repeat_rounded, size: 56, color: AppColors.textTertiary),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            'No habits yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first habit',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showHabitDetail(HabitModel habit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      builder: (_) => _HabitDetailSheet(habit: habit),
    );
  }

  void _confirmDelete(HabitModel habit, HabitNotifier notifier) {
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
            onPressed: hapticMedium(() async {
              Navigator.pop(ctx);
              await notifier.deleteHabit(habit.id);
              if (mounted) setState(() {});
            }),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }

  void _showDayActivity(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      builder: (_) => DayActivityBottomSheet(date: date),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final int count;

  const _CategoryHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitDetailSheet extends ConsumerWidget {
  final HabitModel habit;

  const _HabitDetailSheet({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStreak = ref.read(habitRepositoryProvider).getCurrentStreak(habit.id);
    final longestStreak = ref.read(habitRepositoryProvider).getLongestStreak(habit.id);
    final notifier = ref.read(habitNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingPage),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          Text(
            habit.title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            habit.category,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          Row(
            children: [
              Expanded(
                child: _DetailStat(label: 'Current Streak', value: '$currentStreak days'),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: _DetailStat(label: 'Longest Streak', value: '$longestStreak days'),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: _DetailStat(label: 'Total Done', value: '${habit.completedDates.length}'),
              ),
            ],
          ),
          if (habit.notes != null && habit.notes!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.paddingCard),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                habit.notes!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spaceL),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hapticSelection(() {
                    notifier.toggleArchive(habit.id);
                    Navigator.pop(context);
                  }),
                  icon: const Icon(Icons.archive_rounded, size: 16),
                  label: Text(habit.isArchived ? 'Unarchive' : 'Archive'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hapticLight(() {
                    notifier.duplicate(habit.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Habit duplicated!')),
                    );
                  }),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Duplicate'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppDimensions.spaceM),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;

  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
