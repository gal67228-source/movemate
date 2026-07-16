import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy LocalStorage remains compatible for repository unit tests', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = LocalStorage(preferences);

    await storage.writeObject('move', {'id': 'move-1'});
    await storage.writeObjectList('tasks', [
      {'id': 'task-1'},
    ]);

    expect(storage.readObject('move'), {'id': 'move-1'});
    expect(storage.readObjectList('tasks'), [
      {'id': 'task-1'},
    ]);
  });
}
