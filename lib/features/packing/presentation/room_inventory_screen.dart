import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../moves/data/move_repository.dart';
import '../../sales/data/sale_repository.dart';
import '../../sales/domain/sale_item.dart';
import '../data/packing_repository.dart';
import '../domain/packing_models.dart';

class RoomInventoryScreen extends ConsumerWidget {
  const RoomInventoryScreen({super.key, required this.roomId});

  final String roomId;

  Future<void> _addItem(
    BuildContext context,
    WidgetRef ref,
    MoveRoom room,
  ) async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    var isLarge = false;
    final result = await showDialog<(String, int, bool)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('פריט חדש'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'שם הפריט'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'כמות'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('פריט גדול להובלה ישירה'),
                value: isLarge,
                onChanged: (value) {
                  setDialogState(() => isLarge = value ?? false);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final quantity = int.tryParse(quantityController.text) ?? 1;
                if (name.isNotEmpty && quantity > 0) {
                  Navigator.pop(context, (name, quantity, isLarge));
                }
              },
              child: const Text('הוספה'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    quantityController.dispose();
    if (result == null) {
      return;
    }
    final move = await ref.read(currentMoveProvider.future);
    final repository = await ref.read(packingRepositoryProvider.future);
    if (move == null) {
      return;
    }
    await repository.upsertItem(
      PackingItem(
        id: 'item_${DateTime.now().microsecondsSinceEpoch}',
        moveId: move.id,
        roomId: room.id,
        name: result.$1,
        status: PackingStatus.atHome,
        destination: ItemDestination.moving,
        createdAt: DateTime.now(),
        isLarge: result.$3,
        isCustom: true,
        quantity: result.$2,
      ),
    );
    _invalidatePacking(ref);
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    PackingItem item,
    MovingBox? box,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('להסיר את ${item.name}?'),
        content: Text(
          box == null
              ? 'הפריט יוסר מרשימת החדר.'
              : 'הפריט נמצא בארגז ${box.number}. הוא יוסר גם מתכולת הארגז.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('הסרה'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final packingRepository = await ref.read(packingRepositoryProvider.future);
    await packingRepository.deleteItem(item.id);
    final salesRepository = await ref.read(saleRepositoryProvider.future);
    final sales = salesRepository.getItems(item.moveId);
    for (final sale in sales.where(
      (sale) => sale.sourcePackingItemId == item.id,
    )) {
      await salesRepository.delete(sale.id);
    }
    _invalidatePacking(ref);
    _invalidateSales(ref);
  }

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    PackingItem item,
    List<MovingBox> boxes,
  ) async {
    var status = item.status;
    var destination = item.destination;
    var selectedBoxId = item.linkedBoxId;
    var quantity = item.quantity;
    final notesController = TextEditingController(text: item.notes);
    final quantityController = TextEditingController(text: '$quantity');
    final salesRepository = await ref.read(saleRepositoryProvider.future);
    if (!context.mounted) {
      notesController.dispose();
      quantityController.dispose();
      return;
    }

    final existingSales = salesRepository.getItems(item.moveId).where(
          (sale) => sale.sourcePackingItemId == item.id,
        );
    final existingSale = existingSales.isEmpty ? null : existingSales.first;
    final askingPriceController = TextEditingController(
      text: existingSale?.askingPriceShekels.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'כמות'),
                  onChanged: (value) {
                    quantity = int.tryParse(value) ?? quantity;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PackingStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'סטטוס'),
                  items: PackingStatus.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => status = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ItemDestination>(
                  initialValue: destination,
                  decoration: const InputDecoration(labelText: 'יעד'),
                  items: ItemDestination.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => destination = value);
                    }
                  },
                ),
                if (destination == ItemDestination.selling) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: askingPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'מחיר מבוקש',
                      prefixText: '₪ ',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('הפריט יופיע אוטומטית במסך המכירות.'),
                  ),
                ],
                if (!item.isLarge && destination == ItemDestination.moving) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedBoxId,
                    decoration: const InputDecoration(labelText: 'ארגז'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('ללא ארגז'),
                      ),
                      ...boxes.where((box) => box.roomId == item.roomId).map(
                            (box) => DropdownMenuItem<String?>(
                              value: box.id,
                              child: Text('ארגז ${box.number}'),
                            ),
                          ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedBoxId = value);
                    },
                  ),
                ] else if (item.isLarge &&
                    destination == ItemDestination.moving)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.local_shipping_outlined),
                    title: Text('הובלה ישירה'),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'הערות'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('שמירה'),
            ),
          ],
        ),
      ),
    );
    if (result != true) {
      notesController.dispose();
      quantityController.dispose();
      askingPriceController.dispose();
      return;
    }

    quantity = int.tryParse(quantityController.text) ?? 1;
    if (quantity < 1) {
      quantity = 1;
    }
    final packingRepository = await ref.read(packingRepositoryProvider.future);
    MovingBox? selectedBox;
    if (selectedBoxId != null) {
      for (final box in boxes) {
        if (box.id == selectedBoxId) {
          selectedBox = box;
          break;
        }
      }
    }
    final updated = item.copyWith(
      status: status,
      destination: destination,
      notes: notesController.text.trim(),
      quantity: quantity,
      clearLinkedBox: destination != ItemDestination.moving,
    );
    if (destination != ItemDestination.moving && item.linkedBoxId != null) {
      await packingRepository.assignItemToBox(updated, null);
    } else if (!item.isLarge &&
        destination == ItemDestination.moving &&
        selectedBoxId != item.linkedBoxId) {
      await packingRepository.assignItemToBox(updated, selectedBox);
    } else {
      await packingRepository.upsertItem(updated);
    }

    await _syncSaleItem(
      salesRepository: salesRepository,
      packingItem: updated,
      existingSale: existingSale,
      askingPriceShekels:
          int.tryParse(askingPriceController.text.trim()) ?? 0,
    );

    notesController.dispose();
    quantityController.dispose();
    askingPriceController.dispose();
    _invalidatePacking(ref);
    _invalidateSales(ref);
  }

  Future<void> _syncSaleItem({
    required SaleRepository salesRepository,
    required PackingItem packingItem,
    required SaleItem? existingSale,
    required int askingPriceShekels,
  }) async {
    if (packingItem.destination != ItemDestination.selling) {
      if (existingSale != null && existingSale.status != SaleStatus.sold) {
        await salesRepository.delete(existingSale.id);
      }
      return;
    }
    final now = DateTime.now();
    await salesRepository.upsert(
      SaleItem(
        id: existingSale?.id ?? 'sale_from_${packingItem.id}',
        moveId: packingItem.moveId,
        title: packingItem.name,
        description: packingItem.notes,
        category: _saleCategoryForItem(packingItem),
        askingPriceShekels: askingPriceShekels,
        soldPriceShekels: existingSale?.soldPriceShekels,
        status: existingSale?.status ?? SaleStatus.draft,
        buyerName: existingSale?.buyerName ?? '',
        notes: existingSale?.notes ?? 'נוצר אוטומטית מרשימת הציוד',
        createdAt: existingSale?.createdAt ?? now,
        publishedAt: existingSale?.publishedAt,
        soldAt: existingSale?.soldAt,
        quantity: packingItem.quantity,
        sourcePackingItemId: packingItem.id,
      ),
    );
  }

  SaleCategory _saleCategoryForItem(PackingItem item) {
    final name = item.name;
    if (item.isLarge ||
        name.contains('שולחן') ||
        name.contains('כיסא') ||
        name.contains('ארון') ||
        name.contains('מיטה') ||
        name.contains('ספה')) {
      return SaleCategory.furniture;
    }
    if (name.contains('טלוויז') ||
        name.contains('מחשב') ||
        name.contains('מסך') ||
        name.contains('רמקול')) {
      return SaleCategory.electronics;
    }
    if (name.contains('מקרר') ||
        name.contains('תנור') ||
        name.contains('מדיח') ||
        name.contains('כביסה') ||
        name.contains('מייבש')) {
      return SaleCategory.appliances;
    }
    return SaleCategory.other;
  }

  void _invalidatePacking(WidgetRef ref) {
    ref.invalidate(packingItemsProvider);
    ref.invalidate(movingBoxesProvider);
    ref.invalidate(packingStatsProvider);
  }

  void _invalidateSales(WidgetRef ref) {
    ref.invalidate(saleItemsProvider);
    ref.invalidate(saleStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    final itemsAsync = ref.watch(packingItemsProvider);
    final boxesAsync = ref.watch(movingBoxesProvider);
    return roomsAsync.when(
      data: (rooms) {
        MoveRoom? room;
        for (final value in rooms) {
          if (value.id == roomId) {
            room = value;
            break;
          }
        }
        final selectedRoom = room;
        if (selectedRoom == null) {
          return const Scaffold(body: Center(child: Text('החדר לא נמצא')));
        }
        return Scaffold(
          appBar: AppBar(title: Text(selectedRoom.name)),
          body: itemsAsync.when(
            data: (allItems) => boxesAsync.when(
              data: (boxes) {
                final items = allItems
                    .where((item) => item.roomId == roomId)
                    .toList();
                final progressed = items
                    .where((item) => item.status != PackingStatus.atHome)
                    .fold<int>(0, (total, item) => total + item.quantity);
                final totalQuantity = items.fold<int>(
                  0,
                  (total, item) => total + item.quantity,
                );
                final progress = totalQuantity == 0
                    ? 0.0
                    : progressed / totalQuantity;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 8),
                          Text(
                            '$progressed מתוך $totalQuantity יחידות בתהליך · '
                            '${(progress * 100).round()}%',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(child: Text('אין עדיין פריטים בחדר'))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                MovingBox? linkedBox;
                                for (final box in boxes) {
                                  if (box.id == item.linkedBoxId) {
                                    linkedBox = box;
                                    break;
                                  }
                                }
                                final subtitleParts = <String>[
                                  item.destination.label,
                                  item.status.label,
                                  if (linkedBox != null)
                                    'ארגז ${linkedBox.number}',
                                ];
                                return Card(
                                  child: ListTile(
                                    onTap: () => _editItem(
                                      context,
                                      ref,
                                      item,
                                      boxes,
                                    ),
                                    leading: Icon(
                                      item.isLarge
                                          ? Icons.chair_outlined
                                          : Icons.inventory_2_outlined,
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(child: Text(item.name)),
                                        if (item.quantity > 1)
                                          Chip(
                                            visualDensity: VisualDensity.compact,
                                            label: Text('×${item.quantity}'),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(subtitleParts.join(' · ')),
                                    trailing: IconButton(
                                      tooltip: 'הסרה מהרשימה',
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () => _deleteItem(
                                        context,
                                        ref,
                                        item,
                                        linkedBox,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('שגיאה: $error')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('שגיאה: $error')),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addItem(context, ref, selectedRoom),
            icon: const Icon(Icons.add),
            label: const Text('פריט חדש'),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('שגיאה: $error'))),
    );
  }
}
