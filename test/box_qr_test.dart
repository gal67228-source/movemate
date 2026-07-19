import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/packing/domain/box_qr.dart';

void main() {
  test('creates and parses a stable box QR payload', () {
    const boxId = 'box_123';
    expect(boxQrPayload(boxId), 'movemate:box:box_123');
    expect(boxIdFromQr(boxQrPayload(boxId)), boxId);
  });

  test('rejects unrelated QR values', () {
    expect(boxIdFromQr('https://example.com'), isNull);
    expect(boxIdFromQr(boxQrPrefix), isNull);
  });
}
