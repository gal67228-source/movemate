import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/smart_move/domain/smart_move_models.dart';

void main() {
  test('readiness averages active progress components', () {
    expect(calculateReadiness([1, 0.5, 0.25, 0.75]), 0.625);
  });

  test('readiness remains inside the valid progress range', () {
    expect(calculateReadiness([2, 2]), 1);
    expect(calculateReadiness([]), 0);
  });
}
