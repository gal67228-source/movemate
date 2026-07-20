import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../moves/data/move_repository.dart';
import '../../packing/data/packing_repository.dart';
import '../../packing/domain/packing_models.dart';
import '../../sales/data/sale_repository.dart';
import '../../shopping/data/shopping_repository.dart';
import '../../tasks/data/task_repository.dart';
import '../domain/smart_move_models.dart';

final smartMoveSummaryProvider = FutureProvider<SmartMoveSummary>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) {
    return const SmartMoveSummary(
      daysUntilMove: 0,
      readiness: 0,
      taskProgress: 0,
      packingProgress: 0,
      boxProgress: 0,
      shoppingProgress: 0,
      saleProgress: 0,
      upcomingTasks: [],
      remainingByRoom: [],
      insights: [],
    );
  }

  final tasks = await ref.watch(tasksProvider.future);
  final taskStats = await ref.watch(taskStatsProvider.future);
  final rooms = await ref.watch(roomsProvider.future);
  final items = await ref.watch(packingItemsProvider.future);
  final packingStats = await ref.watch(packingStatsProvider.future);
  final shoppingStats = await ref.watch(shoppingStatsProvider.future);
  final saleStats = await ref.watch(saleStatsProvider.future);

  final roomNames = {for (final room in rooms) room.id: room.name};
  final remaining = items.where((item) {
    return item.destination == ItemDestination.moving &&
        item.status == PackingStatus.atHome;
  }).toList();

  final grouped = <String, List<PackingItem>>{};
  for (final item in remaining) {
    grouped.putIfAbsent(item.roomId, () => []).add(item);
  }
  final remainingByRoom = grouped.entries.map((entry) {
    final list = entry.value..sort((a, b) => a.name.compareTo(b.name));
    return RoomRemainingItems(
      roomName: roomNames[entry.key] ?? 'חדר אחר',
      items: list,
    );
  }).toList()
    ..sort((a, b) => b.items.length.compareTo(a.items.length));

  final now = DateTime.now();
  final openTasks = tasks.where((task) => !task.isCompleted).toList()
    ..sort((a, b) {
      final aDate = a.dueDate ?? DateTime(9999);
      final bDate = b.dueDate ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });

  final componentValues = <double>[
    taskStats.progress,
    packingStats.progress,
    packingStats.boxProgress,
    shoppingStats.progress,
    if (saleStats.totalItems > 0) saleStats.progress,
  ];
  final readiness = calculateReadiness(componentValues);
  final days = DateTime(
    move.moveDate.year,
    move.moveDate.month,
    move.moveDate.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;

  final insights = <String>[];
  final remainingUnits = remaining.fold<int>(0, (sum, item) => sum + item.quantity);
  if (remainingUnits > 0) {
    insights.add('נשארו $remainingUnits פריטים שלא נארזו.');
  }
  final overdue = openTasks.where((task) => task.dueDate != null && task.dueDate!.isBefore(now)).length;
  if (overdue > 0) {
    insights.add('יש $overdue משימות באיחור.');
  }
  if (packingStats.boxes == 0 && items.isNotEmpty) {
    insights.add('עדיין לא נוצרו ארגזים לציוד שבחרת.');
  }
  if (shoppingStats.total > shoppingStats.purchased) {
    insights.add('נשארו ${shoppingStats.total - shoppingStats.purchased} פריטים לקנייה.');
  }
  if (insights.isEmpty) {
    insights.add('המעבר מתקדם היטב. המשך כך!');
  }

  return SmartMoveSummary(
    daysUntilMove: days,
    readiness: readiness,
    taskProgress: taskStats.progress,
    packingProgress: packingStats.progress,
    boxProgress: packingStats.boxProgress,
    shoppingProgress: shoppingStats.progress,
    saleProgress: saleStats.progress,
    upcomingTasks: openTasks.take(8).toList(),
    remainingByRoom: remainingByRoom,
    insights: insights,
  );
});
