import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_shell.dart';
import '../screens/everyday_tasks_screen.dart';
import '../screens/weekly_dashboard_screen.dart';
import '../screens/todays_goals_screen.dart';
import '../screens/monthly_dashboard_screen.dart';
import '../screens/normal_tasks_screen.dart';
import '../screens/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/everyday',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKey,
          routes: [
            GoRoute(path: '/everyday', builder: (c, s) => const EverydayTasksScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/weekly', builder: (c, s) => const WeeklyDashboardScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/today', builder: (c, s) => const TodaysGoalsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/monthly', builder: (c, s) => const MonthlyDashboardScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/normal', builder: (c, s) => const NormalTasksScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (c, s) => const SettingsScreen(),
    ),
  ],
);
