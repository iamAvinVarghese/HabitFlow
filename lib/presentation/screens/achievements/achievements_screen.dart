import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../domain/providers/achievement_providers.dart';
import '../../widgets/achievement_badge.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches gamification to trigger unlocks
    ref.watch(achievementNotifierProvider);
    final badges = ref.watch(allAchievementsWithStatusProvider);

    final unlockedCount = badges.where((b) => b['isUnlocked'] == true).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingPage,
          vertical: AppDimensions.spaceM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score progress row
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingCard),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, size: 36, color: AppColors.textPrimary),
                  const SizedBox(width: AppDimensions.spaceM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Achievement Badges',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Unlocked: $unlockedCount / ${badges.length}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            const Text(
              'Badge List',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                  child: AchievementBadgeCard(
                    title: badge['title'],
                    description: badge['description'],
                    iconName: badge['iconName'],
                    isUnlocked: badge['isUnlocked'],
                    unlockedAt: badge['unlockedAt'],
                    isMilestone: badge['isMilestone'],
                  ),
                );
              },
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
