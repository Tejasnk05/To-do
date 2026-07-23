import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/normal_task.dart';
import '../providers/app_providers.dart';
import '../repositories/hive_service.dart';
import '../repositories/task_actions.dart';
import '../widgets/add_edit_dialog.dart';

class NormalTasksScreen extends ConsumerWidget {
  const NormalTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = ref.watch(normalTasksBoxProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Normal Tasks')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<NormalTask> b, _) {
          final tasks = b.values.toList()..sort((a, c) => a.order.compareTo(c.order));
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('No one-time tasks yet'),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: tasks.length,
            onReorder: (oldIndex, newIndex) => NormalTaskActions.reorder(tasks, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: ValueKey(task.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async => true,
                onDismissed: (_) => _deleteWithUndo(context, task),
                child: _NormalTaskTile(task: task),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showTitleDescriptionDialog(context, heading: 'New task');
          if (result != null) {
            await NormalTaskActions.add(result['title']!, result['description'] ?? '');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteWithUndo(BuildContext context, NormalTask task) async {
    // Snapshot the fields before deleting so we can restore them.
    final snapshot = NormalTask(
      id: task.id,
      title: task.title,
      description: task.description,
      order: task.order,
      createdAt: task.createdAt,
      completedAt: task.completedAt,
      status: task.status,
    );
    await NormalTaskActions.delete(task.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${snapshot.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await HiveService.normalTasksBox.put(snapshot.id, snapshot);
          },
        ),
      ),
    );
  }
}

class _NormalTaskTile extends StatelessWidget {
  final NormalTask task;
  const _NormalTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDone = task.status == TaskStatus.completed;
    return Card(
      color: isDone ? scheme.primaryContainer.withOpacity(0.55) : null,
      child: ListTile(
        onTap: () => NormalTaskActions.toggleStatus(task.id),
        leading: Checkbox(
          value: isDone,
          onChanged: (_) => NormalTaskActions.toggleStatus(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: isDone ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            Text(
              isDone && task.completedAt != null
                  ? 'Created ${DateFormat('d MMM').format(task.createdAt)} · Completed ${DateFormat('d MMM').format(task.completedAt!)}'
                  : 'Created ${DateFormat('d MMM yyyy').format(task.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        isThreeLine: task.description.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () async {
                final result = await showTitleDescriptionDialog(
                  context,
                  heading: 'Edit task',
                  initialTitle: task.title,
                  initialDescription: task.description,
                );
                if (result != null) {
                  await NormalTaskActions.edit(task.id, result['title']!, result['description'] ?? '');
                }
              },
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }
}
