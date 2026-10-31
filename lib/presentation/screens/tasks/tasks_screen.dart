import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../domain/providers/task_providers.dart';
import '../../widgets/task_card.dart';
import '../../widgets/undo_snackbar.dart';
import '../../widgets/skeleton_loader.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showCompleted = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    ref.read(taskNotifierProvider.notifier).refresh();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTasks = ref.watch(activeTasksProvider);
    final completedTasks = ref.watch(completedTasksProvider);
    final searchedTasks = ref.watch(searchedTasksProvider);
    final query = ref.watch(taskSearchQueryProvider);

    final displayedActive = query.isNotEmpty ? searchedTasks : activeTasks;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: AppColors.background,
            floating: true,
            snap: true,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      hintStyle: GoogleFonts.inter(
                          color: AppColors.textTertiary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (val) {
                      ref
                          .read(taskSearchQueryProvider.notifier)
                          .state = val;
                    },
                  )
                : Text(
                    'Tasks',
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
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: hapticLight(() {
                  setState(() => _isSearching = !_isSearching);
                  if (!_isSearching) {
                    _searchController.clear();
                    ref.read(taskSearchQueryProvider.notifier).state = '';
                  }
                }),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
                onPressed: hapticLight(() => context.push('/tasks/add')),
              ),
            ],
          ),
        ],
        body: RefreshIndicator(
          color: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          onRefresh: _refresh,
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingPage),
                  child: SkeletonListLoader(itemCount: 4),
                )
              : displayedActive.isEmpty && completedTasks.isEmpty
                  ? _buildEmptyState()
                  : CustomScrollView(
                      slivers: [
                        // Pinned section
                        ...() {
                          final pinned = displayedActive
                              .where((t) => t.isPinned)
                              .toList();
                          if (pinned.isEmpty) return <Widget>[];
                          return [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(AppDimensions.paddingPage, AppDimensions.spaceM, AppDimensions.paddingPage, 0),
                              sliver: SliverToBoxAdapter(
                                child: _SectionLabel(
                                  title: 'Pinned',
                                  icon: Icons.push_pin,
                                  count: pinned.length,
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage, vertical: 8),
                              sliver: SliverReorderableList(
                                itemCount: pinned.length,
                                onReorder: (oldIdx, newIdx) {
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    if (newIdx > oldIdx) newIdx -= 1;
                                    final item = pinned.removeAt(oldIdx);
                                    pinned.insert(newIdx, item);
                                  });
                                },
                                itemBuilder: (context, idx) {
                                  final task = pinned[idx];
                                  return ReorderableDelayedDragStartListener(
                                    key: ValueKey('pinned_${task.id}'),
                                    index: idx,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                                      child: TaskCard(
                                        task: task,
                                        onEdit: () => context.push('/tasks/edit/${task.id}'),
                                        onDelete: () {
                                          final t = task;
                                          ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
                                          UndoSnackbar.show(
                                            context: context,
                                            message: 'Task deleted',
                                            onUndo: () => ref.read(taskNotifierProvider.notifier).addTask(t),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ];
                        }(),

                        // Active section
                        ...() {
                          final unpinned = displayedActive
                              .where((t) => !t.isPinned)
                              .toList();
                          if (unpinned.isEmpty) return <Widget>[];
                          return [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(AppDimensions.paddingPage, AppDimensions.spaceM, AppDimensions.paddingPage, 0),
                              sliver: SliverToBoxAdapter(
                                child: _SectionLabel(
                                  title: query.isNotEmpty ? 'Results' : 'Active',
                                  icon: Icons.circle_outlined,
                                  count: unpinned.length,
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage, vertical: 8),
                              sliver: SliverReorderableList(
                                itemCount: unpinned.length,
                                onReorder: (oldIdx, newIdx) {
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    if (newIdx > oldIdx) newIdx -= 1;
                                    final item = unpinned.removeAt(oldIdx);
                                    unpinned.insert(newIdx, item);
                                  });
                                },
                                itemBuilder: (context, idx) {
                                  final task = unpinned[idx];
                                  return ReorderableDelayedDragStartListener(
                                    key: ValueKey('active_${task.id}'),
                                    index: idx,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                                      child: TaskCard(
                                        task: task,
                                        onEdit: () => context.push('/tasks/edit/${task.id}'),
                                        onDelete: () {
                                          final t = task;
                                          ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
                                          UndoSnackbar.show(
                                            context: context,
                                            message: 'Task deleted',
                                            onUndo: () => ref.read(taskNotifierProvider.notifier).addTask(t),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ];
                        }(),

                        // Completed section
                        if (completedTasks.isNotEmpty && query.isEmpty) ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(AppDimensions.paddingPage, AppDimensions.spaceM, AppDimensions.paddingPage, 0),
                            sliver: SliverToBoxAdapter(
                              child: GestureDetector(
                                onTap: hapticLight(() => setState(() => _showCompleted = !_showCompleted)),
                                child: Row(
                                  children: [
                                    _SectionLabel(
                                      title: 'Completed',
                                      icon: Icons.check_circle_rounded,
                                      count: completedTasks.length,
                                    ),
                                    const Spacer(),
                                    Icon(
                                      _showCompleted
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textTertiary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_showCompleted)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage, vertical: 8),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, idx) {
                                    final task = completedTasks[idx];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                                      child: TaskCard(
                                        task: task,
                                        onEdit: () => context.push('/tasks/edit/${task.id}'),
                                        onDelete: () {
                                          final t = task;
                                          ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
                                          UndoSnackbar.show(
                                            context: context,
                                            message: 'Task deleted',
                                            onUndo: () => ref.read(taskNotifierProvider.notifier).addTask(t),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  childCount: completedTasks.length,
                                ),
                              ),
                            ),
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 56, color: AppColors.textTertiary),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            'No tasks yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first task',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;

  const _SectionLabel({
    required this.title,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
