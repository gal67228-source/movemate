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
    this.ownerUid,
    this.plan = 'FREE',
    required this.createdAt,
    required this.updatedAt,
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
  final String? ownerUid;
  final String plan;
  final DateTime createdAt;
  final DateTime updatedAt;

  MovePlan copyWith({
    String? name,
    String? fromAddress,
    String? toAddress,
    DateTime? moveDate,
    int? roomCount,
    bool? hasStorage,
    bool? hasBalcony,
    bool? hasElevator,
    String? ownerUid,
    bool clearOwnerUid = false,
    String? plan,
    DateTime? updatedAt,
  }) {
    return MovePlan(
      id: id,
      name: name ?? this.name,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      moveDate: moveDate ?? this.moveDate,
      roomCount: roomCount ?? this.roomCount,
      hasStorage: hasStorage ?? this.hasStorage,
      hasBalcony: hasBalcony ?? this.hasBalcony,
      hasElevator: hasElevator ?? this.hasElevator,
      ownerUid: clearOwnerUid ? null : (ownerUid ?? this.ownerUid),
      plan: plan ?? this.plan,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

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
        'ownerUid': ownerUid,
        'plan': plan,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MovePlan.fromJson(Map<String, Object?> json) {
    final moveDate = DateTime.parse(json['moveDate']! as String);
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        moveDate.subtract(const Duration(days: 30));
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
        createdAt;

    return MovePlan(
      id: json['id']! as String,
      name: json['name']! as String,
      fromAddress: (json['fromAddress'] as String?) ?? '',
      toAddress: (json['toAddress'] as String?) ?? '',
      moveDate: moveDate,
      roomCount: (json['roomCount'] as num?)?.toInt() ?? 1,
      hasStorage: (json['hasStorage'] as bool?) ?? false,
      hasBalcony: (json['hasBalcony'] as bool?) ?? false,
      hasElevator: (json['hasElevator'] as bool?) ?? false,
      ownerUid: json['ownerUid'] as String?,
      plan: (json['plan'] as String?) ?? 'FREE',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
