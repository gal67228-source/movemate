import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

const _migrationCompleteKey = 'drift_migration_complete_v1';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// Compatibility storage facade used by the existing repositories.
///
/// In production, values are persisted in Drift/SQLite. Reads remain
/// synchronous because the complete key-value table is loaded into memory when
/// the provider is initialized. SharedPreferences is retained only for the
/// one-time migration and lightweight unit tests.
class LocalStorage {
  LocalStorage(this._preferences) : _database = null {
    for (final key in _preferences.getKeys()) {
      final value = _preferences.getString(key);
      if (value != null) {
        _cache[key] = value;
      }
    }
  }

  LocalStorage._(this._preferences, this._database);

  final SharedPreferences _preferences;
  final AppDatabase? _database;
  final Map<String, String> _cache = {};

  static Future<LocalStorage> open({
    required SharedPreferences preferences,
    required AppDatabase database,
  }) async {
    final storage = LocalStorage._(preferences, database);
    storage._cache.addAll(await database.readAllEntries());
    await storage._migrateLegacyPreferences();
    return storage;
  }

  Future<void> _migrateLegacyPreferences() async {
    if (_preferences.getBool(_migrationCompleteKey) == true) {
      return;
    }

    for (final key in _preferences.getKeys()) {
      if (key == _migrationCompleteKey || _cache.containsKey(key)) {
        continue;
      }
      final value = _preferences.getString(key);
      if (value == null) {
        continue;
      }
      _cache[key] = value;
      await _database!.putEntry(key, value);
    }

    // The old values are deliberately kept as a recovery copy in v0.97.0.
    // They can be removed in a later release after the migration is verified.
    await _preferences.setBool(_migrationCompleteKey, true);
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
    if (_database != null) {
      await _database.putEntry(key, value);
    } else {
      await _preferences.setString(key, value);
    }
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
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  final database = ref.watch(appDatabaseProvider);
  return LocalStorage.open(preferences: preferences, database: database);
});
