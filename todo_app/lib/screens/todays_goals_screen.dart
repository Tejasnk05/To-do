import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/today_goal.dart';
import '../providers/app_providers.dart';
import '../repositories/task_actions.dart';
import '../utils/date_utils.dart';
import '../widgets/add_edit_dialog.dart';

class TodaysGoalsScreen extends ConsumerWidget {
  const TodaysGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = ref.watch(todayGoalsBoxProvider);
    final today = dateKey(todayDateOnly());

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Goals")),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<TodayGoal> b, _) {
          final all = b.values.where((g) => g.forDate == today).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          final pending = all.where((g) => !g.completed).toList();
          final completed = all.where((g) => g.completed).toList();

          if (all.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text("No goals for today yet"),
                  const SizedBox(height: 4),
                  Text("Add temporary goals just for today", style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              ...pending.map((g) => _GoalTile(goal: g)),
              if (completed.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text('Completed Today',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                ...completed.map((g) => _GoalTile(goal: g)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final title = await showTitleDialog(context, heading: "New goal for today", hint: 'e.g. Finish report');
          if (title != null) await TodayGoalActions.add(title);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final TodayGoal goal;
  const _GoalTile({required this.goal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: goal.completed ? scheme.primaryContainer.withOpacity(0.55) : null,
      child: ListTile(
        onTap: () => TodayGoalActions.toggle(goal.id),
        leading: Checkbox(
          value: goal.completed,
          onChanged: (_) => TodayGoalActions.toggle(goal.id),
        ),
        title: Text(
          goal.title,
          style: TextStyle(decoration: goal.completed ? TextDecoration.lineThrough : null),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () async {
                final title = await showTitleDialog(context, heading: 'Edit goal', initialValue: goal.title);
                if (title != null) await TodayGoalActions.edit(goal.id, title);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => TodayGoalActions.delete(goal.id),
            ),
          ],
        ),
      ),
    );
  }
}
