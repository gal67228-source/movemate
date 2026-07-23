import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MoveMate backup envelope keeps versioned records', () {
    final payload = {
      'format': 'movemate-backup',
      'version': 1,
      'records': [
        {'key': 'current_move', 'value': '{}', 'updatedAt': DateTime(2026).toIso8601String()},
      ],
    };
    final decoded = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
    expect(decoded['format'], 'movemate-backup');
    expect(decoded['version'], 1);
    expect((decoded['records'] as List).single['key'], 'current_move');
  });
}
