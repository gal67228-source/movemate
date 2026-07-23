import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/core/sync/cloud_sync_service.dart';

void main() {
  test('sharing roles expose Hebrew labels', () {
    expect(SharedRole.editor.label, 'עורך');
    expect(SharedRole.viewer.label, 'צופה');
  });
}
