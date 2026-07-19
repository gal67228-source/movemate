import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/moves/domain/move_plan.dart';

void main() {
  test('legacy move data receives identity defaults', () {
    final move = MovePlan.fromJson({
      'id': 'move-1',
      'name': 'המעבר שלנו',
      'moveDate': '2026-08-01T00:00:00.000',
      'roomCount': 3,
    });

    expect(move.ownerUid, isNull);
    expect(move.plan, 'FREE');
    expect(move.createdAt, isNotNull);
    expect(move.updatedAt, isNotNull);
  });

  test('copyWith assigns an owner without losing move data', () {
    final createdAt = DateTime(2026, 7, 1);
    final move = MovePlan(
      id: 'move-1',
      name: 'המעבר שלנו',
      fromAddress: 'ישן',
      toAddress: 'חדש',
      moveDate: DateTime(2026, 8, 1),
      roomCount: 3,
      hasStorage: true,
      hasBalcony: false,
      hasElevator: true,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final owned = move.copyWith(ownerUid: 'google-user-1');

    expect(owned.ownerUid, 'google-user-1');
    expect(owned.name, move.name);
    expect(owned.createdAt, createdAt);
    expect(owned.plan, 'FREE');
  });
}
