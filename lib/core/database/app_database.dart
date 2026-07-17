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

class StorageRecord {
  const StorageRecord({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  final String key;
  final String value;
  final DateTime updatedAt;
}

@DriftDatabase(tables: [AppStorageEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(driftDatabase(name: 'movemate'));

  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  Future<Map<String, String>> readAllEntries() async {
    final rows = await select(appStorageEntries).get();
    return {for (final row in rows) row.key: row.value};
  }

  Future<Map<String, StorageRecord>> readAllRecords() async {
    final rows = await select(appStorageEntries).get();
    return {
      for (final row in rows)
        row.key: StorageRecord(
          key: row.key,
          value: row.value,
          updatedAt: row.updatedAt,
        ),
    };
  }

  Future<void> putEntry(
    String key,
    String value, {
    DateTime? updatedAt,
  }) {
    return into(appStorageEntries).insertOnConflictUpdate(
      AppStorageEntriesCompanion.insert(
        key: key,
        value: value,
        updatedAt: Value(updatedAt ?? DateTime.now()),
      ),
    );
  }

  Future<void> replaceAllRecords(Iterable<StorageRecord> records) async {
    await transaction(() async {
      await delete(appStorageEntries).go();
      for (final record in records) {
        await putEntry(
          record.key,
          record.value,
          updatedAt: record.updatedAt,
        );
      }
    });
  }

  Future<void> deleteEntry(String key) {
    return (delete(appStorageEntries)..where((row) => row.key.equals(key))).go();
  }
}
