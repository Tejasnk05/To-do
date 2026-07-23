import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/recurring_task.dart';
import '../providers/app_providers.dart';
import '../repositories/task_actions.dart';
import '../utils/date_utils.dart';
import '../widgets/add_edit_dialog.dart';

class EverydayTasksScreen extends ConsumerWidget {
  const EverydayTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksBox = ref.watch(recurringTasksBoxProvider);
    final completionsBox = ref.watch(dailyCompletionsBoxProvider);
    final today = todayDateOnly();

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE').format(today), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('d MMMM yyyy').format(today),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: tasksBox.listenable(),
        builder: (context, Box<RecurringTask> box, _) {
          final tasks = box.values.toList()..sort((a, b) => a.order.compareTo(b.order));
          if (tasks.isEmpty) {
            return _EmptyState(onAdd: () => _addTask(context));
          }
          return ValueListenableBuilder(
            valueListenable: completionsBox.listenable(),
            builder: (context, __, ___) {
              return ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: tasks.length,
                onReorder: (oldIndex, newIndex) =>
                    RecurringTaskActions.reorder(tasks, oldIndex, newIndex),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final done = DailyCompletionActions.isCompleted(task.id, today);
                  return _EverydayTaskTile(
                    key: ValueKey(task.id),
                    task: task,
                    completed: done,
                    onToggle: () => DailyCompletionActions.toggle(task.id, today),
                    onEdit: () => _editTask(context, task),
                    onDelete: () => _confirmDelete(context, task),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addTask(BuildContext context) async {
    final title = await showTitleDialog(context, heading: 'New everyday task', hint: 'e.g. Morning workout');
    if (title != null) await RecurringTaskActions.add(title);
  }

  Future<void> _editTask(BuildContext context, RecurringTask task) async {
    final title = await showTitleDialog(context, heading: 'Edit task', initialValue: task.title);
    if (title != null) await RecurringTaskActions.edit(task.id, title);
  }

  Future<void> _confirmDelete(BuildContext context, RecurringTask task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await RecurringTaskActions.delete(task.id);
  }
}

class _EverydayTaskTile extends StatelessWidget {
  final RecurringTask task;
  final bool completed;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EverydayTaskTile({
    super.key,
    required this.task,
    required this.completed,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: completed ? scheme.primaryContainer.withOpacity(0.55) : null,
      child: ListTile(
        onTap: onToggle,
        leading: Checkbox(
          value: completed,
          onChanged: (_) => onToggle(),
          shape: const CircleBorder(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: completed ? TextDecoration.lineThrough : null,
            color: completed ? scheme.onSurfaceVariant : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: onDelete),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rtl, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          const Text('No everyday tasks yet'),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add your first task')),
        ],
      ),
    );
  }
}
