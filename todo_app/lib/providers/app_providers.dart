import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/recurring_task.dart';
import '../models/daily_completion.dart';
import '../models/today_goal.dart';
import '../models/normal_task.dart';
import '../repositories/hive_service.dart';

/// Boxes are exposed as simple Providers. Widgets listen to
/// `box.listenable()` via ValueListenableBuilder, which is the
/// idiomatic way to get live-updating UI straight from Hive without
/// duplicating state inside Riverpod notifiers.
final recurringTasksBoxProvider =
    Provider<Box<RecurringTask>>((ref) => HiveService.recurringTasksBox);

final dailyCompletionsBoxProvider =
    Provider<Box<DailyCompletion>>((ref) => HiveService.dailyCompletionsBox);

final todayGoalsBoxProvider =
    Provider<Box<TodayGoal>>((ref) => HiveService.todayGoalsBox);

final normalTasksBoxProvider =
    Provider<Box<NormalTask>>((ref) => HiveService.normalTasksBox);

/// Which week is currently shown on the Weekly Dashboard (any date within it).
final weeklyDashboardAnchorProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Which month is currently shown on the Monthly Dashboard.
final monthlyDashboardAnchorProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadInitial());

  static ThemeMode _loadInitial() {
    final saved = HiveService.settingsBox.get('themeMode') as String?;
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    HiveService.settingsBox.put('themeMode', next == ThemeMode.dark ? 'dark' : 'light');
  }
}
