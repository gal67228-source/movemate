enum PackingStatus { notPacked, packed }

enum ItemDestination { moving, staying, selling, donating }

extension ItemDestinationLabel on ItemDestination {
  String get label => switch (this) {
        ItemDestination.moving => 'עובר בהובלה',
        ItemDestination.staying => 'נשאר בדירה',
        ItemDestination.selling => 'למכירה',
        ItemDestination.donating => 'למסירה',
      };
}

enum MovingBoxStatus { preparing, packed, loaded, arrived, unpacked }

extension MovingBoxStatusLabel on MovingBoxStatus {
  String get label => switch (this) {
        MovingBoxStatus.preparing => 'בהכנה',
        MovingBoxStatus.packed => 'נארז',
        MovingBoxStatus.loaded => 'הועמס',
        MovingBoxStatus.arrived => 'הגיע',
        MovingBoxStatus.unpacked => 'נפרק',
      };
}

enum MovingBoxWeight { light, medium, heavy }

extension MovingBoxWeightLabel on MovingBoxWeight {
  String get label => switch (this) {
        MovingBoxWeight.light => 'קל',
        MovingBoxWeight.medium => 'בינוני',
        MovingBoxWeight.heavy => 'כבד',
      };
}

class MoveRoom {
  const MoveRoom({
    required this.id,
    required this.moveId,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String moveId;
  final String name;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'moveId': moveId,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MoveRoom.fromJson(Map<String, Object?> json) => MoveRoom(
        id: json['id']! as String,
        moveId: json['moveId']! as String,
        name: json['name']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
      );
}

class PackingItem {
  const PackingItem({
    required this.id,
    required this.moveId,
    required this.roomId,
    required this.name,
    required this.status,
    required this.destination,
    required this.createdAt,
  });

  final String id;
  final String moveId;
  final String roomId;
  final String name;
  final PackingStatus status;
  final ItemDestination destination;
  final DateTime createdAt;

  PackingItem copyWith({
    String? roomId,
    String? name,
    PackingStatus? status,
    ItemDestination? destination,
  }) =>
      PackingItem(
        id: id,
        moveId: moveId,
        roomId: roomId ?? this.roomId,
        name: name ?? this.name,
        status: status ?? this.status,
        destination: destination ?? this.destination,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'moveId': moveId,
        'roomId': roomId,
        'name': name,
        'status': status.name,
        'destination': destination.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PackingItem.fromJson(Map<String, Object?> json) => PackingItem(
        id: json['id']! as String,
        moveId: json['moveId']! as String,
        roomId: json['roomId']! as String,
        name: json['name']! as String,
        status: PackingStatus.values.byName(json['status']! as String),
        destination: ItemDestination.values.byName(
          json['destination']! as String,
        ),
        createdAt: DateTime.parse(json['createdAt']! as String),
      );
}

class MovingBox {
  const MovingBox({
    required this.id,
    required this.moveId,
    required this.roomId,
    required this.number,
    required this.name,
    required this.contents,
    required this.fragile,
    required this.weight,
    required this.status,
    required this.notes,
    required this.createdAt,
    this.packedAt,
    this.unpackedAt,
  });

  final String id;
  final String moveId;
  final String roomId;
  final int number;
  final String name;
  final List<String> contents;
  final bool fragile;
  final MovingBoxWeight weight;
  final MovingBoxStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime? packedAt;
  final DateTime? unpackedAt;

  bool get isClosed => status != MovingBoxStatus.preparing;

  MovingBox copyWith({
    String? roomId,
    String? name,
    List<String>? contents,
    bool? fragile,
    MovingBoxWeight? weight,
    MovingBoxStatus? status,
    String? notes,
    DateTime? packedAt,
    DateTime? unpackedAt,
  }) =>
      MovingBox(
        id: id,
        moveId: moveId,
        roomId: roomId ?? this.roomId,
        number: number,
        name: name ?? this.name,
        contents: contents ?? this.contents,
        fragile: fragile ?? this.fragile,
        weight: weight ?? this.weight,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        packedAt: packedAt ?? this.packedAt,
        unpackedAt: unpackedAt ?? this.unpackedAt,
      );

  bool matches(String query, String roomName) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    final searchable = <String>[
      number.toString(),
      name,
      roomName,
      notes,
      status.label,
      ...contents,
    ].join(' ').toLowerCase();
    return searchable.contains(normalized);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'moveId': moveId,
        'roomId': roomId,
        'number': number,
        'name': name,
        'contents': contents,
        'fragile': fragile,
        'weight': weight.name,
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'packedAt': packedAt?.toIso8601String(),
        'unpackedAt': unpackedAt?.toIso8601String(),
      };

  factory MovingBox.fromJson(Map<String, Object?> json) {
    final legacyClosed = json['isClosed'] as bool? ?? false;
    final statusName = json['status'] as String?;
    return MovingBox(
      id: json['id']! as String,
      moveId: json['moveId']! as String,
      roomId: json['roomId']! as String,
      number: json['number']! as int,
      name: json['name'] as String? ?? '',
      contents: List<String>.from(json['contents']! as List),
      fragile: json['fragile']! as bool,
      weight: MovingBoxWeight.values.byName(
        json['weight'] as String? ?? MovingBoxWeight.medium.name,
      ),
      status: statusName == null
          ? legacyClosed
              ? MovingBoxStatus.packed
              : MovingBoxStatus.preparing
          : MovingBoxStatus.values.byName(statusName),
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt']! as String),
      packedAt: _dateFromJson(json['packedAt']),
      unpackedAt: _dateFromJson(json['unpackedAt']),
    );
  }

  static DateTime? _dateFromJson(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }
}

class PackingStats {
  const PackingStats({
    required this.totalItems,
    required this.packedItems,
    required this.boxes,
    required this.closedBoxes,
    this.fragileBoxes = 0,
    this.unpackedBoxes = 0,
  });

  final int totalItems;
  final int packedItems;
  final int boxes;
  final int closedBoxes;
  final int fragileBoxes;
  final int unpackedBoxes;

  double get progress => totalItems == 0 ? 0 : packedItems / totalItems;
  double get boxProgress => boxes == 0 ? 0 : closedBoxes / boxes;
}
