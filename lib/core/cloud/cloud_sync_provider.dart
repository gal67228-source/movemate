import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import 'cloud_sync_service.dart';

final cloudSyncProvider = FutureProvider<void>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final service = CloudSyncService(database: database);
  ref.onDispose(() {
    service.dispose();
  });
  await service.start();
});
