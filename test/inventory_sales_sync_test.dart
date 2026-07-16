import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/packing/domain/packing_models.dart';
import 'package:movemate/features/sales/domain/sale_item.dart';

void main() {
  test('packing item quantity is backward compatible', () {
    final item = PackingItem.fromJson({
      'id': 'item-1',
      'moveId': 'move-1',
      'roomId': 'room-1',
      'name': 'טלוויזיה',
      'status': 'atHome',
      'destination': 'moving',
      'createdAt': DateTime(2026).toIso8601String(),
    });

    expect(item.quantity, 1);
    expect(item.copyWith(quantity: 3).quantity, 3);
  });

  test('sale item stores quantity and packing source', () {
    final item = SaleItem(
      id: 'sale-1',
      moveId: 'move-1',
      title: 'טלוויזיה',
      description: '',
      category: SaleCategory.electronics,
      askingPriceShekels: 1200,
      soldPriceShekels: null,
      status: SaleStatus.draft,
      buyerName: '',
      notes: '',
      createdAt: DateTime(2026),
      publishedAt: null,
      soldAt: null,
      quantity: 3,
      sourcePackingItemId: 'item-1',
    );

    final restored = SaleItem.fromJson(item.toJson());
    expect(restored.quantity, 3);
    expect(restored.sourcePackingItemId, 'item-1');
  });
}
