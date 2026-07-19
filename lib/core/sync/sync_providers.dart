import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_storage.dart';
import 'cloud_sync_service.dart';

final cloudSyncServiceProvider = FutureProvider<CloudSyncService?>((ref) async {
  final storage = await ref.watch(localStorageProvider.future);
  return storage.cloudSync;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) async* {
  final service = await ref.watch(cloudSyncServiceProvider.future);
  if (service == null) {
    yield const SyncStatus.disabled();
    return;
  }
  yield service.status;
  yield* service.statusChanges;
});
