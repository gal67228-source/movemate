import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../moves/data/move_repository.dart';
import '../domain/packing_models.dart';

const _roomsKey = 'move_rooms';
const _itemsKey = 'packing_items';
const _boxesKey = 'moving_boxes';

class PackingRepository {
  PackingRepository(this._storage);

  final LocalStorage _storage;

  List<MoveRoom> getRooms(String moveId) => _storage
      .readObjectList(_roomsKey)
      .map(MoveRoom.fromJson)
      .where((room) => room.moveId == moveId)
      .toList();

  List<PackingItem> getItems(String moveId) => _storage
      .readObjectList(_itemsKey)
      .map(PackingItem.fromJson)
      .where((item) => item.moveId == moveId)
      .toList();

  List<MovingBox> getBoxes(String moveId) {
    final boxes = _storage
        .readObjectList(_boxesKey)
        .map(MovingBox.fromJson)
        .where((box) => box.moveId == moveId)
        .toList();
    boxes.sort((a, b) => a.number.compareTo(b.number));
    return boxes;
  }

  Future<void> seedRooms(String moveId, int roomCount) async {
    if (getRooms(moveId).isNotEmpty) return;
    final names = <String>['סלון', 'מטבח', 'חדר שינה'];
    for (var index = 3; index < roomCount; index++) {
      names.add('חדר ${index - 1}');
    }
    final count = roomCount < 1 ? 1 : roomCount;
    for (final name in names.take(count)) {
      await upsertRoom(
        MoveRoom(
          id: 'room_${moveId}_${DateTime.now().microsecondsSinceEpoch}_$name',
          moveId: moveId,
          name: name,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> upsertRoom(MoveRoom room) async {
    final all = _storage.readObjectList(_roomsKey).map(MoveRoom.fromJson).toList();
    final index = all.indexWhere((value) => value.id == room.id);
    if (index == -1) {
      all.add(room);
    } else {
      all[index] = room;
    }
    await _storage.writeObjectList(
      _roomsKey,
      all.map((value) => value.toJson()).toList(),
    );
  }

  Future<void> deleteRoom(String roomId) async {
    final rooms = _storage
        .readObjectList(_roomsKey)
        .map(MoveRoom.fromJson)
        .where((room) => room.id != roomId)
        .toList();
    final items = _storage
        .readObjectList(_itemsKey)
        .map(PackingItem.fromJson)
        .where((item) => item.roomId != roomId)
        .toList();
    final boxes = _storage
        .readObjectList(_boxesKey)
        .map(MovingBox.fromJson)
        .where((box) => box.roomId != roomId)
        .toList();
    await _storage.writeObjectList(
      _roomsKey,
      rooms.map((value) => value.toJson()).toList(),
    );
    await _storage.writeObjectList(
      _itemsKey,
      items.map((value) => value.toJson()).toList(),
    );
    await _storage.writeObjectList(
      _boxesKey,
      boxes.map((value) => value.toJson()).toList(),
    );
  }

  Future<void> upsertItem(PackingItem item) async {
    final all = _storage.readObjectList(_itemsKey).map(PackingItem.fromJson).toList();
    final index = all.indexWhere((value) => value.id == item.id);
    if (index == -1) {
      all.add(item);
    } else {
      all[index] = item;
    }
    await _storage.writeObjectList(
      _itemsKey,
      all.map((value) => value.toJson()).toList(),
    );
  }

  Future<void> deleteItem(String id) async {
    final all = _storage
        .readObjectList(_itemsKey)
        .map(PackingItem.fromJson)
        .where((item) => item.id != id)
        .toList();
    await _storage.writeObjectList(
      _itemsKey,
      all.map((value) => value.toJson()).toList(),
    );
  }

  Future<void> upsertBox(MovingBox box) async {
    final all = _storage.readObjectList(_boxesKey).map(MovingBox.fromJson).toList();
    final index = all.indexWhere((value) => value.id == box.id);
    if (index == -1) {
      all.add(box);
    } else {
      all[index] = box;
    }
    await _storage.writeObjectList(
      _boxesKey,
      all.map((value) => value.toJson()).toList(),
    );
  }

  Future<void> deleteBox(String id) async {
    final all = _storage
        .readObjectList(_boxesKey)
        .map(MovingBox.fromJson)
        .where((box) => box.id != id)
        .toList();
    await _storage.writeObjectList(
      _boxesKey,
      all.map((value) => value.toJson()).toList(),
    );
  }
}

final packingRepositoryProvider = FutureProvider<PackingRepository>((ref) async {
  return PackingRepository(await ref.watch(localStorageProvider.future));
});

final roomsProvider = FutureProvider<List<MoveRoom>>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) return [];
  final repository = await ref.watch(packingRepositoryProvider.future);
  await repository.seedRooms(move.id, move.roomCount);
  return repository.getRooms(move.id);
});

final packingItemsProvider = FutureProvider<List<PackingItem>>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) return [];
  final repository = await ref.watch(packingRepositoryProvider.future);
  return repository.getItems(move.id);
});

final movingBoxesProvider = FutureProvider<List<MovingBox>>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) return [];
  final repository = await ref.watch(packingRepositoryProvider.future);
  return repository.getBoxes(move.id);
});

final packingStatsProvider = FutureProvider<PackingStats>((ref) async {
  final items = await ref.watch(packingItemsProvider.future);
  final boxes = await ref.watch(movingBoxesProvider.future);
  return PackingStats(
    totalItems: items.length,
    packedItems: items.where((item) => item.status == PackingStatus.packed).length,
    boxes: boxes.length,
    closedBoxes: boxes.where((box) => box.isClosed).length,
  );
});
