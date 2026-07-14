import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../moves/data/move_repository.dart';
import '../packing/data/packing_repository.dart';
import '../tasks/data/task_repository.dart';
import '../../shared/widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moveAsync = ref.watch(currentMoveProvider);
    final statsAsync = ref.watch(taskStatsProvider);
    final packingStatsAsync = ref.watch(packingStatsProvider);
    final actions = <({String title, IconData icon, String? route})>[
      (title: 'משימות', icon: Icons.checklist_rounded, route: '/tasks'),
      (title: 'ארגזים', icon: Icons.inventory_2_outlined, route: '/boxes'),
      (title: 'חדרים', icon: Icons.meeting_room_outlined, route: '/rooms'),
      (title: 'ציוד', icon: Icons.category_outlined, route: '/packing-items'),
      (title: 'קניות', icon: Icons.shopping_cart_outlined, route: null),
      (title: 'תקציב', icon: Icons.account_balance_wallet_outlined, route: null),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('MoveMate')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentMoveProvider);
          ref.invalidate(tasksProvider);
          ref.invalidate(taskStatsProvider);
          ref.invalidate(packingItemsProvider);
          ref.invalidate(movingBoxesProvider);
          ref.invalidate(packingStatsProvider);
          await ref.read(taskStatsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            moveAsync.when(
              data: (move) {
                if (move == null) return const SizedBox.shrink();
                final days = move.moveDate.difference(DateTime.now()).inDays;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(move.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(days <= 0 ? 'יום המעבר הגיע!' : 'נותרו $days ימים למעבר'),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('שגיאה: $error'),
            ),
            const SizedBox(height: 18),
            statsAsync.when(
              data: (stats) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('התקדמות במשימות', style: Theme.of(context).textTheme.titleMedium),
                          Text('${(stats.progress * 100).round()}%'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: stats.progress, minHeight: 10, borderRadius: const BorderRadius.all(Radius.circular(20))),
                      const SizedBox(height: 10),
                      Text(stats.total == 0 ? 'הוסף משימה ראשונה' : 'עוד צעד אחד לבית החדש!'),
                    ],
                  ),
                ),
              ),
              loading: () => const Card(child: Padding(padding: EdgeInsets.all(24), child: LinearProgressIndicator())),
              error: (error, stackTrace) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('לא ניתן לטעון משימות: $error'))),
            ),
            const SizedBox(height: 16),
            packingStatsAsync.when(
              data: (stats) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'התקדמות באריזה',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('${(stats.progress * 100).round()}%'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: stats.progress,
                        minHeight: 10,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${stats.packedItems} מתוך ${stats.totalItems} פריטים נארזו · '
                        '${stats.closedBoxes} מתוך ${stats.boxes} ארגזים נסגרו',
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 136,
              child: statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.75,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(icon: Icons.pending_actions_rounded, value: '${stats.open}', label: 'משימות פתוחות'),
                    StatCard(icon: Icons.task_alt_rounded, value: '${stats.completed}', label: 'הושלמו'),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 18),
            Text('גישה מהירה', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemBuilder: (context, index) {
                final action = actions[index];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: action.route == null ? null : () => context.push(action.route!),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(action.icon, size: 30), const SizedBox(height: 8), Text(action.title)]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/tasks/edit'), icon: const Icon(Icons.add), label: const Text('משימה חדשה')),
    );
  }
}
