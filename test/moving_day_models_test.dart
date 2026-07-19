import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/moving_day/domain/moving_day_models.dart';

void main() {
  test('moving day item serializes and restores its status', () {
    final item = MovingDayItem(
      id: 'item-1',
      moveId: 'move-1',
      title: 'מפתחות',
      status: MovingDayItemStatus.arrived,
      createdAt: DateTime(2026, 7, 16),
      notes: 'בתיק הכחול',
      isCustom: true,
    );

    final restored = MovingDayItem.fromJson(item.toJson());

    expect(restored.id, item.id);
    expect(restored.title, 'מפתחות');
    expect(restored.status, MovingDayItemStatus.arrived);
    expect(restored.notes, 'בתיק הכחול');
    expect(restored.isCustom, isTrue);
  });

  test('moving day checklist progress is calculated correctly', () {
    const stats = MovingDayStats(
      totalBoxes: 10,
      loadedBoxes: 7,
      arrivedBoxes: 5,
      unpackedBoxes: 2,
      totalChecklistItems: 8,
      checkedChecklistItems: 6,
      openTodayTasks: 1,
      unpackedInventoryItems: 4,
    );

    expect(stats.boxesStillAtHome, 3);
    expect(stats.checklistProgress, 0.75);
  });
}
