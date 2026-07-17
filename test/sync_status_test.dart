import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/core/sync/cloud_sync_service.dart';

void main() {
  test('sync status copyWith preserves values', () {
    final time = DateTime(2026, 7, 17, 12);
    final status = SyncStatus(
      available: true,
      syncing: false,
      pendingWrites: 2,
      lastSyncedAt: time,
    );

    final updated = status.copyWith(syncing: true, pendingWrites: 1);

    expect(updated.available, isTrue);
    expect(updated.syncing, isTrue);
    expect(updated.pendingWrites, 1);
    expect(updated.lastSyncedAt, time);
  });

  test('disabled sync status is unavailable', () {
    const status = SyncStatus.disabled();
    expect(status.available, isFalse);
    expect(status.syncing, isFalse);
    expect(status.pendingWrites, 0);
  });
}
