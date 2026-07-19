import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../moves/data/move_repository.dart';
import '../domain/packing_models.dart';
import '../domain/room_catalog.dart';

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
    if (getRooms(moveId).isNotEmpty) {
      return;
    }
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

  Future<void> seedRoomCatalog(MoveRoom room) async {
    final existing = getItems(room.moveId).where((item) => item.roomId == room.id);
    if (existing.isNotEmpty) {
      return;
    }
    final now = DateTime.now();
    for (final entry in catalogForRoom(room.name)) {
      await upsertItem(
        PackingItem(
          id: 'item_${room.id}_${entry.name.hashCode.abs()}',
          moveId: room.moveId,
          roomId: room.id,
          name: entry.name,
          status: PackingStatus.atHome,
          destination: ItemDestination.moving,
          createdAt: now,
          isLarge: entry.isLarge,
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
    await _storage.writeObjectList(_roomsKey, all.map((e) => e.toJson()).toList());
  }

  Future<void> deleteRoom(String roomId) async {
    final rooms = _storage.readObjectList(_roomsKey).map(MoveRoom.fromJson).where((e) => e.id != roomId).toList();
    final items = _storage.readObjectList(_itemsKey).map(PackingItem.fromJson).where((e) => e.roomId != roomId).toList();
    final boxes = _storage.readObjectList(_boxesKey).map(MovingBox.fromJson).where((e) => e.roomId != roomId).toList();
    await _storage.writeObjectList(_roomsKey, rooms.map((e) => e.toJson()).toList());
    await _storage.writeObjectList(_itemsKey, items.map((e) => e.toJson()).toList());
    await _storage.writeObjectList(_boxesKey, boxes.map((e) => e.toJson()).toList());
  }

  Future<void> upsertItem(PackingItem item) async {
    final all = _storage.readObjectList(_itemsKey).map(PackingItem.fromJson).toList();
    final index = all.indexWhere((value) => value.id == item.id);
    if (index == -1) {
      all.add(item);
    } else {
      all[index] = item;
    }
    await _storage.writeObjectList(_itemsKey, all.map((e) => e.toJson()).toList());
  }

  Future<void> deleteItem(String id) async {
    final all = _storage.readObjectList(_itemsKey).map(PackingItem.fromJson).toList();
    PackingItem? item;
    for (final value in all) {
      if (value.id == id) {
        item = value;
        break;
      }
    }
    final remaining = all.where((value) => value.id != id).toList();
    await _storage.writeObjectList(_itemsKey, remaining.map((e) => e.toJson()).toList());
    if (item?.linkedBoxId != null) {
      final boxes = _storage.readObjectList(_boxesKey).map(MovingBox.fromJson).toList();
      final index = boxes.indexWhere((box) => box.id == item!.linkedBoxId);
      if (index != -1) {
        boxes[index] = boxes[index].copyWith(
          contents: boxes[index].contents.where((name) => _normalize(name) != _normalize(item!.name)).toList(),
        );
        await _storage.writeObjectList(_boxesKey, boxes.map((e) => e.toJson()).toList());
      }
    }
  }

  Future<void> upsertBox(MovingBox box) async {
    final allBoxes = _storage.readObjectList(_boxesKey).map(MovingBox.fromJson).toList();
    final index = allBoxes.indexWhere((value) => value.id == box.id);
    if (index == -1) {
      allBoxes.add(box);
    } else {
      allBoxes[index] = box;
    }
    await _storage.writeObjectList(_boxesKey, allBoxes.map((e) => e.toJson()).toList());
    await _syncItemsWithBox(box);
  }

  Future<void> _syncItemsWithBox(MovingBox box) async {
    final all = _storage.readObjectList(_itemsKey).map(PackingItem.fromJson).toList();
    final normalizedContents = box.contents.map(_normalize).toSet();
    final derivedStatus = switch (box.status) {
      MovingBoxStatus.preparing || MovingBoxStatus.packed => PackingStatus.inBox,
      MovingBoxStatus.loaded => PackingStatus.loaded,
      MovingBoxStatus.arrived => PackingStatus.arrived,
      MovingBoxStatus.unpacked => PackingStatus.unpacked,
    };
    var changed = false;
    final matchedNames = <String>{};
    for (var i = 0; i < all.length; i++) {
      final item = all[i];
      if (item.moveId != box.moveId) {
        continue;
      }
      final normalizedName = _normalize(item.name);
      final belongsByName = item.roomId == box.roomId && normalizedContents.contains(normalizedName);
      final wasLinked = item.linkedBoxId == box.id;
      if (belongsByName) {
        matchedNames.add(normalizedName);
        all[i] = item.copyWith(linkedBoxId: box.id, status: derivedStatus);
        changed = true;
      } else if (wasLinked) {
        all[i] = item.copyWith(clearLinkedBox: true, status: PackingStatus.atHome);
        changed = true;
      }
    }
    for (final contentName in box.contents) {
      if (!matchedNames.contains(_normalize(contentName))) {
        all.add(
          PackingItem(
            id: 'item_${box.id}_${contentName.hashCode.abs()}',
            moveId: box.moveId,
            roomId: box.roomId,
            name: contentName,
            status: derivedStatus,
            destination: ItemDestination.moving,
            createdAt: DateTime.now(),
            linkedBoxId: box.id,
            isCustom: true,
          ),
        );
        changed = true;
      }
    }
    if (changed) {
      await _storage.writeObjectList(_itemsKey, all.map((e) => e.toJson()).toList());
    }
  }

  Future<void> assignItemToBox(PackingItem item, MovingBox? box) async {
    final boxes = _storage.readObjectList(_boxesKey).map(MovingBox.fromJson).toList();
    for (var i = 0; i < boxes.length; i++) {
      if (boxes[i].id == item.linkedBoxId) {
        boxes[i] = boxes[i].copyWith(
          contents: boxes[i].contents.where((name) => _normalize(name) != _normalize(item.name)).toList(),
        );
      }
    }
    if (box == null) {
      await _storage.writeObjectList(_boxesKey, boxes.map((e) => e.toJson()).toList());
      await upsertItem(item.copyWith(clearLinkedBox: true, status: PackingStatus.atHome));
      return;
    }
    final boxIndex = boxes.indexWhere((value) => value.id == box.id);
    if (boxIndex != -1 && !boxes[boxIndex].contents.any((name) => _normalize(name) == _normalize(item.name))) {
      boxes[boxIndex] = boxes[boxIndex].copyWith(contents: [...boxes[boxIndex].contents, item.name]);
    }
    await _storage.writeObjectList(_boxesKey, boxes.map((e) => e.toJson()).toList());
    await upsertItem(item.copyWith(linkedBoxId: box.id, status: PackingStatus.inBox));
  }

  Future<void> deleteBox(String id) async {
    final boxes = _storage.readObjectList(_boxesKey).map(MovingBox.fromJson).where((e) => e.id != id).toList();
    final items = _storage.readObjectList(_itemsKey).map(PackingItem.fromJson).map((item) {
      return item.linkedBoxId == id
          ? item.copyWith(clearLinkedBox: true, status: PackingStatus.atHome)
          : item;
    }).toList();
    await _storage.writeObjectList(_boxesKey, boxes.map((e) => e.toJson()).toList());
    await _storage.writeObjectList(_itemsKey, items.map((e) => e.toJson()).toList());
  }

  static String _normalize(String value) => value.trim().toLowerCase().replaceAll('"', '').replaceAll('״', '').replaceAll("'", '').replaceAll('׳', '');
}

final packingRepositoryProvider = FutureProvider<PackingRepository>((ref) async {
  return PackingRepository(await ref.watch(localStorageProvider.future));
});

final roomsProvider = FutureProvider<List<MoveRoom>>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) {
    return [];
  }
  final repository = await ref.watch(packingRepositoryProvider.future);
  await repository.seedRooms(move.id, move.roomCount);
  final rooms = repository.getRooms(move.id);
  for (final room in rooms) {
    await repository.seedRoomCatalog(room);
  }
  return rooms;
});

final packingItemsProvider = FutureProvider<List<PackingItem>>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) {
    return [];
  }
  final repository = await ref.watch(packingRepositoryProvider.future);
  final rooms = await ref.watch(roomsProvider.future);
  for (final room in rooms) {
    await repository.seedRoomCatalog(room);
  }
  return repository.getItems(move.id);
});

final movingBoxesProvider = FutureProvider<List<MovingBox>>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) {
    return [];
  }
  final repository = await ref.watch(packingRepositoryProvider.future);
  return repository.getBoxes(move.id);
});

final packingStatsProvider = FutureProvider<PackingStats>((ref) async {
  final items = await ref.watch(packingItemsProvider.future);
  final boxes = await ref.watch(movingBoxesProvider.future);
  return PackingStats(
    totalItems: items.fold<int>(0, (total, item) => total + item.quantity),
    packedItems: items
        .where((item) => item.status != PackingStatus.atHome)
        .fold<int>(0, (total, item) => total + item.quantity),
    boxes: boxes.length,
    closedBoxes: boxes.where((box) => box.isClosed).length,
    fragileBoxes: boxes.where((box) => box.fragile).length,
    unpackedBoxes: boxes.where((box) => box.status == MovingBoxStatus.unpacked).length,
  );
});
