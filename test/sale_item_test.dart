import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/sales/domain/sale_item.dart';

void main() {
  SaleItem item({
    String id = '1',
    String title = 'טלוויזיה',
    int askingPriceShekels = 1000,
    int? soldPriceShekels,
    SaleStatus status = SaleStatus.published,
  }) {
    return SaleItem(
      id: id,
      moveId: 'move-1',
      title: title,
      description: 'Samsung',
      category: SaleCategory.electronics,
      askingPriceShekels: askingPriceShekels,
      soldPriceShekels: soldPriceShekels,
      status: status,
      buyerName: '',
      notes: '',
      createdAt: DateTime(2026),
      publishedAt: DateTime(2026),
      soldAt: status == SaleStatus.sold ? DateTime(2026, 2) : null,
    );
  }

  test('calculates expected and actual sale revenue in shekels', () {
    final stats = calculateSaleStats([
      item(),
      item(
        id: '2',
        askingPriceShekels: 800,
        soldPriceShekels: 700,
        status: SaleStatus.sold,
      ),
    ]);

    expect(stats.totalItems, 2);
    expect(stats.activeItems, 1);
    expect(stats.soldItems, 1);
    expect(stats.expectedRevenueShekels, 1000);
    expect(stats.actualRevenueShekels, 700);
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
    expect(legacy.askingPriceShekels, 450);
    expect(legacy.soldPriceShekels, 400);
    expect(legacy.status, SaleStatus.sold);
  });

  test('migrates previous agorot values to whole shekels', () {
    final previous = SaleItem.fromJson({
      'id': 'previous',
      'moveId': 'move-1',
      'title': 'ספה',
      'askingPriceAgorot': 125000,
      'soldPriceAgorot': 110000,
      'status': 'sold',
    });

    expect(previous.askingPriceShekels, 1250);
    expect(previous.soldPriceShekels, 1100);
  });

  test('searches by title, description and category', () {
    final saleItem = item();

    expect(saleItem.matches('טלוויזיה'), isTrue);
    expect(saleItem.matches('samsung'), isTrue);
    expect(saleItem.matches('אלקטרוניקה'), isTrue);
    expect(saleItem.matches('ספה'), isFalse);
  });
}
