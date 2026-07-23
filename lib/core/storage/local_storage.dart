import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_providers.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../sync/cloud_sync_service.dart';
import 'legacy_preferences_migrator.dart';

final storageRevisionProvider = StateProvider<int>((ref) => 0);

final legacyPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// Drift-backed storage facade used by feature repositories.
///
/// Drift is the local source of truth. When a signed-in Firebase user exists,
/// writes are also sent to Cloud Firestore and remote updates refresh the
/// in-memory cache used by the existing synchronous repository API.
class LocalStorage {
  LocalStorage._(this._database, this._cache, this._updatedAt);

  final AppDatabase _database;
  final Map<String, String> _cache;
  final Map<String, DateTime> _updatedAt;
  CloudSyncService? _cloudSync;

  CloudSyncService? get cloudSync => _cloudSync;

  static Future<LocalStorage> open(AppDatabase database) async {
    final records = await database.readAllRecords();
    return LocalStorage._(
      database,
      {for (final record in records.values) record.key: record.value},
      {for (final record in records.values) record.key: record.updatedAt},
    );
  }

  Future<void> attachCloudSync(CloudSyncService service) async {
    _cloudSync = service;
    await service.initialize(await _database.readAllRecords());
  }

  Map<String, Object?>? readObject(String key) {
    final value = _cache[key];
    if (value == null) {
      return null;
    }
    return Map<String, Object?>.from(jsonDecode(value) as Map);
  }

  List<Map<String, Object?>> readObjectList(String key) {
    final value = _cache[key];
    if (value == null) {
      return [];
    }
    return (jsonDecode(value) as List)
        .map((item) => Map<String, Object?>.from(item as Map))
        .toList();
  }

  String? readString(String key) => _cache[key];

  Future<void> writeString(String key, String value) async {
    if (_cloudSync?.canWrite == false) {
      throw StateError('אין הרשאת עריכה למעבר הזה.');
    }
    final updatedAt = DateTime.now();
    _cache[key] = value;
    _updatedAt[key] = updatedAt;
    await _database.putEntry(key, value, updatedAt: updatedAt);
    await _cloudSync?.push(key, value, updatedAt);
  }

  Future<void> applyRemoteValue(
    String key,
    String value,
    DateTime updatedAt,
  ) async {
    final localTime = _updatedAt[key];
    if (localTime != null && !updatedAt.isAfter(localTime)) {
      return;
    }
    _cache[key] = value;
    _updatedAt[key] = updatedAt;
    await _database.putEntry(key, value, updatedAt: updatedAt);
  }

  Future<void> replaceFromCloud(Iterable<StorageRecord> records) async {
    final recordList = records.toList();
    await _database.replaceAllRecords(recordList);
    _cache
      ..clear()
      ..addEntries(recordList.map((record) => MapEntry(record.key, record.value)));
    _updatedAt
      ..clear()
      ..addEntries(
        recordList.map((record) => MapEntry(record.key, record.updatedAt)),
      );
  }

  Future<void> writeObject(String key, Map<String, Object?> value) {
    return writeString(key, jsonEncode(value));
  }

  Future<void> writeObjectList(
    String key,
    List<Map<String, Object?>> value,
  ) {
    return writeString(key, jsonEncode(value));
  }
}

final localStorageProvider = FutureProvider<LocalStorage>((ref) async {
  ref.watch(storageRevisionProvider);
  final database = ref.watch(appDatabaseProvider);
  final preferences = await ref.watch(legacyPreferencesProvider.future);

  await LegacyPreferencesMigrator(
    preferences: preferences,
    database: database,
  ).migrateIfNeeded();

  final storage = await LocalStorage.open(database);
  final session = await ref.watch(authSessionProvider.future);
  final user = session.user;
  if (user != null && session.firebaseConfigured) {
    final service = CloudSyncService(
      firestore: FirebaseFirestore.instance,
      database: database,
      user: user,
      onRemoteApplied: () {
        Future<void>.microtask(() {
          ref.read(storageRevisionProvider.notifier).state++;
        });
      },
      onRemoteValue: storage.applyRemoteValue,
      onReplaceAll: storage.replaceFromCloud,
    );
    ref.onDispose(() {
      service.dispose();
    });
    await storage.attachCloudSync(service);
  }
  return storage;
});
