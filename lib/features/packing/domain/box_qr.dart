const boxQrPrefix = 'movemate:box:';

String boxQrPayload(String boxId) => '$boxQrPrefix$boxId';

String? boxIdFromQr(String value) {
  if (!value.startsWith(boxQrPrefix)) {
    return null;
  }
  final id = value.substring(boxQrPrefix.length).trim();
  return id.isEmpty ? null : id;
}
