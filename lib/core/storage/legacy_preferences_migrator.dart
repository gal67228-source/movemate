import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';

const _migrationCompleteKey = 'drift_migration_complete_v1';

/// Imports legacy application data from SharedPreferences into Drift exactly
/// once. Legacy values are kept as a recovery copy until a later release.
class LegacyPreferencesMigrator {
  LegacyPreferencesMigrator({
    required SharedPreferences preferences,
    required AppDatabase database,
  }) : _preferences = preferences,
       _database = database;

  final SharedPreferences _preferences;
  final AppDatabase _database;

  Future<void> migrateIfNeeded() async {
    if (_preferences.getBool(_migrationCompleteKey) == true) {
      return;
    }

    final existingEntries = await _database.readAllEntries();
    for (final key in _preferences.getKeys()) {
      if (key == _migrationCompleteKey || existingEntries.containsKey(key)) {
        continue;
      }

      final value = _preferences.getString(key);
      if (value != null) {
        await _database.putEntry(key, value);
      }
    }

    await _preferences.setBool(_migrationCompleteKey, true);
  }
}
