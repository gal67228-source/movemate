import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../moves/data/move_repository.dart';
import '../domain/move_task.dart';

const _tasksKey = 'move_tasks';

class TaskRepository {
  TaskRepository(this._storage);

  final LocalStorage _storage;

  List<MoveTask> getTasks(String moveId) {
    final tasks = _storage.readObjectList(_tasksKey).map(MoveTask.fromJson).where((task) => task.moveId == moveId).toList();
    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      final aDate = a.dueDate ?? DateTime(9999);
      final bDate = b.dueDate ?? DateTime(9999);
      final dateComparison = aDate.compareTo(bDate);
      if (dateComparison != 0) return dateComparison;
      return b.priority.index.compareTo(a.priority.index);
    });
    return tasks;
  }

  Future<void> upsert(MoveTask task) async {
    final all = _storage.readObjectList(_tasksKey).map(MoveTask.fromJson).toList();
    final index = all.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      all.add(task);
    } else {
      all[index] = task;
    }
    await _storage.writeObjectList(_tasksKey, all.map((item) => item.toJson()).toList());
  }

  Future<void> delete(String id) async {
    final all = _storage.readObjectList(_tasksKey).map(MoveTask.fromJson).where((task) => task.id != id).toList();
    await _storage.writeObjectList(_tasksKey, all.map((item) => item.toJson()).toList());
  }

  Future<void> seedDefaults({required String moveId, required DateTime moveDate}) async {
    if (getTasks(moveId).isNotEmpty) return;
    final now = DateTime.now();
    final templates = <({String title, int daysBefore, TaskCategory category, TaskPriority priority})>[
      (title: 'להזמין חברת הובלה', daysBefore: 30, category: TaskCategory.moving, priority: TaskPriority.high),
      (title: 'להתחיל למיין ציוד', daysBefore: 21, category: TaskCategory.packing, priority: TaskPriority.medium),
      (title: 'לקנות חומרי אריזה', daysBefore: 14, category: TaskCategory.shopping, priority: TaskPriority.high),
      (title: 'לעדכן כתובת בשירותים', daysBefore: 7, category: TaskCategory.bureaucracy, priority: TaskPriority.high),
      (title: 'לארוז תיק ליום המעבר', daysBefore: 3, category: TaskCategory.packing, priority: TaskPriority.high),
      (title: 'להפשיר את המקפיא', daysBefore: 1, category: TaskCategory.packing, priority: TaskPriority.medium),
      (title: 'לבדוק שכל הארגזים הועמסו', daysBefore: 0, category: TaskCategory.moving, priority: TaskPriority.high),
    ];
    for (var index = 0; index < templates.length; index++) {
      final template = templates[index];
      final planned = moveDate.subtract(Duration(days: template.daysBefore));
      final dueDate = planned.isBefore(now) ? DateTime(now.year, now.month, now.day) : planned;
      await upsert(
        MoveTask(
          id: 'default_${moveId}_$index',
          moveId: moveId,
          title: template.title,
          description: 'משימה שנוצרה אוטומטית לפי תאריך המעבר.',
          dueDate: dueDate,
          priority: template.priority,
          category: template.category,
          isCompleted: false,
          createdAt: now,
        ),
      );
    }
  }
}

final taskRepositoryProvider = FutureProvider<TaskRepository>((ref) async {
  return TaskRepository(await ref.watch(localStorageProvider.future));
});

final tasksProvider = FutureProvider<List<MoveTask>>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) return [];
  final repository = await ref.watch(taskRepositoryProvider.future);
  return repository.getTasks(move.id);
});

final taskStatsProvider = FutureProvider<TaskStats>((ref) async {
  return calculateTaskStats(await ref.watch(tasksProvider.future));
});
