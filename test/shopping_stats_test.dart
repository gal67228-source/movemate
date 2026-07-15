import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/shopping/domain/shopping_item.dart';

void main() {
  ShoppingItem item({required String id, required ShoppingStatus status, int estimated = 100, int? actual, int quantity = 1}) => ShoppingItem(
        id: id,
        moveId: 'move-1',
        title: 'פריט',
        category: ShoppingCategory.packing,
        quantity: quantity,
        estimatedPriceShekels: estimated,
        actualPriceShekels: actual,
        status: status,
        notes: '',
        createdAt: DateTime(2026),
      );

  test('calculates shopping totals in whole shekels', () {
    final stats = calculateShoppingStats([
      item(id: '1', status: ShoppingStatus.needed, estimated: 50, quantity: 2),
      item(id: '2', status: ShoppingStatus.purchased, estimated: 80, actual: 70),
    ]);
    expect(stats.total, 2);
    expect(stats.purchased, 1);
    expect(stats.estimatedTotalShekels, 180);
    expect(stats.actualTotalShekels, 70);
    expect(stats.progress, 0.5);
  });
}
