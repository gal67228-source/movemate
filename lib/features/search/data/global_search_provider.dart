import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../packing/data/packing_repository.dart';
import '../../packing/domain/packing_models.dart';
import '../../sales/data/sale_repository.dart';
import '../../sales/domain/sale_item.dart';
import '../../shopping/data/shopping_repository.dart';
import '../../shopping/domain/shopping_item.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/move_task.dart';
import '../domain/global_search_result.dart';

final globalSearchResultsProvider =
    FutureProvider<List<GlobalSearchResult>>((ref) async {
  final rooms = await ref.watch(roomsProvider.future);
  final inventoryItems = await ref.watch(packingItemsProvider.future);
  final boxes = await ref.watch(movingBoxesProvider.future);
  final saleItems = await ref.watch(saleItemsProvider.future);
  final tasks = await ref.watch(tasksProvider.future);
  final shoppingItems = await ref.watch(shoppingItemsProvider.future);

  final roomNames = <String, String>{
    for (final room in rooms) room.id: room.name,
  };
  final boxesById = <String, MovingBox>{
    for (final box in boxes) box.id: box,
  };

  return <GlobalSearchResult>[
    ...inventoryItems.map((item) {
      final roomName = roomNames[item.roomId] ?? 'חדר לא ידוע';
      final linkedBox = item.linkedBoxId == null
          ? null
          : boxesById[item.linkedBoxId];
      final effectiveStatus = _effectivePackingStatus(item, linkedBox);
      final boxText = linkedBox == null ? '' : ' · ארגז ${linkedBox.number}';
      return GlobalSearchResult(
        id: 'inventory_${item.id}',
        type: GlobalSearchType.inventory,
        title: item.quantity > 1 ? '${item.name} ×${item.quantity}' : item.name,
        subtitle: '$roomName · ${effectiveStatus.label}$boxText',
        details: item.notes,
        route: '/rooms/${item.roomId}',
        searchTerms: [
          item.destination.label,
          if (item.isLarge) 'הובלה ישירה',
          if (linkedBox != null) linkedBox.contents.join(' '),
        ],
      );
    }),
    ...boxes.map((box) {
      final roomName = roomNames[box.roomId] ?? 'חדר לא ידוע';
      final displayName = box.name.trim().isEmpty ? '' : ' · ${box.name}';
      return GlobalSearchResult(
        id: 'box_${box.id}',
        type: GlobalSearchType.box,
        title: 'ארגז ${box.number}$displayName',
        subtitle: '$roomName · ${box.status.label}',
        details: box.contents.isEmpty
            ? 'לא הוזנה תכולה'
            : box.contents.join(', '),
        route: '/boxes/edit?id=${box.id}',
        searchTerms: [
          box.notes,
          box.weight.label,
          if (box.fragile) 'שביר',
        ],
      );
    }),
    ...saleItems.map((item) {
      final quantityText = item.quantity > 1 ? ' ×${item.quantity}' : '';
      final price = item.status == SaleStatus.sold
          ? item.soldPriceShekels ?? item.askingPriceShekels
          : item.askingPriceShekels;
      return GlobalSearchResult(
        id: 'sale_${item.id}',
        type: GlobalSearchType.sale,
        title: '${item.title}$quantityText',
        subtitle: '${saleStatusLabel(item.status)} · ₪$price',
        details: item.description,
        route: '/sales/edit?id=${item.id}',
        searchTerms: [
          saleCategoryLabel(item.category),
          item.buyerName,
          item.notes,
        ],
      );
    }),
    ...tasks.map((task) {
      return GlobalSearchResult(
        id: 'task_${task.id}',
        type: GlobalSearchType.task,
        title: task.title,
        subtitle: task.isCompleted
            ? 'הושלמה'
            : '${categoryLabel(task.category)} · עדיפות ${priorityLabel(task.priority)}',
        details: task.description,
        route: '/tasks/edit?id=${task.id}',
        searchTerms: [
          categoryLabel(task.category),
          priorityLabel(task.priority),
        ],
      );
    }),
    ...shoppingItems.map((item) {
      final quantityText = item.quantity > 1 ? ' ×${item.quantity}' : '';
      return GlobalSearchResult(
        id: 'shopping_${item.id}',
        type: GlobalSearchType.shopping,
        title: '${item.title}$quantityText',
        subtitle:
            '${shoppingStatusLabel(item.status)} · ₪${item.actualPriceShekels ?? item.estimatedPriceShekels}',
        details: item.notes,
        route: '/shopping',
        searchTerms: [shoppingCategoryLabel(item.category)],
      );
    }),
  ];
});

PackingStatus _effectivePackingStatus(
  PackingItem item,
  MovingBox? linkedBox,
) {
  if (linkedBox == null) {
    return item.status;
  }

  return switch (linkedBox.status) {
    MovingBoxStatus.preparing || MovingBoxStatus.packed => PackingStatus.inBox,
    MovingBoxStatus.loaded => PackingStatus.loaded,
    MovingBoxStatus.arrived => PackingStatus.arrived,
    MovingBoxStatus.unpacked => PackingStatus.unpacked,
  };
}
