class MovePlan {
  const MovePlan({
    required this.id,
    required this.name,
    required this.fromAddress,
    required this.toAddress,
    required this.moveDate,
    required this.roomCount,
    required this.hasStorage,
    required this.hasBalcony,
    required this.hasElevator,
  });

  final String id;
  final String name;
  final String fromAddress;
  final String toAddress;
  final DateTime moveDate;
  final int roomCount;
  final bool hasStorage;
  final bool hasBalcony;
  final bool hasElevator;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'fromAddress': fromAddress,
        'toAddress': toAddress,
        'moveDate': moveDate.toIso8601String(),
        'roomCount': roomCount,
        'hasStorage': hasStorage,
        'hasBalcony': hasBalcony,
        'hasElevator': hasElevator,
      };

  factory MovePlan.fromJson(Map<String, Object?> json) => MovePlan(
        id: json['id']! as String,
        name: json['name']! as String,
        fromAddress: (json['fromAddress'] as String?) ?? '',
        toAddress: (json['toAddress'] as String?) ?? '',
        moveDate: DateTime.parse(json['moveDate']! as String),
        roomCount: (json['roomCount'] as num?)?.toInt() ?? 1,
        hasStorage: (json['hasStorage'] as bool?) ?? false,
        hasBalcony: (json['hasBalcony'] as bool?) ?? false,
        hasElevator: (json['hasElevator'] as bool?) ?? false,
      );
}
