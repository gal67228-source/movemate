import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../moves/data/move_repository.dart';
import '../../tasks/data/task_repository.dart';
import '../data/smart_move_provider.dart';

class SmartMoveScreen extends ConsumerStatefulWidget {
  const SmartMoveScreen({super.key});

  @override
  ConsumerState<SmartMoveScreen> createState() => _SmartMoveScreenState();
}

class _SmartMoveScreenState extends ConsumerState<SmartMoveScreen> {
  bool _addingRecommendations = false;

  Future<void> _addRecommendations() async {
    final move = await ref.read(currentMoveProvider.future);
    if (move == null) {
      return;
    }
    setState(() => _addingRecommendations = true);
    final repository = await ref.read(taskRepositoryProvider.future);
    final added = await repository.addMissingRecommendations(
      moveId: move.id,
      moveDate: move.moveDate,
    );
    ref.invalidate(tasksProvider);
    ref.invalidate(taskStatsProvider);
    ref.invalidate(smartMoveSummaryProvider);
    if (!mounted) {
      return;
    }
    setState(() => _addingRecommendations = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == 0 ? 'כל המשימות המומלצות כבר קיימות' : 'נוספו $added משימות מומלצות',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(smartMoveSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('תוכנית המעבר')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('לא ניתן לטעון: $error')),
        data: (summary) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(smartMoveSummaryProvider);
            await ref.read(smartMoveSummaryProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        summary.daysUntilMove < 0
                            ? 'עברו ${summary.daysUntilMove.abs()} ימים מהמעבר'
                            : summary.daysUntilMove == 0
                                ? 'היום עוברים!'
                                : 'עוד ${summary.daysUntilMove} ימים למעבר',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: summary.readiness,
                                strokeWidth: 12,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${summary.readinessPercent}%',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const Text('מוכנות'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ProgressRow(label: 'משימות', value: summary.taskProgress),
                      _ProgressRow(label: 'אריזה', value: summary.packingProgress),
                      _ProgressRow(label: 'ארגזים', value: summary.boxProgress),
                      _ProgressRow(label: 'קניות', value: summary.shoppingProgress),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('מה דורש תשומת לב', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...summary.insights.map(
                (insight) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline_rounded),
                    title: Text(insight),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text('ציר זמן', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  TextButton.icon(
                    onPressed: _addingRecommendations ? null : _addRecommendations,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('השלם מומלצות'),
                  ),
                ],
              ),
              if (summary.upcomingTasks.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.task_alt_rounded),
                    title: Text('אין משימות פתוחות'),
                  ),
                )
              else
                ...summary.upcomingTasks.map(
                  (task) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_note_rounded),
                      title: Text(task.title),
                      subtitle: Text(
                        task.dueDate == null
                            ? 'ללא תאריך'
                            : DateFormat('dd/MM/yyyy').format(task.dueDate!),
                      ),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => context.push('/tasks/edit?id=${task.id}'),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text('מה עדיין לא נארז', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  Text('${summary.remainingItems} פריטים'),
                ],
              ),
              const SizedBox(height: 8),
              if (summary.remainingByRoom.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.inventory_2_rounded),
                    title: Text('כל הציוד שנבחר כבר נארז'),
                  ),
                )
              else
                ...summary.remainingByRoom.map(
                  (room) => Card(
                    child: ExpansionTile(
                      title: Text(room.roomName),
                      subtitle: Text('${room.items.length} סוגי פריטים'),
                      children: room.items
                          .map(
                            (item) => ListTile(
                              title: Text(item.quantity > 1 ? '${item.name} ×${item.quantity}' : item.name),
                              trailing: const Icon(Icons.chevron_left_rounded),
                              onTap: () => context.push('/rooms/${item.roomId}'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          SizedBox(width: 66, child: Text(label)),
          Expanded(child: LinearProgressIndicator(value: value)),
          const SizedBox(width: 10),
          SizedBox(width: 40, child: Text('${(value * 100).round()}%')),
        ],
      ),
    );
  }
}
