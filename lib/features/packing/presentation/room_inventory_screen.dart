import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../moves/data/move_repository.dart';
import '../data/packing_repository.dart';
import '../domain/packing_models.dart';

class RoomInventoryScreen extends ConsumerWidget {
  const RoomInventoryScreen({super.key, required this.roomId});
  final String roomId;

  Future<void> _addItem(BuildContext context, WidgetRef ref, MoveRoom room) async {
    final controller = TextEditingController();
    var isLarge = false;
    final result = await showDialog<(String, bool)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('פריט חדש'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'שם הפריט')),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('פריט גדול להובלה ישירה'),
                value: isLarge,
                onChanged: (value) => setDialogState(() => isLarge = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context, (name, isLarge));
                }
              },
              child: const Text('הוספה'),
            ),
          ],
        ),
      ),
    );
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
        isLarge: result.$2,
        isCustom: true,
      ),
    );
    ref.invalidate(packingItemsProvider);
    ref.invalidate(packingStatsProvider);
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref, PackingItem item, MovingBox? box) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('להסיר את ${item.name}?'),
        content: Text(box == null ? 'הפריט יוסר מרשימת החדר.' : 'הפריט נמצא בארגז ${box.number}. הוא יוסר גם מתכולת הארגז.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('הסרה')),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final repository = await ref.read(packingRepositoryProvider.future);
    await repository.deleteItem(item.id);
    ref.invalidate(packingItemsProvider);
    ref.invalidate(movingBoxesProvider);
    ref.invalidate(packingStatsProvider);
  }

  Future<void> _editItem(BuildContext context, WidgetRef ref, PackingItem item, List<MovingBox> boxes) async {
    var status = item.status;
    var destination = item.destination;
    var selectedBoxId = item.linkedBoxId;
    final notesController = TextEditingController(text: item.notes);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<PackingStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'סטטוס'),
                  items: PackingStatus.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(),
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
                  items: ItemDestination.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => destination = value);
                    }
                  },
                ),
                if (!item.isLarge) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedBoxId,
                    decoration: const InputDecoration(labelText: 'ארגז'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('ללא ארגז')),
                      ...boxes.where((box) => box.roomId == item.roomId).map(
                        (box) => DropdownMenuItem<String?>(value: box.id, child: Text('ארגז ${box.number}')),
                      ),
                    ],
                    onChanged: (value) => setDialogState(() => selectedBoxId = value),
                  ),
                ] else
                  const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.local_shipping_outlined), title: Text('הובלה ישירה')),
                const SizedBox(height: 12),
                TextField(controller: notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'הערות')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('שמירה')),
          ],
        ),
      ),
    );
    if (result != true) {
      return;
    }
    final repository = await ref.read(packingRepositoryProvider.future);
    MovingBox? selectedBox;
    if (selectedBoxId != null) {
      for (final box in boxes) {
        if (box.id == selectedBoxId) {
          selectedBox = box;
          break;
        }
      }
    }
    final updated = item.copyWith(status: status, destination: destination, notes: notesController.text.trim());
    if (!item.isLarge && selectedBoxId != item.linkedBoxId) {
      await repository.assignItemToBox(updated, selectedBox);
    } else {
      await repository.upsertItem(updated);
    }
    ref.invalidate(packingItemsProvider);
    ref.invalidate(movingBoxesProvider);
    ref.invalidate(packingStatsProvider);
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
        if (room == null) {
          return const Scaffold(body: Center(child: Text('החדר לא נמצא')));
        }
        return Scaffold(
          appBar: AppBar(title: Text(room.name)),
          body: itemsAsync.when(
            data: (allItems) => boxesAsync.when(
              data: (boxes) {
                final items = allItems.where((item) => item.roomId == roomId).toList();
                final progressed = items.where((item) => item.status != PackingStatus.atHome).length;
                final progress = items.isEmpty ? 0.0 : progressed / items.length;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 8),
                          Text('$progressed מתוך ${items.length} פריטים בתהליך · ${(progress * 100).round()}%'),
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
                                return Card(
                                  child: ListTile(
                                    onTap: () => _editItem(context, ref, item, boxes),
                                    leading: Icon(item.isLarge ? Icons.chair_outlined : Icons.inventory_2_outlined),
                                    title: Text(item.name),
                                    subtitle: Text(linkedBox == null ? item.status.label : '${item.status.label} · ארגז ${linkedBox.number}'),
                                    trailing: IconButton(
                                      tooltip: 'הסרה מהרשימה',
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () => _deleteItem(context, ref, item, linkedBox),
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
            onPressed: () => _addItem(context, ref, room),
            icon: const Icon(Icons.add),
            label: const Text('פריט חדש'),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('שגיאה: $error'))),
    );
  }
}
