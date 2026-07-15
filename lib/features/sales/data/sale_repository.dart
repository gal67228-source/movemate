import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../moves/data/move_repository.dart';
import '../domain/sale_item.dart';

const _saleItemsKey = 'sale_items';

class SaleRepository {
  SaleRepository(this._storage);

  final LocalStorage _storage;

  List<SaleItem> getItems(String moveId) {
    final items = _storage
        .readObjectList(_saleItemsKey)
        .map(SaleItem.fromJson)
        .where((item) => item.moveId == moveId)
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> upsert(SaleItem item) async {
    final all = _storage
        .readObjectList(_saleItemsKey)
        .map(SaleItem.fromJson)
        .toList();
    final index = all.indexWhere((value) => value.id == item.id);
    if (index == -1) {
      all.add(item);
    } else {
      all[index] = item;
    }
    await _storage.writeObjectList(
      _saleItemsKey,
      all.map((value) => value.toJson()).toList(),
    );
  }

  Future<void> delete(String id) async {
    final all = _storage
        .readObjectList(_saleItemsKey)
        .map(SaleItem.fromJson)
        .where((item) => item.id != id)
        .toList();
    await _storage.writeObjectList(
      _saleItemsKey,
      all.map((value) => value.toJson()).toList(),
    );
  }
}

final saleRepositoryProvider = FutureProvider<SaleRepository>((ref) async {
  return SaleRepository(await ref.watch(localStorageProvider.future));
});

final saleItemsProvider = FutureProvider<List<SaleItem>>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) {
    return [];
  }
  final repository = await ref.watch(saleRepositoryProvider.future);
  return repository.getItems(move.id);
});

final saleStatsProvider = FutureProvider<SaleStats>((ref) async {
  return calculateSaleStats(await ref.watch(saleItemsProvider.future));
});
