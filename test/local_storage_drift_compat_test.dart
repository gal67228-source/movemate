import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/core/database/app_database.dart';
import 'package:movemate/core/storage/local_storage.dart';

void main() {
  test('application data is persisted and restored from Drift', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);

    final storage = await LocalStorage.open(database);
    await storage.writeObject('move', {'name': 'מעבר בדיקה'});
    await storage.writeObjectList('tasks', [
      {'id': '1', 'title': 'לארוז'},
    ]);

    final restored = await LocalStorage.open(database);
    expect(restored.readObject('move')?['name'], 'מעבר בדיקה');
    expect(restored.readObjectList('tasks').single['title'], 'לארוז');
  });
}
