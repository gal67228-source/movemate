import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class AppStorageEntries extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [AppStorageEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'movemate'));

  /// In-memory database used by unit and widget tests.
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  Future<Map<String, String>> readAllEntries() async {
    final rows = await select(appStorageEntries).get();
    return {for (final row in rows) row.key: row.value};
  }

  Future<void> putEntry(String key, String value) {
    return into(appStorageEntries).insertOnConflictUpdate(
      AppStorageEntriesCompanion.insert(
        key: key,
        value: value,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteEntry(String key) {
    return (delete(appStorageEntries)..where((row) => row.key.equals(key))).go();
  }
}
