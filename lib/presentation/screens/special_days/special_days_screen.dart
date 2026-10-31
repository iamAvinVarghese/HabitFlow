import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/special_day_model.dart';
import '../../../domain/providers/special_day_providers.dart';

class SpecialDaysScreen extends ConsumerWidget {
  const SpecialDaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(specialDayNotifierProvider);

    final upcoming =
        days.where((d) => !d.isPast || d.type == SpecialDayType.yearly || d.type == SpecialDayType.monthly).toList();
    final past =
        days.where((d) => d.isPast && d.type == SpecialDayType.oneTime).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Special Days',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
            onPressed: hapticLight(() => context.push('/special-days/add')),
          ),
        ],
      ),
      body: days.isEmpty
          ? const _EmptyState()
          : CustomScrollView(
              slivers: [
                if (upcoming.isNotEmpty) ...[
                  SliverPersistentHeader(
                    delegate: _SliverHeader('Upcoming'),
                    pinned: false,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingPage),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _SpecialDayCard(
                          model: upcoming[i],
                          onTap: () => context
                              .push('/special-days/edit/${upcoming[i].id}'),
                          onDelete: () =>
                              _confirmDelete(context, ref, upcoming[i]),
                        ),
                        childCount: upcoming.length,
                      ),
                    ),
                  ),
                ],

                if (past.isNotEmpty) ...[
                  SliverPersistentHeader(
                    delegate: _SliverHeader('Past Events'),
                    pinned: false,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingPage),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _SpecialDayCard(
                          model: past[i],
                          isPast: true,
                          onTap: () =>
                              context.push('/special-days/edit/${past[i].id}'),
                          onDelete: () =>
                              _confirmDelete(context, ref, past[i]),
                        ),
                        childCount: past.length,
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(
                    child: SizedBox(height: AppDimensions.spaceXL)),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: hapticMedium(() => context.push('/special-days/add')),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, SpecialDayModel model) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge)),
        title: Text(
          'Delete "${model.title}"?',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Text(
          'All ${model.notificationIds.length} scheduled reminders will be cancelled.',
          style:
              GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: hapticLight(() => Navigator.pop(ctx)),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              AppHaptics.medium();
              Navigator.pop(ctx);
              ref
                  .read(specialDayNotifierProvider.notifier)
                  .delete(model);
            },
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _SpecialDayCard extends StatelessWidget {
  final SpecialDayModel model;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isPast;

  const _SpecialDayCard({
    required this.model,
    required this.onTap,
    required this.onDelete,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final days = model.daysUntilNext;

    String countdownLabel;
    Color countdownColor;
    if (isPast) {
      countdownLabel = 'Passed';
      countdownColor = AppColors.textTertiary;
    } else if (days == 0) {
      countdownLabel = 'TODAY';
      countdownColor = AppColors.textPrimary;
    } else if (days == 1) {
      countdownLabel = 'Tomorrow';
      countdownColor = AppColors.textSecondary;
    } else {
      countdownLabel = 'In $days days';
      countdownColor = AppColors.textSecondary;
    }

    final dateLabel = model.type == SpecialDayType.yearly
        ? DateFormat('MMMM d').format(model.date)
        : model.type == SpecialDayType.monthly
            ? 'Day ${model.date.day} of every month'
            : DateFormat('MMM d, y').format(model.date);

    final typeIcon = model.type == SpecialDayType.yearly
        ? Icons.repeat_rounded
        : model.type == SpecialDayType.monthly
            ? Icons.repeat_one_rounded
            : Icons.today_rounded;
    final typeLabel = model.type == SpecialDayType.yearly
        ? 'Yearly'
        : model.type == SpecialDayType.monthly
            ? 'Monthly'
            : 'One-time';

    final List<int> offsets = model.reminderOffsets.isNotEmpty
        ? (List<int>.from(model.reminderOffsets)..sort((a, b) => b.compareTo(a)))
        : [7, 3, 1, 0];
    final offsetsLabel = offsets.map((off) {
      if (off == 0) return 'Day-of';
      return '${off}d';
    }).join(' · ');

    return GestureDetector(
      onTap: hapticLight(onTap),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            // Left strip (white, always visible for upcoming events)
            if (!isPast)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppDimensions.radiusLarge),
                      bottomLeft: Radius.circular(AppDimensions.radiusLarge),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: title + countdown
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isPast
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 11,
                                    color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  dateLabel,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            countdownLabel,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: countdownColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Type badge (no emoji)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeIcon,
                                  size: 10,
                                  color: AppColors.textTertiary),
                              const SizedBox(width: 3),
                              Text(
                                typeLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.textTertiary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Quick note snippet
                  if (model.notes != null && model.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notes_rounded,
                              size: 12,
                              color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              model.notes!,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Bottom row: reminders + delete
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        offsetsLabel,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textTertiary),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: hapticMedium(onDelete),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 17, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingPage),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.06),
                    blurRadius: 48,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.lightbulb_rounded,
                  size: 44,
                  color: AppColors.textPrimary,
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 12,
                    ),
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'No Special Days Yet',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Add birthdays, anniversaries, or any event\nyou never want to forget.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            ElevatedButton.icon(
              onPressed:
                  hapticMedium(() => context.push('/special-days/add')),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Add Special Day',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sliver Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SliverHeader extends SliverPersistentHeaderDelegate {
  final String title;
  _SliverHeader(this.title);

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(
        color: AppColors.background,
        padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingPage, 16, AppDimensions.paddingPage, 8),
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 1.2),
        ),
      );

  @override
  double get maxExtent => 44;
  @override
  double get minExtent => 44;
  @override
  bool shouldRebuild(covariant _SliverHeader old) => old.title != title;
}
