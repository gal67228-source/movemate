import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/packing/domain/packing_models.dart';

void main() {
  test('legacy packing item without image remains supported', () {
    final item = PackingItem.fromJson({
      'id': 'item_1',
      'moveId': 'move_1',
      'roomId': 'room_1',
      'name': 'קומקום',
      'status': 'atHome',
      'destination': 'moving',
      'createdAt': DateTime(2026).toIso8601String(),
    });

    expect(item.imageUri, isNull);
  });

  test('box image URI is serialized and restored', () {
    final box = MovingBox(
      id: 'box_1',
      moveId: 'move_1',
      roomId: 'room_1',
      number: 1,
      name: 'מטבח',
      contents: const ['קומקום'],
      fragile: false,
      weight: MovingBoxWeight.medium,
      status: MovingBoxStatus.packed,
      notes: '',
      createdAt: DateTime(2026),
      imageUri: 'https://example.com/box.jpg',
    );

    expect(MovingBox.fromJson(box.toJson()).imageUri, box.imageUri);
  });
}
