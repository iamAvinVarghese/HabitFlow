import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.bottomNavHeight + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _NavItem(
              icon: Icons.grid_view_rounded,
              label: 'Dashboard',
              isSelected: currentIndex == 0,
              onTap: hapticSelection(() => onTap(0)),
            ),
            _NavItem(
              icon: Icons.repeat_rounded,
              label: 'Habits',
              isSelected: currentIndex == 1,
              onTap: hapticSelection(() => onTap(1)),
            ),
            _NavItem(
              icon: Icons.check_circle_outline_rounded,
              label: 'Tasks',
              isSelected: currentIndex == 2,
              onTap: hapticSelection(() => onTap(2)),
            ),
            _NavItem(
              icon: Icons.note_alt_rounded,
              label: 'Notes',
              isSelected: currentIndex == 3,
              onTap: hapticSelection(() => onTap(3)),
            ),
            _NavItem(
              icon: Icons.lightbulb_rounded,
              label: 'Special',
              isSelected: currentIndex == 4,
              onTap: hapticSelection(() => onTap(4)),
              glowing: true,
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              isSelected: currentIndex == 5,
              onTap: hapticSelection(() => onTap(5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool glowing;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.glowing = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<Shadow> glowShadows = [
      Shadow(
        color: Colors.white.withValues(alpha: 0.9),
        blurRadius: 10,
      ),
      Shadow(
        color: Colors.white.withValues(alpha: 0.5),
        blurRadius: 20,
      ),
    ];

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDimensions.animFast,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppDimensions.animFast,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                  size: 22,
                  shadows: (glowing && isSelected) ? glowShadows : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
