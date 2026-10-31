import 'dart:io';
import 'package:habitflow/core/utils/haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/backup_service.dart';
import '../../../domain/providers/habit_providers.dart';
import '../../../domain/providers/task_providers.dart';
import '../../../domain/providers/mood_providers.dart';
import '../../../domain/providers/journal_providers.dart';
import '../../../domain/providers/pomodoro_providers.dart';
import '../../../domain/providers/achievement_providers.dart';
import '../../../domain/providers/goal_providers.dart';

import 'package:permission_handler/permission_handler.dart';

final notificationsEnabledProvider = StateNotifierProvider<_NotifNotifier, bool>((ref) {
  return _NotifNotifier();
});

class _NotifNotifier extends StateNotifier<bool> {
  _NotifNotifier() : super(true);

  Future<void> toggle(bool val) async {
    if (val) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        state = true;
      } else {
        state = false;
      }
    } else {
      state = false;
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
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
            _buildPremiumHeader(),
            const SizedBox(height: AppDimensions.spaceXL),
            
            // Notifications & Prompts
            _SectionHeader(title: 'Preferences'),
            const SizedBox(height: AppDimensions.spaceS),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  subtitle: 'Daily reminders for habits & tasks',
                  trailing: Switch(
                    value: notifEnabled,
                    onChanged: (v) => ref.read(notificationsEnabledProvider.notifier).toggle(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceL),

            // Backup & Data management
            _SectionHeader(title: 'Backup & Restore'),
            const SizedBox(height: AppDimensions.spaceS),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.upload_file_rounded,
                  title: 'Export Backup JSON',
                  subtitle: 'Save application state as JSON',
                  onTap: hapticLight(() => _exportJsonBackup(context)),
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingsTile(
                  icon: Icons.download_rounded,
                  title: 'Import Backup JSON',
                  subtitle: 'Restore application state from JSON',
                  onTap: hapticLight(() => _importJsonBackup(context, ref)),
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingsTile(
                  icon: Icons.table_view_rounded,
                  title: 'Export Habits to CSV',
                  subtitle: 'Extract habits records as CSV file',
                  onTap: hapticLight(() => _exportCsv(context, true)),
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingsTile(
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'Export Tasks to CSV',
                  subtitle: 'Extract daily tasks data as CSV file',
                  onTap: hapticLight(() => _exportCsv(context, false)),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceL),

            // Danger Zone / Resets
            _SectionHeader(title: 'Data Control'),
            const SizedBox(height: AppDimensions.spaceS),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.refresh_rounded,
                  title: 'Reset All Statistics',
                  subtitle: 'Wipe progress, streaks & logged stats',
                  titleColor: const Color(0xFFFF6B6B),
                  onTap: hapticMedium(() => _confirmReset(context, ref, true)),
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Reset All Data',
                  subtitle: 'Erase everything permanently',
                  titleColor: const Color(0xFFFF6B6B),
                  onTap: hapticMedium(() => _confirmReset(context, ref, false)),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceL),

            // Privacy & About
            _SectionHeader(title: 'App Information'),
            const SizedBox(height: AppDimensions.spaceS),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.security_rounded,
                  title: 'Privacy Policy',
                  subtitle: '100% offline. Zero tracking. Zero collection.',
                  onTap: hapticLight(() => _showPrivacyPolicy(context)),
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About ${AppStrings.appName}',
                  subtitle: 'Version 1.1.0 (Premium build)',
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXL),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderBright),
      ),
      child: const Row(
        children: [
          Icon(Icons.workspace_premium_rounded, size: 36, color: AppColors.textPrimary),
          SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.appName} Active',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Unlimited habits, goals, pomodoros & offline backups enabled.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportJsonBackup(BuildContext context) async {
    final path = await BackupService().exportBackupToJson();
    // Copy content of JSON to clipboard too for safety
    final file = SystemFileMock(path);
    final jsonStr = await file.readAsString();
    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Backup Exported'),
          content: Text(
            'JSON data written successfully:\n\n$path\n\nBackup string has also been copied to your clipboard.',
          ),
          actions: [
            TextButton(
              onPressed: hapticLight(() => Navigator.pop(ctx)),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _importJsonBackup(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Import Backup JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the exported backup JSON below:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 8,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: '{ "version": 1, ... }',
                contentPadding: EdgeInsets.all(8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: hapticLight(() => Navigator.pop(ctx)),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: hapticLight(() async {
              final jsonStr = textController.text.trim();
              if (jsonStr.isEmpty) return;

              final success = await BackupService().importBackupFromJson(jsonStr);
              if (ctx.mounted) Navigator.pop(ctx);
              
              if (success) {
                // Refresh states
                ref.read(habitNotifierProvider.notifier).refresh();
                ref.read(taskNotifierProvider.notifier).refresh();
                ref.read(moodNotifierProvider.notifier).refresh();
                ref.read(journalNotifierProvider.notifier).refresh();
                ref.read(pomodoroNotifierProvider.notifier).refresh();
                ref.read(goalNotifierProvider.notifier).refresh();
                ref.read(achievementNotifierProvider.notifier).refresh();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Database restored successfully!')),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to parse backup. Check formatting.')),
                  );
                }
              }
            }),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _exportCsv(BuildContext context, bool isHabits) async {
    final path = isHabits
        ? await BackupService().exportHabitsToCsv()
        : await BackupService().exportTasksToCsv();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported CSV to: $path')),
      );
    }
  }

  void _confirmReset(BuildContext context, WidgetRef ref, bool isOnlyStats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          isOnlyStats ? 'Reset Statistics' : 'Reset All Data',
          style: const TextStyle(color: Color(0xFFFF6B6B)),
        ),
        content: Text(
          isOnlyStats
              ? 'This will clear all Pomodoro sessions, journal entries, achievements, and mood tracker entries. Habits and tasks are kept.'
              : 'This will completely erase all databases: habits, tasks, mood tracking, pomodoros, and settings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: hapticLight(() => Navigator.pop(ctx)),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: hapticMedium(() async {
              Navigator.pop(ctx);
              if (isOnlyStats) {
                await ref.read(pomodoroRepositoryProvider).clearAll();
                await ref.read(journalRepositoryProvider).clearAll();
                await ref.read(achievementRepositoryProvider).clearAll();
                await ref.read(moodRepositoryProvider).clearAll();
                await ref.read(goalRepositoryProvider).clearAll();
                ref.read(pomodoroNotifierProvider.notifier).refresh();
                ref.read(journalNotifierProvider.notifier).refresh();
                ref.read(achievementNotifierProvider.notifier).refresh();
                ref.read(moodNotifierProvider.notifier).refresh();
                ref.read(goalNotifierProvider.notifier).refresh();
              } else {
                await ref.read(habitRepositoryProvider).clearAll();
                await ref.read(taskRepositoryProvider).clearAll();
                await ref.read(pomodoroRepositoryProvider).clearAll();
                await ref.read(journalRepositoryProvider).clearAll();
                await ref.read(achievementRepositoryProvider).clearAll();
                await ref.read(moodRepositoryProvider).clearAll();
                await ref.read(goalRepositoryProvider).clearAll();
                
                ref.read(habitNotifierProvider.notifier).refresh();
                ref.read(taskNotifierProvider.notifier).refresh();
                ref.read(pomodoroNotifierProvider.notifier).refresh();
                ref.read(journalNotifierProvider.notifier).refresh();
                ref.read(achievementNotifierProvider.notifier).refresh();
                ref.read(moodNotifierProvider.notifier).refresh();
                ref.read(goalNotifierProvider.notifier).refresh();
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selected datasets have been reset.')),
                );
              }
            }),
            child: const Text('Confirm', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Privacy Commitment'),
        content: const Text(
          '${AppStrings.appName} does not transmit any of your habits, daily reflections, schedules, pomodoros, or mood records over the network.\n\nEverything is stored securely inside an encrypted local sandbox using Hive. You own your data 100%.',
        ),
        actions: [
          TextButton(
            onPressed: hapticLight(() => Navigator.pop(ctx)),
            child: const Text('Great'),
          ),
        ],
      ),
    );
  }
}

class SystemFileMock {
  final String path;
  SystemFileMock(this.path);
  Future<String> readAsString() async {
    final file = File(path);
    return await file.readAsString();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 1.2),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingCard, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            )
          : null,
      trailing: trailing,
      onTap: hapticLight(onTap),
    );
  }
}
