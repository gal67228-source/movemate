import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/core/database/app_database.dart';
import 'package:movemate/core/storage/legacy_preferences_migrator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('legacy data is copied to Drift once without overwriting data', () async {
    SharedPreferences.setMockInitialValues({
      'tasks': '[{"id":"legacy"}]',
    });
    final preferences = await SharedPreferences.getInstance();
    final database = AppDatabase.inMemory();
    addTearDown(database.close);

    await database.putEntry('move', '{"name":"existing"}');
    final migrator = LegacyPreferencesMigrator(
      preferences: preferences,
      database: database,
    );

    await migrator.migrateIfNeeded();
    final entries = await database.readAllEntries();

    expect(entries['tasks'], '[{"id":"legacy"}]');
    expect(entries['move'], '{"name":"existing"}');
    expect(preferences.getBool('drift_migration_complete_v1'), isTrue);
  });
}
