import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/shell_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/habits/habits_screen.dart';
import '../../presentation/screens/habits/add_edit_habit_screen.dart';
import '../../presentation/screens/tasks/tasks_screen.dart';
import '../../presentation/screens/tasks/add_edit_task_screen.dart';
import '../../presentation/screens/analytics/analytics_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/pomodoro/pomodoro_screen.dart';
import '../../presentation/screens/mood/mood_tracker_screen.dart';
import '../../presentation/screens/journal/journal_screen.dart';
import '../../presentation/screens/journal/journal_entry_screen.dart';
import '../../presentation/screens/timeline/timeline_screen.dart';
import '../../presentation/screens/achievements/achievements_screen.dart';
import '../../presentation/screens/goals/goals_screen.dart';
import '../../presentation/screens/goals/add_edit_goal_screen.dart';
import '../../presentation/screens/special_days/special_days_screen.dart';
import '../../presentation/screens/special_days/add_edit_special_day_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/habits',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HabitsScreen(),
            ),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TasksScreen(),
            ),
          ),
          GoRoute(
            path: '/notes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JournalScreen(),
            ),
          ),
          GoRoute(
            path: '/special-days',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SpecialDaysScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
        ],
      ),
      // Modal routes (outside shell)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/habits/add',
        builder: (context, state) => const AddEditHabitScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/habits/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditHabitScreen(habitId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tasks/add',
        builder: (context, state) => const AddEditTaskScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tasks/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditTaskScreen(taskId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/pomodoro',
        builder: (context, state) => const PomodoroScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/mood',
        builder: (context, state) => const MoodTrackerScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/journal/write',
        builder: (context, state) => const JournalEntryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/journal/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return JournalEntryScreen(entryId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/timeline',
        builder: (context, state) => const TimelineScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/goals/add',
        builder: (context, state) => const AddEditGoalScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/special-days/add',
        builder: (context, state) => const AddEditSpecialDayScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/special-days/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditSpecialDayScreen(specialDayId: id);
        },
      ),
    ],
  );
});
