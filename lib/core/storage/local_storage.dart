import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'legacy_preferences_migrator.dart';

final legacyPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// Drift-backed compatibility facade used by the existing repositories.
///
/// Reads stay synchronous by loading the small key-value table into memory at
/// startup. All application data writes are persisted exclusively to Drift.
class LocalStorage {
  LocalStorage._(this._database, this._cache);

  final AppDatabase _database;
  final Map<String, String> _cache;

  static Future<LocalStorage> open(AppDatabase database) async {
    return LocalStorage._(database, await database.readAllEntries());
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
    _cache[key] = value;
    await _database.putEntry(key, value);
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
  final database = ref.watch(appDatabaseProvider);
  final preferences = await ref.watch(legacyPreferencesProvider.future);

  await LegacyPreferencesMigrator(
    preferences: preferences,
    database: database,
  ).migrateIfNeeded();

  return LocalStorage.open(database);
});
