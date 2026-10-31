import 'package:flutter/material.dart';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../widgets/bottom_nav_bar.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;
  bool _fabOpen = false;

  final List<String> _routes = [
    '/dashboard',
    '/habits',
    '/tasks',
    '/notes',
    '/special-days',
    '/settings',
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: AppDimensions.animMedium,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_fabOpen) _closeFab();
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  void _toggleFab() {
    HapticFeedback.lightImpact();
    setState(() => _fabOpen = !_fabOpen);
    if (_fabOpen) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  void _closeFab() {
    setState(() => _fabOpen = false);
    _fabController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hapticLight(_fabOpen ? _closeFab : null),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: widget.child,
        floatingActionButton: _buildFab(),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: _currentIndex,
          onTap: hapticLight(_onNavTap),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // FAB options
        AnimatedBuilder(
          animation: _fabController,
          builder: (context, _) {
            final scale = CurvedAnimation(
              parent: _fabController,
              curve: Curves.easeOutBack,
            ).value;

            if (scale <= 0) return const SizedBox.shrink();

            return Transform.scale(
              scale: scale,
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _FabOption(
                      label: 'Link Goal',
                      icon: Icons.flag_rounded,
                      onTap: hapticLight(() {
                        _closeFab();
                        context.push('/goals/add');
                      }),
                    ),
                    const SizedBox(height: 8),
                    _FabOption(
                      label: 'Focus Timer',
                      icon: Icons.timer_rounded,
                      onTap: hapticLight(() {
                        _closeFab();
                        context.push('/pomodoro');
                      }),
                    ),
                    const SizedBox(height: 8),
                    _FabOption(
                      label: 'Daily Journal',
                      icon: Icons.book_rounded,
                      onTap: hapticLight(() {
                        _closeFab();
                        context.push('/journal/write');
                      }),
                    ),
                    const SizedBox(height: 8),
                    _FabOption(
                      label: 'Log Mood',
                      icon: Icons.mood_rounded,
                      onTap: hapticLight(() {
                        _closeFab();
                        context.push('/mood');
                      }),
                    ),
                    const SizedBox(height: 8),
                    _FabOption(
                      label: 'New Task',
                      icon: Icons.check_circle_outline_rounded,
                      onTap: hapticLight(() {
                        _closeFab();
                        context.push('/tasks/add');
                      }),
                    ),
                    const SizedBox(height: 8),
                    _FabOption(
                      label: 'New Habit',
                      icon: Icons.repeat_rounded,
                      onTap: hapticLight(() {
                        _closeFab();
                        context.push('/habits/add');
                      }),
                    ),
                    const SizedBox(height: 8),
                    _FabOption(
                      label: 'New Note',
                      icon: Icons.note_add_rounded,
                      onTap: hapticLight(() {
                        _closeFab();
                        context.push('/journal/write');
                      }),
                    ),
                    const SizedBox(height: 8),
                    _FabOption(
                      label: 'Special Day',
                      icon: Icons.lightbulb_rounded,
                      iconShadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.9),
                          blurRadius: 10,
                        ),
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 20,
                        ),
                      ],
                      onTap: hapticLight(() {
                        _closeFab();
                        context.push('/special-days/add');
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Main FAB (positioned at the bottom right corner)
        AnimatedRotation(
          turns: _fabOpen ? 0.125 : 0.0,
          duration: AppDimensions.animMedium,
          child: FloatingActionButton(
            onPressed: hapticSelection(_toggleFab),
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
            elevation: 4,
            child: Icon(
              _fabOpen ? Icons.close_rounded : Icons.add_rounded,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

class _FabOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final List<Shadow>? iconShadows;

  const _FabOption({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconShadows,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hapticLight(onTap),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: AppColors.textPrimary,
                size: 18,
                shadows: iconShadows),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
