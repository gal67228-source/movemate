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
    required this.contents,
    required this.fragile,
    required this.isClosed,
    required this.createdAt,
  });

  final String id;
  final String moveId;
  final String roomId;
  final int number;
  final List<String> contents;
  final bool fragile;
  final bool isClosed;
  final DateTime createdAt;

  MovingBox copyWith({
    String? roomId,
    List<String>? contents,
    bool? fragile,
    bool? isClosed,
  }) =>
      MovingBox(
        id: id,
        moveId: moveId,
        roomId: roomId ?? this.roomId,
        number: number,
        contents: contents ?? this.contents,
        fragile: fragile ?? this.fragile,
        isClosed: isClosed ?? this.isClosed,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'moveId': moveId,
        'roomId': roomId,
        'number': number,
        'contents': contents,
        'fragile': fragile,
        'isClosed': isClosed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MovingBox.fromJson(Map<String, Object?> json) => MovingBox(
        id: json['id']! as String,
        moveId: json['moveId']! as String,
        roomId: json['roomId']! as String,
        number: json['number']! as int,
        contents: List<String>.from(json['contents']! as List),
        fragile: json['fragile']! as bool,
        isClosed: json['isClosed']! as bool,
        createdAt: DateTime.parse(json['createdAt']! as String),
      );
}

class PackingStats {
  const PackingStats({
    required this.totalItems,
    required this.packedItems,
    required this.boxes,
    required this.closedBoxes,
  });

  final int totalItems;
  final int packedItems;
  final int boxes;
  final int closedBoxes;

  double get progress => totalItems == 0 ? 0 : packedItems / totalItems;
}
