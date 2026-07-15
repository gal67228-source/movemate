import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../moves/data/move_repository.dart';
import '../domain/shopping_item.dart';

const _shoppingKey = 'shopping_items';

class ShoppingRepository {
  ShoppingRepository(this._storage);
  final LocalStorage _storage;

  List<ShoppingItem> getItems(String moveId) => _storage.readObjectList(_shoppingKey).map(ShoppingItem.fromJson).where((item) => item.moveId == moveId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> upsert(ShoppingItem item) async {
    final all = _storage.readObjectList(_shoppingKey).map(ShoppingItem.fromJson).toList();
    final index = all.indexWhere((value) => value.id == item.id);
    if (index == -1) {
      all.add(item);
    } else {
      all[index] = item;
    }
    await _storage.writeObjectList(_shoppingKey, all.map((value) => value.toJson()).toList());
  }

  Future<void> delete(String id) async {
    final all = _storage.readObjectList(_shoppingKey).map(ShoppingItem.fromJson).where((item) => item.id != id).toList();
    await _storage.writeObjectList(_shoppingKey, all.map((value) => value.toJson()).toList());
  }
}

final shoppingRepositoryProvider = FutureProvider<ShoppingRepository>((ref) async => ShoppingRepository(await ref.watch(localStorageProvider.future)));
final shoppingItemsProvider = FutureProvider<List<ShoppingItem>>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) {
    return [];
  }
  return (await ref.watch(shoppingRepositoryProvider.future)).getItems(move.id);
});
final shoppingStatsProvider = FutureProvider<ShoppingStats>((ref) async => calculateShoppingStats(await ref.watch(shoppingItemsProvider.future)));
