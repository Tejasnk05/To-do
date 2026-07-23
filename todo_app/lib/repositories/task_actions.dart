import 'package:uuid/uuid.dart';
import '../models/recurring_task.dart';
import '../models/daily_completion.dart';
import '../models/today_goal.dart';
import '../models/normal_task.dart';
import '../utils/date_utils.dart';
import 'hive_service.dart';

const _uuid = Uuid();

/// ---------------- Everyday (recurring) tasks ----------------
class RecurringTaskActions {
  static Future<void> add(String title) async {
    final box = HiveService.recurringTasksBox;
    final order = box.values.isEmpty
        ? 0
        : (box.values.map((t) => t.order).reduce((a, b) => a > b ? a : b) + 1);
    final task = RecurringTask(
      id: _uuid.v4(),
      title: title.trim(),
      order: order,
      createdAt: DateTime.now(),
    );
    await box.put(task.id, task);
  }

  static Future<void> edit(String id, String newTitle) async {
    final box = HiveService.recurringTasksBox;
    final task = box.get(id);
    if (task != null) {
      task.title = newTitle.trim();
      await task.save();
    }
  }

  static Future<void> delete(String id) async {
    await HiveService.recurringTasksBox.delete(id);
    // Keep completion history for stats/history purposes even after
    // deletion; comment out the following if you'd rather wipe it too.
  }

  static Future<void> reorder(List<RecurringTask> currentOrder, int oldIndex, int newIndex) async {
    final list = List<RecurringTask>.from(currentOrder);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    for (var i = 0; i < list.length; i++) {
      list[i].order = i;
      await list[i].save();
    }
  }
}

/// ---------------- Daily completion (per task, per date) ----------------
class DailyCompletionActions {
  static bool isCompleted(String taskId, DateTime date) {
    final key = DailyCompletion.keyFor(taskId, dateKey(date));
    return HiveService.dailyCompletionsBox.get(key)?.completed ?? false;
  }

  static Future<void> toggle(String taskId, DateTime date) async {
    final box = HiveService.dailyCompletionsBox;
    final k = dateKey(date);
    final key = DailyCompletion.keyFor(taskId, k);
    final existing = box.get(key);
    if (existing != null) {
      existing.completed = !existing.completed;
      await existing.save();
    } else {
      await box.put(key, DailyCompletion(taskId: taskId, date: k, completed: true));
    }
  }
}

/// ---------------- Today's Goals ----------------
class TodayGoalActions {
  static Future<void> add(String title) async {
    final goal = TodayGoal(
      id: _uuid.v4(),
      title: title.trim(),
      createdAt: DateTime.now(),
      forDate: dateKey(todayDateOnly()),
    );
    await HiveService.todayGoalsBox.put(goal.id, goal);
  }

  static Future<void> edit(String id, String newTitle) async {
    final goal = HiveService.todayGoalsBox.get(id);
    if (goal != null) {
      goal.title = newTitle.trim();
      await goal.save();
    }
  }

  static Future<void> toggle(String id) async {
    final goal = HiveService.todayGoalsBox.get(id);
    if (goal != null) {
      goal.completed = !goal.completed;
      await goal.save();
    }
  }

  static Future<void> delete(String id) async {
    await HiveService.todayGoalsBox.delete(id);
  }
}

/// ---------------- Normal (one-time) tasks ----------------
class NormalTaskActions {
  static Future<void> add(String title, String description) async {
    final box = HiveService.normalTasksBox;
    final order = box.values.isEmpty
        ? 0
        : (box.values.map((t) => t.order).reduce((a, b) => a > b ? a : b) + 1);
    final task = NormalTask(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      order: order,
      createdAt: DateTime.now(),
    );
    await box.put(task.id, task);
  }

  static Future<void> edit(String id, String title, String description) async {
    final task = HiveService.normalTasksBox.get(id);
    if (task != null) {
      task.title = title.trim();
      task.description = description.trim();
      await task.save();
    }
  }

  static Future<void> toggleStatus(String id) async {
    final task = HiveService.normalTasksBox.get(id);
    if (task != null) {
      if (task.status == TaskStatus.pending) {
        task.status = TaskStatus.completed;
        task.completedAt = DateTime.now();
      } else {
        task.status = TaskStatus.pending;
        task.completedAt = null;
      }
      await task.save();
    }
  }

  static Future<void> delete(String id) async {
    await HiveService.normalTasksBox.delete(id);
  }

  static Future<void> reorder(List<NormalTask> currentOrder, int oldIndex, int newIndex) async {
    final list = List<NormalTask>.from(currentOrder);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    for (var i = 0; i < list.length; i++) {
      list[i].order = i;
      await list[i].save();
    }
  }

  static NormalTask restore(NormalTask deletedCopy) => deletedCopy;
}
