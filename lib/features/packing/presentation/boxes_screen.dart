import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/media_thumbnail.dart';
import '../data/packing_repository.dart';
import '../domain/packing_models.dart';

class BoxesScreen extends ConsumerStatefulWidget {
  const BoxesScreen({super.key});

  @override
  ConsumerState<BoxesScreen> createState() => _BoxesScreenState();
}

class _BoxesScreenState extends ConsumerState<BoxesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteBox(MovingBox box) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('מחיקת ארגז ${box.number}'),
        content: const Text('הארגז וכל פרטי התכולה שלו יימחקו.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('מחיקה'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final repository = await ref.read(packingRepositoryProvider.future);
    await repository.deleteBox(box.id);
    ref.invalidate(movingBoxesProvider);
    ref.invalidate(packingItemsProvider);
    ref.invalidate(packingStatsProvider);
  }

  Future<void> _advanceStatus(MovingBox box) async {
    final nextIndex = (box.status.index + 1) % MovingBoxStatus.values.length;
    final nextStatus = MovingBoxStatus.values[nextIndex];
    final now = DateTime.now();
    final repository = await ref.read(packingRepositoryProvider.future);
    await repository.upsertBox(
      box.copyWith(
        status: nextStatus,
        packedAt: nextStatus == MovingBoxStatus.preparing
            ? box.packedAt
            : box.packedAt ?? now,
        unpackedAt:
            nextStatus == MovingBoxStatus.unpacked ? box.unpackedAt ?? now : null,
      ),
    );
    ref.invalidate(movingBoxesProvider);
    ref.invalidate(packingItemsProvider);
    ref.invalidate(packingStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final boxesAsync = ref.watch(movingBoxesProvider);
    final roomsAsync = ref.watch(roomsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ארגזים'),
        actions: [
          IconButton(
            tooltip: 'סריקת QR',
            onPressed: () => context.push('/boxes/scan'),
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      body: boxesAsync.when(
        data: (boxes) => roomsAsync.when(
          data: (rooms) {
            final roomNames = {for (final room in rooms) room.id: room.name};
            final filtered = boxes
                .where(
                  (box) => box.matches(
                    _query,
                    roomNames[box.roomId] ?? '',
                  ),
                )
                .toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'חיפוש לפי פריט, חדר או מספר ארגז',
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (_query.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                    ],
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _BoxSummary(boxes: boxes),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            boxes.isEmpty
                                ? 'עדיין לא יצרת ארגזים'
                                : 'לא נמצאו ארגזים מתאימים',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final box = filtered[index];
                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => context.push(
                                  '/boxes/edit?id=${box.id}',
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      box.imageUri == null
                                          ? CircleAvatar(child: Text('${box.number}'))
                                          : MediaThumbnail(
                                              uri: box.imageUri,
                                              size: 52,
                                              borderRadius: 26,
                                            ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              box.name.isEmpty
                                                  ? 'ארגז ${box.number}'
                                                  : 'ארגז ${box.number} · ${box.name}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              roomNames[box.roomId] ??
                                                  'ללא חדר',
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              box.contents.isEmpty
                                                  ? 'ללא תכולה רשומה'
                                                  : box.contents.join(', '),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: [
                                                Chip(
                                                  label: Text(box.status.label),
                                                  avatar: const Icon(
                                                    Icons.local_shipping_outlined,
                                                    size: 18,
                                                  ),
                                                ),
                                                Chip(
                                                  label: Text(box.weight.label),
                                                ),
                                                if (box.fragile)
                                                  const Chip(
                                                    label: Text('שביר'),
                                                    avatar: Icon(
                                                      Icons.warning_amber_rounded,
                                                      size: 18,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'status') {
                                            _advanceStatus(box);
                                          } else if (value == 'edit') {
                                            context.push(
                                              '/boxes/edit?id=${box.id}',
                                            );
                                          } else if (value == 'delete') {
                                            _deleteBox(box);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'status',
                                            child: Text('התקדם לסטטוס הבא'),
                                          ),
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('עריכה'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('מחיקה'),
                                          ),
                                        ],
                                      ),
                                    ],
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
        onPressed: () => context.push('/boxes/edit'),
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('ארגז חדש'),
      ),
    );
  }
}

class _BoxSummary extends StatelessWidget {
  const _BoxSummary({required this.boxes});

  final List<MovingBox> boxes;

  @override
  Widget build(BuildContext context) {
    final packed = boxes.where((box) => box.isClosed).length;
    final fragile = boxes.where((box) => box.fragile).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text('${boxes.length} ארגזים')),
          Text('$packed מוכנים · $fragile שבירים'),
        ],
      ),
    );
  }
}
