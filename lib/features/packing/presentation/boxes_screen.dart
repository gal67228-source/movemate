import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../moves/data/move_repository.dart';
import '../data/packing_repository.dart';
import '../domain/packing_models.dart';

class BoxesScreen extends ConsumerWidget {
  const BoxesScreen({super.key});

  Future<void> _addBox(BuildContext context, WidgetRef ref) async {
    final rooms = await ref.read(roomsProvider.future);
    final boxes = await ref.read(movingBoxesProvider.future);
    if (rooms.isEmpty || !context.mounted) return;
    final contentsController = TextEditingController();
    var selectedRoom = rooms.first.id;
    var fragile = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('ארגז ${boxes.length + 1}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedRoom,
                decoration: const InputDecoration(labelText: 'חדר יעד'),
                items: rooms
                    .map((room) => DropdownMenuItem(value: room.id, child: Text(room.name)))
                    .toList(),
                onChanged: (value) => setState(() => selectedRoom = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'תכולה',
                  hintText: 'הפרד פריטים בפסיקים',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: fragile,
                title: const Text('ארגז שביר'),
                onChanged: (value) => setState(() => fragile = value),
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
    if (saved != true) return;
    final move = await ref.read(currentMoveProvider.future);
    final repository = await ref.read(packingRepositoryProvider.future);
    if (move == null) return;
    final contents = contentsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    await repository.upsertBox(
      MovingBox(
        id: 'box_${DateTime.now().microsecondsSinceEpoch}',
        moveId: move.id,
        roomId: selectedRoom,
        number: boxes.isEmpty ? 1 : boxes.last.number + 1,
        contents: contents,
        fragile: fragile,
        isClosed: false,
        createdAt: DateTime.now(),
      ),
    );
    ref.invalidate(movingBoxesProvider);
    ref.invalidate(packingStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boxesAsync = ref.watch(movingBoxesProvider);
    final roomsAsync = ref.watch(roomsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ארגזים')),
      body: boxesAsync.when(
        data: (boxes) => roomsAsync.when(
          data: (rooms) {
            final roomNames = {for (final room in rooms) room.id: room.name};
            if (boxes.isEmpty) return const Center(child: Text('עדיין לא יצרת ארגזים'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: boxes.length,
              itemBuilder: (context, index) {
                final box = boxes[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${box.number}')),
                    title: Text('ארגז ${box.number} · ${roomNames[box.roomId] ?? 'ללא חדר'}'),
                    subtitle: Text(
                      box.contents.isEmpty ? 'ללא תכולה רשומה' : box.contents.join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: box.fragile,
                    trailing: Checkbox(
                      value: box.isClosed,
                      onChanged: (value) async {
                        final repository = await ref.read(packingRepositoryProvider.future);
                        await repository.upsertBox(box.copyWith(isClosed: value ?? false));
                        ref.invalidate(movingBoxesProvider);
                        ref.invalidate(packingStatsProvider);
                      },
                    ),
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
        onPressed: () => _addBox(context, ref),
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('ארגז חדש'),
      ),
    );
  }
}
