import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final room = MoveRoom(
      id: 'room_${DateTime.now().microsecondsSinceEpoch}',
      moveId: move.id,
      name: name,
      createdAt: DateTime.now(),
    );
    await repository.upsertRoom(room);
    await repository.seedRoomCatalog(room);
    ref.invalidate(roomsProvider);
    ref.invalidate(packingItemsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    final itemsAsync = ref.watch(packingItemsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('חדרים חכמים')),
      body: roomsAsync.when(
        data: (rooms) => itemsAsync.when(
          data: (items) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final roomItems = items.where((item) => item.roomId == room.id).toList();
              final progressed = roomItems.where((item) => item.status != PackingStatus.atHome).length;
              final progress = roomItems.isEmpty ? 0.0 : progressed / roomItems.length;
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/rooms/${room.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(child: Icon(Icons.meeting_room_outlined)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(room.name, style: Theme.of(context).textTheme.titleMedium)),
                            const Icon(Icons.chevron_left),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 8),
                        Text('$progressed מתוך ${roomItems.length} פריטים בתהליך · ${(progress * 100).round()}%'),
                      ],
                    ),
                  ),
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
