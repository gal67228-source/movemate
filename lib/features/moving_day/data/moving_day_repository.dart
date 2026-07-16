import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../moves/data/move_repository.dart';
import '../../packing/data/packing_repository.dart';
import '../../packing/domain/packing_models.dart';
import '../../tasks/data/task_repository.dart';
import '../domain/moving_day_models.dart';

const _movingDayItemsKey = 'moving_day_items';

class MovingDayRepository {
  MovingDayRepository(this._storage);

  final LocalStorage _storage;

  List<MovingDayItem> getItems(String moveId) {
    return _storage
        .readObjectList(_movingDayItemsKey)
        .map(MovingDayItem.fromJson)
        .where((item) => item.moveId == moveId)
        .toList();
  }

  Future<void> seedDefaults(String moveId) async {
    if (getItems(moveId).isNotEmpty) {
      return;
    }
    const defaults = <String>[
      'מפתחות',
      'ארנק ותעודות',
      'מסמכים חשובים',
      'תרופות',
      'טלפונים ומטענים',
      'מים ואוכל לדרך',
      'תיק ליום הראשון',
      'ציוד ניקיון בסיסי',
      'כלי עבודה בסיסיים',
      'מפתחות הדירה החדשה',
      'קריאת מוני חשמל ומים',
      'בדיקה אחרונה של כל החדרים',
    ];
    final now = DateTime.now();
    for (var index = 0; index < defaults.length; index++) {
      await upsert(
        MovingDayItem(
          id: 'moving_day_${moveId}_$index',
          moveId: moveId,
          title: defaults[index],
          status: MovingDayItemStatus.waiting,
          createdAt: now,
        ),
      );
    }
  }

  Future<void> upsert(MovingDayItem item) async {
    final all = _storage
        .readObjectList(_movingDayItemsKey)
        .map(MovingDayItem.fromJson)
        .toList();
    final index = all.indexWhere((value) => value.id == item.id);
    if (index == -1) {
      all.add(item);
    } else {
      all[index] = item;
    }
    await _storage.writeObjectList(
      _movingDayItemsKey,
      all.map((value) => value.toJson()).toList(),
    );
  }

  Future<void> delete(String id) async {
    final all = _storage
        .readObjectList(_movingDayItemsKey)
        .map(MovingDayItem.fromJson)
        .where((item) => item.id != id)
        .toList();
    await _storage.writeObjectList(
      _movingDayItemsKey,
      all.map((value) => value.toJson()).toList(),
    );
  }
}

final movingDayRepositoryProvider = FutureProvider<MovingDayRepository>((ref) async {
  return MovingDayRepository(await ref.watch(localStorageProvider.future));
});

final movingDayItemsProvider = FutureProvider<List<MovingDayItem>>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) {
    return [];
  }
  final repository = await ref.watch(movingDayRepositoryProvider.future);
  await repository.seedDefaults(move.id);
  return repository.getItems(move.id);
});

final movingDayStatsProvider = FutureProvider<MovingDayStats>((ref) async {
  final boxes = await ref.watch(movingBoxesProvider.future);
  final items = await ref.watch(movingDayItemsProvider.future);
  final tasks = await ref.watch(tasksProvider.future);
  final inventory = await ref.watch(packingItemsProvider.future);
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);

  final loadedBoxes = boxes.where((box) {
    return box.status.index >= MovingBoxStatus.loaded.index;
  }).length;
  final arrivedBoxes = boxes.where((box) {
    return box.status.index >= MovingBoxStatus.arrived.index;
  }).length;
  final unpackedBoxes = boxes.where((box) {
    return box.status == MovingBoxStatus.unpacked;
  }).length;
  final openTodayTasks = tasks.where((task) {
    if (task.isCompleted || task.dueDate == null) {
      return false;
    }
    final due = task.dueDate!;
    final dueOnly = DateTime(due.year, due.month, due.day);
    return !dueOnly.isAfter(todayOnly);
  }).length;
  final unpackedInventoryItems = inventory
      .where((item) {
        return item.destination == ItemDestination.moving &&
            item.status != PackingStatus.unpacked;
      })
      .fold<int>(0, (total, item) => total + item.quantity);

  return MovingDayStats(
    totalBoxes: boxes.length,
    loadedBoxes: loadedBoxes,
    arrivedBoxes: arrivedBoxes,
    unpackedBoxes: unpackedBoxes,
    totalChecklistItems: items.length,
    checkedChecklistItems: items.where((item) {
      return item.status == MovingDayItemStatus.checked;
    }).length,
    openTodayTasks: openTodayTasks,
    unpackedInventoryItems: unpackedInventoryItems,
  );
});
