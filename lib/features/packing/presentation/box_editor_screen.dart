import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../moves/data/move_repository.dart';
import '../data/packing_repository.dart';
import '../domain/box_qr.dart';
import '../domain/packing_models.dart';

class BoxEditorScreen extends ConsumerStatefulWidget {
  const BoxEditorScreen({super.key, this.boxId});

  final String? boxId;

  @override
  ConsumerState<BoxEditorScreen> createState() => _BoxEditorScreenState();
}

class _BoxEditorScreenState extends ConsumerState<BoxEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contentsController = TextEditingController();
  final _notesController = TextEditingController();

  String? _roomId;
  bool _fragile = false;
  MovingBoxWeight _weight = MovingBoxWeight.medium;
  MovingBoxStatus _status = MovingBoxStatus.preparing;
  MovingBox? _existingBox;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contentsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _load(List<MoveRoom> rooms, List<MovingBox> boxes) {
    if (_loaded) {
      return;
    }
    _loaded = true;
    _roomId = rooms.isEmpty ? null : rooms.first.id;
    if (widget.boxId != null) {
      for (final box in boxes) {
        if (box.id == widget.boxId) {
          _existingBox = box;
          break;
        }
      }
      final box = _existingBox;
      if (box != null) {
        _roomId = box.roomId;
        _nameController.text = box.name;
        _contentsController.text = box.contents.join(', ');
        _notesController.text = box.notes;
        _fragile = box.fragile;
        _weight = box.weight;
        _status = box.status;
      }
    }
  }

  Future<void> _save(List<MovingBox> boxes) async {
    if (!_formKey.currentState!.validate() || _roomId == null) {
      return;
    }
    setState(() => _saving = true);
    final move = await ref.read(currentMoveProvider.future);
    final repository = await ref.read(packingRepositoryProvider.future);
    if (move == null || !mounted) {
      return;
    }
    final now = DateTime.now();
    final contents = _contentsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final previous = _existingBox;
    final box = MovingBox(
      id: previous?.id ?? 'box_${now.microsecondsSinceEpoch}',
      moveId: move.id,
      roomId: _roomId!,
      number: previous?.number ?? _nextBoxNumber(boxes),
      name: _nameController.text.trim(),
      contents: contents,
      fragile: _fragile,
      weight: _weight,
      status: _status,
      notes: _notesController.text.trim(),
      createdAt: previous?.createdAt ?? now,
      packedAt: _status == MovingBoxStatus.preparing
          ? null
          : previous?.packedAt ?? now,
      unpackedAt: _status == MovingBoxStatus.unpacked
          ? previous?.unpackedAt ?? now
          : null,
    );
    await repository.upsertBox(box);
    ref.invalidate(movingBoxesProvider);
    ref.invalidate(packingItemsProvider);
    ref.invalidate(packingStatsProvider);
    if (mounted) {
      context.pop();
    }
  }



  int _nextBoxNumber(List<MovingBox> boxes) {
    if (boxes.isEmpty) {
      return 1;
    }
    return boxes.map((box) => box.number).reduce((a, b) => a > b ? a : b) +
        1;
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);
    final boxesAsync = ref.watch(movingBoxesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boxId == null ? 'ארגז חדש' : 'עריכת ארגז'),
      ),
      body: roomsAsync.when(
        data: (rooms) => boxesAsync.when(
          data: (boxes) {
            _load(rooms, boxes);
            if (rooms.isEmpty) {
              return const Center(
                child: Text('יש ליצור חדר לפני הוספת ארגז'),
              );
            }
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_existingBox != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            QrImageView(
                              data: boxQrPayload(_existingBox!.id),
                              size: 180,
                            ),
                            const SizedBox(height: 8),
                            Text('QR לארגז ${_existingBox!.number}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'שם הארגז (אופציונלי)',
                      hintText: 'למשל: כלי מטבח יומיומיים',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _roomId,
                    decoration: const InputDecoration(labelText: 'חדר יעד'),
                    items: rooms
                        .map(
                          (room) => DropdownMenuItem(
                            value: room.id,
                            child: Text(room.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _roomId = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contentsController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'תכולת הארגז',
                      hintText: 'הפרד בין פריטים באמצעות פסיקים',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'יש להוסיף לפחות פריט אחד';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MovingBoxWeight>(
                    initialValue: _weight,
                    decoration: const InputDecoration(labelText: 'משקל'),
                    items: MovingBoxWeight.values
                        .map(
                          (weight) => DropdownMenuItem(
                            value: weight,
                            child: Text(weight.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _weight = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MovingBoxStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'סטטוס'),
                    items: MovingBoxStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('תכולה שבירה'),
                    subtitle: const Text('יציג סימון בולט ברשימת הארגזים'),
                    value: _fragile,
                    onChanged: (value) => setState(() => _fragile = value),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'הערות',
                      hintText: 'למשל: להניח מעל שאר הארגזים',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : () => _save(boxes),
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('שמירת ארגז'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('שגיאה: $error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('שגיאה: $error')),
      ),
    );
  }
}
