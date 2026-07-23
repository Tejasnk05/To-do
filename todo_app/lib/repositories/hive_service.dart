import 'package:hive_flutter/hive_flutter.dart';
import '../models/recurring_task.dart';
import '../models/daily_completion.dart';
import '../models/today_goal.dart';
import '../models/normal_task.dart';

class HiveBoxes {
  static const recurringTasks = 'recurring_tasks';
  static const dailyCompletions = 'daily_completions';
  static const todayGoals = 'today_goals';
  static const normalTasks = 'normal_tasks';
  static const settings = 'settings';
}

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(RecurringTaskAdapter());
    Hive.registerAdapter(DailyCompletionAdapter());
    Hive.registerAdapter(TodayGoalAdapter());
    Hive.registerAdapter(NormalTaskAdapter());

    await Future.wait([
      Hive.openBox<RecurringTask>(HiveBoxes.recurringTasks),
      Hive.openBox<DailyCompletion>(HiveBoxes.dailyCompletions),
      Hive.openBox<TodayGoal>(HiveBoxes.todayGoals),
      Hive.openBox<NormalTask>(HiveBoxes.normalTasks),
      Hive.openBox(HiveBoxes.settings),
    ]);
  }

  static Box<RecurringTask> get recurringTasksBox =>
      Hive.box<RecurringTask>(HiveBoxes.recurringTasks);

  static Box<DailyCompletion> get dailyCompletionsBox =>
      Hive.box<DailyCompletion>(HiveBoxes.dailyCompletions);

  static Box<TodayGoal> get todayGoalsBox =>
      Hive.box<TodayGoal>(HiveBoxes.todayGoals);

  static Box<NormalTask> get normalTasksBox =>
      Hive.box<NormalTask>(HiveBoxes.normalTasks);

  static Box get settingsBox => Hive.box(HiveBoxes.settings);
}
