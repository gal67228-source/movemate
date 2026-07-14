import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../moves/data/move_repository.dart';
import '../data/packing_repository.dart';
import '../domain/packing_models.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  Future<void> _addRoom(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('חדר חדש'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'שם החדר'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('שמירה'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) {
      return;
    }
    final move = await ref.read(currentMoveProvider.future);
    final repository = await ref.read(packingRepositoryProvider.future);
    if (move == null) {
      return;
    }
    await repository.upsertRoom(
      MoveRoom(
        id: 'room_${DateTime.now().microsecondsSinceEpoch}',
        moveId: move.id,
        name: name,
        createdAt: DateTime.now(),
      ),
    );
    ref.invalidate(roomsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    final itemsAsync = ref.watch(packingItemsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('חדרים')),
      body: roomsAsync.when(
        data: (rooms) => itemsAsync.when(
          data: (items) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final roomItems = items.where((item) => item.roomId == room.id).toList();
              final packed = roomItems.where((item) => item.status == PackingStatus.packed).length;
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.meeting_room_outlined)),
                  title: Text(room.name),
                  subtitle: Text('${roomItems.length} פריטים · $packed נארזו'),
                  trailing: roomItems.isEmpty
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final repository = await ref.read(packingRepositoryProvider.future);
                            await repository.deleteRoom(room.id);
                            ref.invalidate(roomsProvider);
                          },
                        )
                      : null,
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('שגיאה: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('שגיאה: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addRoom(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('חדר חדש'),
      ),
    );
  }
}
