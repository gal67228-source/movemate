import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/packing/domain/packing_models.dart';

void main() {
  test('migrates legacy packing status', () {
    final item = PackingItem.fromJson({
      'id': 'item-1',
      'moveId': 'move-1',
      'roomId': 'room-1',
      'name': 'סכו״ם',
      'status': 'packed',
      'destination': 'moving',
      'createdAt': '2026-07-15T00:00:00.000',
    });

    expect(item.status, PackingStatus.packed);
    expect(item.linkedBoxId, isNull);
    expect(item.isLarge, isFalse);
  });
}
