import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../moves/data/move_repository.dart';
import '../data/packing_repository.dart';
import '../domain/packing_models.dart';

class PackingItemsScreen extends ConsumerWidget {
  const PackingItemsScreen({super.key});

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final rooms = await ref.read(roomsProvider.future);
    if (rooms.isEmpty || !context.mounted) return;
    final nameController = TextEditingController();
    var selectedRoom = rooms.first.id;
    var destination = ItemDestination.moving;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
              DropdownButtonFormField<String>(
                initialValue: selectedRoom,
                decoration: const InputDecoration(labelText: 'חדר'),
                items: rooms
                    .map((room) => DropdownMenuItem(value: room.id, child: Text(room.name)))
                    .toList(),
                onChanged: (value) => setState(() => selectedRoom = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ItemDestination>(
                initialValue: destination,
                decoration: const InputDecoration(labelText: 'יעד'),
                items: ItemDestination.values
                    .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                    .toList(),
                onChanged: (value) => setState(() => destination = value!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('שמירה')),
          ],
        ),
      ),
    );
    if (result != true || nameController.text.trim().isEmpty) return;
    final move = await ref.read(currentMoveProvider.future);
    final repository = await ref.read(packingRepositoryProvider.future);
    if (move == null) return;
    await repository.upsertItem(
      PackingItem(
        id: 'item_${DateTime.now().microsecondsSinceEpoch}',
        moveId: move.id,
        roomId: selectedRoom,
        name: nameController.text.trim(),
        status: PackingStatus.notPacked,
        destination: destination,
        createdAt: DateTime.now(),
      ),
    );
    ref.invalidate(packingItemsProvider);
    ref.invalidate(packingStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(packingItemsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ציוד לאריזה')),
      body: itemsAsync.when(
        data: (items) => roomsAsync.when(
          data: (rooms) {
            final roomNames = {for (final room in rooms) room.id: room.name};
            if (items.isEmpty) {
              return const Center(child: Text('עדיין לא הוספת ציוד לאריזה'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: CheckboxListTile(
                    value: item.status == PackingStatus.packed,
                    title: Text(item.name),
                    subtitle: Text('${roomNames[item.roomId] ?? 'ללא חדר'} · ${item.destination.label}'),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final repository = await ref.read(packingRepositoryProvider.future);
                        await repository.deleteItem(item.id);
                        ref.invalidate(packingItemsProvider);
                        ref.invalidate(packingStatsProvider);
                      },
                    ),
                    onChanged: (value) async {
                      final repository = await ref.read(packingRepositoryProvider.future);
                      await repository.upsertItem(
                        item.copyWith(
                          status: value == true ? PackingStatus.packed : PackingStatus.notPacked,
                        ),
                      );
                      ref.invalidate(packingItemsProvider);
                      ref.invalidate(packingStatsProvider);
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('שגיאה: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('שגיאה: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addItem(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('פריט חדש'),
      ),
    );
  }
}
