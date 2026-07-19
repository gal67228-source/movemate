import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/tasks/domain/move_task.dart';

void main() {
  test('calculates task progress', () {
    final now = DateTime(2026, 7, 14);
    final tasks = [
      MoveTask(
        id: '1',
        moveId: 'move',
        title: 'א',
        description: '',
        dueDate: null,
        priority: TaskPriority.medium,
        category: TaskCategory.general,
        isCompleted: true,
        createdAt: now,
      ),
      MoveTask(
        id: '2',
        moveId: 'move',
        title: 'ב',
        description: '',
        dueDate: null,
        priority: TaskPriority.high,
        category: TaskCategory.packing,
        isCompleted: false,
        createdAt: now,
      ),
    ];

    final stats = calculateTaskStats(tasks);
    expect(stats.total, 2);
    expect(stats.completed, 1);
    expect(stats.open, 1);
    expect(stats.progress, 0.5);
  });
}
