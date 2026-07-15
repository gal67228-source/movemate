import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/sales/domain/sale_item.dart';

void main() {
  SaleItem item({
    String id = '1',
    String title = 'טלוויזיה',
    int askingPriceAgorot = 100000,
    int? soldPriceAgorot,
    SaleStatus status = SaleStatus.published,
  }) {
    return SaleItem(
      id: id,
      moveId: 'move-1',
      title: title,
      description: 'Samsung',
      category: SaleCategory.electronics,
      askingPriceAgorot: askingPriceAgorot,
      soldPriceAgorot: soldPriceAgorot,
      status: status,
      buyerName: '',
      notes: '',
      createdAt: DateTime(2026),
      publishedAt: DateTime(2026),
      soldAt: status == SaleStatus.sold ? DateTime(2026, 2) : null,
    );
  }

  test('calculates expected and actual sale revenue', () {
    final stats = calculateSaleStats([
      item(),
      item(
        id: '2',
        askingPriceAgorot: 80000,
        soldPriceAgorot: 70000,
        status: SaleStatus.sold,
      ),
    ]);

    expect(stats.totalItems, 2);
    expect(stats.activeItems, 1);
    expect(stats.soldItems, 1);
    expect(stats.expectedRevenueAgorot, 100000);
    expect(stats.actualRevenueAgorot, 70000);
  });

  test('loads legacy shekel prices and sold flag', () {
    final legacy = SaleItem.fromJson({
      'id': 'legacy',
      'moveId': 'move-1',
      'name': 'שולחן',
      'askingPrice': 450,
      'soldPrice': 400,
      'sold': true,
      'createdAt': '2026-01-01T00:00:00.000',
    });

    expect(legacy.title, 'שולחן');
    expect(legacy.askingPriceAgorot, 45000);
    expect(legacy.soldPriceAgorot, 40000);
    expect(legacy.status, SaleStatus.sold);
  });

  test('searches by title, description and category', () {
    final saleItem = item();

    expect(saleItem.matches('טלוויזיה'), isTrue);
    expect(saleItem.matches('samsung'), isTrue);
    expect(saleItem.matches('אלקטרוניקה'), isTrue);
    expect(saleItem.matches('ספה'), isFalse);
  });
}
