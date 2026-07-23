import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/recurring_task.dart';
import '../providers/app_providers.dart';
import '../repositories/task_actions.dart';
import '../utils/date_utils.dart' as du;

class WeeklyDashboardScreen extends ConsumerWidget {
  const WeeklyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchor = ref.watch(weeklyDashboardAnchorProvider);
    final tasksBox = ref.watch(recurringTasksBoxProvider);
    final completionsBox = ref.watch(dailyCompletionsBoxProvider);
    final days = du.weekdaysMonToSat(anchor);
    final dayLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Dashboard'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref.read(weeklyDashboardAnchorProvider.notifier).state =
                      anchor.subtract(const Duration(days: 7)),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Week ${du.isoWeekNumber(anchor)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(du.weekRangeLabel(anchor),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => ref.read(weeklyDashboardAnchorProvider.notifier).state =
                      anchor.add(const Duration(days: 7)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: tasksBox.listenable(),
              builder: (context, Box<RecurringTask> box, _) {
                final tasks = box.values.toList()..sort((a, b) => a.order.compareTo(b.order));
                if (tasks.isEmpty) {
                  return const Center(child: Text('Add everyday tasks first to see them here.'));
                }
                return ValueListenableBuilder(
                  valueListenable: completionsBox.listenable(),
                  builder: (context, __, ___) {
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(6, (i) {
                                    final day = days[i];
                                    final done = DailyCompletionActions.isCompleted(task.id, day);
                                    final isFuture = day.isAfter(du.todayDateOnly());
                                    return Column(
                                      children: [
                                        Text(dayLabels[i], style: Theme.of(context).textTheme.labelSmall),
                                        const SizedBox(height: 4),
                                        Icon(
                                          done
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          size: 22,
                                          color: done
                                              ? Theme.of(context).colorScheme.primary
                                              : isFuture
                                                  ? Theme.of(context).colorScheme.outlineVariant
                                                  : Theme.of(context).colorScheme.outline,
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
