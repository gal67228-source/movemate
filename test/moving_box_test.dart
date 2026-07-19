import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/packing/domain/packing_models.dart';

void main() {
  final box = MovingBox(
    id: 'box-1',
    moveId: 'move-1',
    roomId: 'room-1',
    number: 18,
    name: 'אלקטרוניקה',
    contents: const ['מטען למחשב', 'כבלים'],
    fragile: true,
    weight: MovingBoxWeight.medium,
    status: MovingBoxStatus.packed,
    notes: 'מדף עליון',
    createdAt: DateTime(2026, 7, 14),
  );

  test('box search matches content, number and room', () {
    expect(box.matches('מטען', 'חדר עבודה'), isTrue);
    expect(box.matches('18', 'חדר עבודה'), isTrue);
    expect(box.matches('עבודה', 'חדר עבודה'), isTrue);
    expect(box.matches('קומקום', 'חדר עבודה'), isFalse);
  });

  test('legacy JSON remains supported', () {
    final legacy = MovingBox.fromJson({
      'id': 'legacy',
      'moveId': 'move',
      'roomId': 'room',
      'number': 1,
      'contents': <String>['ספרים'],
      'fragile': false,
      'isClosed': true,
      'createdAt': '2026-07-14T10:00:00.000',
    });

    expect(legacy.status, MovingBoxStatus.packed);
    expect(legacy.weight, MovingBoxWeight.medium);
    expect(legacy.name, isEmpty);
  });
}
