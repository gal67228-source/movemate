import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/packing/domain/packing_models.dart';

void main() {
  test('packing progress is calculated from packed items', () {
    const stats = PackingStats(
      totalItems: 4,
      packedItems: 3,
      boxes: 2,
      closedBoxes: 1,
    );

    expect(stats.progress, 0.75);
  });

  test('empty packing list has zero progress', () {
    const stats = PackingStats(
      totalItems: 0,
      packedItems: 0,
      boxes: 0,
      closedBoxes: 0,
    );

    expect(stats.progress, 0);
  });
}
