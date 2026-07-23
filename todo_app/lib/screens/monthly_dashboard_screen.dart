import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/recurring_task.dart';
import '../models/normal_task.dart';
import '../models/today_goal.dart';
import '../providers/app_providers.dart';
import '../repositories/task_actions.dart';
import '../utils/date_utils.dart' as du;
import '../widgets/month_year_picker.dart';

class MonthlyDashboardScreen extends ConsumerWidget {
  const MonthlyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchor = ref.watch(monthlyDashboardAnchorProvider);
    final tasksBox = ref.watch(recurringTasksBoxProvider);
    final completionsBox = ref.watch(dailyCompletionsBoxProvider);
    final normalBox = ref.watch(normalTasksBoxProvider);
    final goalsBox = ref.watch(todayGoalsBoxProvider);
    final elapsedDays = du.elapsedDaysOfMonth(anchor.year, anchor.month);
    final monthPrefix = DateFormat('yyyy-MM').format(anchor);
    final now = DateTime.now();
    final isCurrentOrFutureMonth = anchor.year > now.year ||
        (anchor.year == now.year && anchor.month >= now.month);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Dashboard')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref.read(monthlyDashboardAnchorProvider.notifier).state =
                      DateTime(anchor.year, anchor.month - 1, 1),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await showMonthYearPicker(context, initial: anchor);
                      if (picked != null) {
                        ref.read(monthlyDashboardAnchorProvider.notifier).state = picked;
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(anchor),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: isCurrentOrFutureMonth
                      ? null
                      : () => ref.read(monthlyDashboardAnchorProvider.notifier).state =
                          DateTime(anchor.year, anchor.month + 1, 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: tasksBox.listenable(),
              builder: (context, Box<RecurringTask> rBox, _) {
                return ValueListenableBuilder(
                  valueListenable: completionsBox.listenable(),
                  builder: (context, __, ___) {
                    return ValueListenableBuilder(
                      valueListenable: normalBox.listenable(),
                      builder: (context, Box<NormalTask> nBox, ____) {
                        return ValueListenableBuilder(
                          valueListenable: goalsBox.listenable(),
                          builder: (context, Box<TodayGoal> gBox, _____) {
                            final tasks = rBox.values.toList()..sort((a, b) => a.order.compareTo(b.order));

                            final normalCompletedThisMonth = nBox.values
                                .where((t) =>
                                    t.status == TaskStatus.completed &&
                                    t.completedAt != null &&
                                    t.completedAt!.year == anchor.year &&
                                    t.completedAt!.month == anchor.month)
                                .toList()
                              ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

                            final goalsCompletedThisMonth = gBox.values
                                .where((g) => g.completed && g.forDate.startsWith(monthPrefix))
                                .toList()
                              ..sort((a, b) => b.forDate.compareTo(a.forDate));

                            int totalCompletedAllTasks = 0;
                            int totalPossibleAllTasks = 0;
                            final rows = tasks.map((task) {
                              final completedDays = elapsedDays
                                  .where((d) => DailyCompletionActions.isCompleted(task.id, d))
                                  .length;
                              totalCompletedAllTasks += completedDays;
                              totalPossibleAllTasks += elapsedDays.length;
                              return _TaskStat(task: task, completed: completedDays, total: elapsedDays.length);
                            }).toList();

                            final overallPct = totalPossibleAllTasks == 0
                                ? 0.0
                                : totalCompletedAllTasks / totalPossibleAllTasks;

                            return ListView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              children: [
                                if (tasks.isNotEmpty) ...[
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Total recurring tasks', style: Theme.of(context).textTheme.bodySmall),
                                                Text('${tasks.length}',
                                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Overall completion', style: Theme.of(context).textTheme.bodySmall),
                                                Text('${(overallPct * 100).round()}%',
                                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...rows.map((r) => _MonthlyTaskCard(stat: r)),
                                  const SizedBox(height: 20),
                                ] else
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(child: Text('Add everyday tasks first to see stats here.')),
                                  ),

                                _SectionHeader(
                                  title: 'One-time tasks completed',
                                  count: normalCompletedThisMonth.length,
                                ),
                                if (normalCompletedThisMonth.isEmpty)
                                  _EmptyRow(text: 'Nothing completed this month')
                                else
                                  ...normalCompletedThisMonth.map((t) => Card(
                                        child: ListTile(
                                          leading: const Icon(Icons.check_circle, color: Colors.green),
                                          title: Text(t.title),
                                          subtitle: Text('Completed ${DateFormat('d MMM yyyy').format(t.completedAt!)}'),
                                        ),
                                      )),
                                const SizedBox(height: 20),

                                _SectionHeader(
                                  title: "Today's Goals completed",
                                  count: goalsCompletedThisMonth.length,
                                ),
                                if (goalsCompletedThisMonth.isEmpty)
                                  _EmptyRow(text: 'No goals completed this month')
                                else
                                  ...goalsCompletedThisMonth.map((g) => Card(
                                        child: ListTile(
                                          leading: const Icon(Icons.flag, color: Colors.orange),
                                          title: Text(g.title),
                                          subtitle: Text(DateFormat('d MMM yyyy').format(DateTime.parse(g.forDate))),
                                        ),
                                      )),
                              ],
                            );
                          },
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text('$count', style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;
  const _EmptyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

class _TaskStat {
  final RecurringTask task;
  final int completed;
  final int total;
  _TaskStat({required this.task, required this.completed, required this.total});
  double get pct => total == 0 ? 0 : completed / total;
}

class _MonthlyTaskCard extends StatelessWidget {
  final _TaskStat stat;
  const _MonthlyTaskCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final pct = stat.pct;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(stat.task.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('${(pct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text('${stat.completed} / ${stat.total} days',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
