import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../moves/data/move_repository.dart';
import '../../packing/data/packing_repository.dart';
import '../../packing/domain/packing_models.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/domain/move_task.dart';
import '../data/moving_day_repository.dart';
import '../domain/moving_day_models.dart';

class MovingDayScreen extends ConsumerWidget {
  const MovingDayScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(movingDayItemsProvider);
    ref.invalidate(movingDayStatsProvider);
    ref.invalidate(movingBoxesProvider);
    ref.invalidate(packingItemsProvider);
    ref.invalidate(tasksProvider);
    await ref.read(movingDayStatsProvider.future);
  }

  Future<void> _setBoxStatus(
    WidgetRef ref,
    MovingBox box,
    MovingBoxStatus status,
  ) async {
    final repository = await ref.read(packingRepositoryProvider.future);
    await repository.upsertBox(
      box.copyWith(
        status: status,
        packedAt: status.index >= MovingBoxStatus.packed.index
            ? box.packedAt ?? DateTime.now()
            : box.packedAt,
        unpackedAt: status == MovingBoxStatus.unpacked
            ? DateTime.now()
            : box.unpackedAt,
      ),
    );
    await _refresh(ref);
  }

  Future<void> _toggleTask(WidgetRef ref, MoveTask task) async {
    final repository = await ref.read(taskRepositoryProvider.future);
    await repository.upsert(task.copyWith(isCompleted: !task.isCompleted));
    await _refresh(ref);
  }

  Future<void> _setChecklistStatus(
    WidgetRef ref,
    MovingDayItem item,
    MovingDayItemStatus status,
  ) async {
    final repository = await ref.read(movingDayRepositoryProvider.future);
    await repository.upsert(item.copyWith(status: status));
    await _refresh(ref);
  }

  Future<void> _addChecklistItem(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('פריט חדש ליום המעבר'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'שם הפריט',
              hintText: 'לדוגמה: מזון לחתול',
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(dialogContext).pop(trimmed);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isNotEmpty) {
                  Navigator.of(dialogContext).pop(trimmed);
                }
              },
              child: const Text('הוסף'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (title == null) {
      return;
    }
    final items = await ref.read(movingDayItemsProvider.future);
    final moveId = items.isEmpty
        ? (await ref.read(currentMoveProvider.future))?.id
        : items.first.moveId;
    if (moveId == null) {
      return;
    }
    final repository = await ref.read(movingDayRepositoryProvider.future);
    await repository.upsert(
      MovingDayItem(
        id: 'moving_day_custom_${DateTime.now().microsecondsSinceEpoch}',
        moveId: moveId,
        title: title,
        status: MovingDayItemStatus.waiting,
        createdAt: DateTime.now(),
        isCustom: true,
      ),
    );
    await _refresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(movingDayStatsProvider);
    final boxesAsync = ref.watch(movingBoxesProvider);
    final checklistAsync = ref.watch(movingDayItemsProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('יום המעבר'),
        actions: [
          IconButton(
            tooltip: 'חיפוש',
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addChecklistItem(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('פריט חשוב'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            statsAsync.when(
              data: (stats) => _SummarySection(stats: stats),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('לא ניתן לטעון סיכום: $error'),
            ),
            const SizedBox(height: 20),
            Text(
              'ארגזים',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            boxesAsync.when(
              data: (boxes) {
                if (boxes.isEmpty) {
                  return _EmptyCard(
                    icon: Icons.inventory_2_outlined,
                    text: 'עדיין לא נוצרו ארגזים.',
                    actionText: 'למסך הארגזים',
                    onPressed: () => context.push('/boxes'),
                  );
                }
                return Column(
                  children: boxes.map((box) {
                    return _BoxMovingCard(
                      box: box,
                      onStatusChanged: (status) {
                        return _setBoxStatus(ref, box, status);
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('לא ניתן לטעון ארגזים: $error'),
            ),
            const SizedBox(height: 20),
            Text(
              'משימות דחופות',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            tasksAsync.when(
              data: (tasks) {
                final urgentTasks = _urgentTasks(tasks);
                if (urgentTasks.isEmpty) {
                  return const _EmptyCard(
                    icon: Icons.task_alt_rounded,
                    text: 'אין משימות פתוחות להיום או באיחור.',
                  );
                }
                return Card(
                  child: Column(
                    children: urgentTasks.map((task) {
                      return CheckboxListTile(
                        value: task.isCompleted,
                        onChanged: (_) => _toggleTask(ref, task),
                        title: Text(task.title),
                        subtitle: Text(_taskDueLabel(task)),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('לא ניתן לטעון משימות: $error'),
            ),
            const SizedBox(height: 20),
            Text(
              'צ׳קליסט ופריטים חשובים',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            checklistAsync.when(
              data: (items) => Card(
                child: Column(
                  children: items.map((item) {
                    return _ChecklistTile(
                      item: item,
                      onStatusChanged: (status) {
                        return _setChecklistStatus(ref, item, status);
                      },
                    );
                  }).toList(),
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('לא ניתן לטעון צ׳קליסט: $error'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.stats});

  final MovingDayStats stats;

  @override
  Widget build(BuildContext context) {
    final warnings = <String>[];
    if (stats.boxesStillAtHome > 0) {
      warnings.add('${stats.boxesStillAtHome} ארגזים עדיין לא הועמסו');
    }
    if (stats.openTodayTasks > 0) {
      warnings.add('${stats.openTodayTasks} משימות דחופות פתוחות');
    }
    if (stats.unpackedInventoryItems > 0) {
      warnings.add('${stats.unpackedInventoryItems} יחידות ציוד עדיין לא נפרקו');
    }

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.7,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _SummaryCard(
              icon: Icons.local_shipping_outlined,
              value: '${stats.loadedBoxes}/${stats.totalBoxes}',
              label: 'ארגזים הועמסו',
            ),
            _SummaryCard(
              icon: Icons.home_work_outlined,
              value: '${stats.arrivedBoxes}/${stats.totalBoxes}',
              label: 'ארגזים הגיעו',
            ),
            _SummaryCard(
              icon: Icons.inventory_outlined,
              value: '${stats.unpackedBoxes}/${stats.totalBoxes}',
              label: 'ארגזים נפרקו',
            ),
            _SummaryCard(
              icon: Icons.fact_check_outlined,
              value:
                  '${stats.checkedChecklistItems}/${stats.totalChecklistItems}',
              label: 'פריטים נבדקו',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warnings.isEmpty ? 'הכול בשליטה' : 'דורש תשומת לב',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                if (warnings.isEmpty)
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded),
                      SizedBox(width: 8),
                      Expanded(child: Text('לא נמצאו דברים דחופים כרגע.')),
                    ],
                  )
                else
                  ...warnings.map((warning) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(warning)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(label, maxLines: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoxMovingCard extends StatelessWidget {
  const _BoxMovingCard({
    required this.box,
    required this.onStatusChanged,
  });

  final MovingBox box;
  final Future<void> Function(MovingBoxStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    box.name.trim().isEmpty
                        ? 'ארגז ${box.number}'
                        : 'ארגז ${box.number} · ${box.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(label: Text(box.status.label)),
              ],
            ),
            if (box.contents.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                box.contents.take(4).join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            SegmentedButton<MovingBoxStatus>(
              segments: const [
                ButtonSegment(
                  value: MovingBoxStatus.packed,
                  label: Text('מוכן'),
                ),
                ButtonSegment(
                  value: MovingBoxStatus.loaded,
                  label: Text('הועמס'),
                ),
                ButtonSegment(
                  value: MovingBoxStatus.arrived,
                  label: Text('הגיע'),
                ),
                ButtonSegment(
                  value: MovingBoxStatus.unpacked,
                  label: Text('נפרק'),
                ),
              ],
              selected: <MovingBoxStatus>{
                box.status == MovingBoxStatus.preparing
                    ? MovingBoxStatus.packed
                    : box.status,
              },
              onSelectionChanged: (selection) {
                onStatusChanged(selection.first);
              },
              showSelectedIcon: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.item,
    required this.onStatusChanged,
  });

  final MovingDayItem item;
  final Future<void> Function(MovingDayItemStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_statusIcon(item.status)),
      title: Text(item.title),
      subtitle: item.notes.isEmpty ? null : Text(item.notes),
      trailing: DropdownButton<MovingDayItemStatus>(
        value: item.status,
        underline: const SizedBox.shrink(),
        items: MovingDayItemStatus.values.map((status) {
          return DropdownMenuItem(
            value: status,
            child: Text(status.label),
          );
        }).toList(),
        onChanged: (status) {
          if (status != null) {
            onStatusChanged(status);
          }
        },
      ),
    );
  }

  IconData _statusIcon(MovingDayItemStatus status) {
    return switch (status) {
      MovingDayItemStatus.waiting => Icons.radio_button_unchecked_rounded,
      MovingDayItemStatus.loaded => Icons.local_shipping_outlined,
      MovingDayItemStatus.arrived => Icons.home_work_outlined,
      MovingDayItemStatus.checked => Icons.check_circle_rounded,
    };
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.text,
    this.actionText,
    this.onPressed,
  });

  final IconData icon;
  final String text;
  final String? actionText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
            if (actionText != null)
              TextButton(onPressed: onPressed, child: Text(actionText!)),
          ],
        ),
      ),
    );
  }
}

List<MoveTask> _urgentTasks(List<MoveTask> tasks) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return tasks.where((task) {
    if (task.isCompleted || task.dueDate == null) {
      return false;
    }
    final due = task.dueDate!;
    final dueOnly = DateTime(due.year, due.month, due.day);
    return !dueOnly.isAfter(today);
  }).toList();
}

String _taskDueLabel(MoveTask task) {
  final due = task.dueDate;
  if (due == null) {
    return 'ללא תאריך';
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueOnly = DateTime(due.year, due.month, due.day);
  final difference = dueOnly.difference(today).inDays;
  if (difference < 0) {
    return 'באיחור של ${difference.abs()} ימים';
  }
  return 'להיום';
}
