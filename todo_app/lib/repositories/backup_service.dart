import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/recurring_task.dart';
import '../models/daily_completion.dart';
import '../models/today_goal.dart';
import '../models/normal_task.dart';
import 'hive_service.dart';

/// Reads/writes every box into a single portable JSON document, so the
/// whole app's data can be backed up to a file and restored later
/// (including on a different device).
class BackupService {
  static const _formatVersion = 1;

  static Map<String, dynamic> _buildSnapshot() {
    final recurring = HiveService.recurringTasksBox.values
        .map((t) => {
              'id': t.id,
              'title': t.title,
              'order': t.order,
              'createdAt': t.createdAt.toIso8601String(),
              'colorValue': t.colorValue,
            })
        .toList();

    final completions = HiveService.dailyCompletionsBox.values
        .map((c) => {
              'taskId': c.taskId,
              'date': c.date,
              'completed': c.completed,
            })
        .toList();

    final goals = HiveService.todayGoalsBox.values
        .map((g) => {
              'id': g.id,
              'title': g.title,
              'createdAt': g.createdAt.toIso8601String(),
              'forDate': g.forDate,
              'completed': g.completed,
            })
        .toList();

    final normal = HiveService.normalTasksBox.values
        .map((t) => {
              'id': t.id,
              'title': t.title,
              'description': t.description,
              'order': t.order,
              'createdAt': t.createdAt.toIso8601String(),
              'completedAt': t.completedAt?.toIso8601String(),
              'status': t.status.index,
            })
        .toList();

    return {
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'recurringTasks': recurring,
      'dailyCompletions': completions,
      'todayGoals': goals,
      'normalTasks': normal,
    };
  }

  static String exportToJsonString() {
    return const JsonEncoder.withIndent('  ').convert(_buildSnapshot());
  }

  /// Writes the export to a file in the app's temp/documents directory and
  /// returns the file so it can be shared (e.g. via share_plus).
  static Future<File> exportToFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/daily_todo_backup_$stamp.json');
    await file.writeAsString(exportToJsonString());
    return file;
  }

  /// Replaces ALL current data with what's in [jsonStr]. Throws
  /// [FormatException] if the content isn't a recognizable backup.
  static Future<void> importFromJsonString(String jsonStr) async {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic> || !decoded.containsKey('formatVersion')) {
      throw const FormatException('This file is not a valid Daily To-Do backup.');
    }

    final recurringBox = HiveService.recurringTasksBox;
    final completionsBox = HiveService.dailyCompletionsBox;
    final goalsBox = HiveService.todayGoalsBox;
    final normalBox = HiveService.normalTasksBox;

    await recurringBox.clear();
    await completionsBox.clear();
    await goalsBox.clear();
    await normalBox.clear();

    for (final r in (decoded['recurringTasks'] as List? ?? [])) {
      final m = r as Map<String, dynamic>;
      final task = RecurringTask(
        id: m['id'] as String,
        title: m['title'] as String,
        order: m['order'] as int,
        createdAt: DateTime.parse(m['createdAt'] as String),
        colorValue: m['colorValue'] as int? ?? 0xFF6C63FF,
      );
      await recurringBox.put(task.id, task);
    }

    for (final c in (decoded['dailyCompletions'] as List? ?? [])) {
      final m = c as Map<String, dynamic>;
      final completion = DailyCompletion(
        taskId: m['taskId'] as String,
        date: m['date'] as String,
        completed: m['completed'] as bool,
      );
      await completionsBox.put(DailyCompletion.keyFor(completion.taskId, completion.date), completion);
    }

    for (final g in (decoded['todayGoals'] as List? ?? [])) {
      final m = g as Map<String, dynamic>;
      final goal = TodayGoal(
        id: m['id'] as String,
        title: m['title'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        forDate: m['forDate'] as String,
        completed: m['completed'] as bool? ?? false,
      );
      await goalsBox.put(goal.id, goal);
    }

    for (final t in (decoded['normalTasks'] as List? ?? [])) {
      final m = t as Map<String, dynamic>;
      final task = NormalTask(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String? ?? '',
        order: m['order'] as int,
        createdAt: DateTime.parse(m['createdAt'] as String),
        completedAt: m['completedAt'] != null ? DateTime.parse(m['completedAt'] as String) : null,
        status: TaskStatus.values[m['status'] as int? ?? 0],
      );
      await normalBox.put(task.id, task);
    }
  }
}
