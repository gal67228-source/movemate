enum SaleStatus { draft, published, reserved, sold, donated, cancelled }

enum SaleCategory {
  furniture,
  appliances,
  kitchen,
  electronics,
  children,
  clothing,
  tools,
  other,
}

class SaleItem {
  const SaleItem({
    required this.id,
    required this.moveId,
    required this.title,
    required this.description,
    required this.category,
    required this.askingPriceAgorot,
    required this.soldPriceAgorot,
    required this.status,
    required this.buyerName,
    required this.notes,
    required this.createdAt,
    required this.publishedAt,
    required this.soldAt,
  });

  final String id;
  final String moveId;
  final String title;
  final String description;
  final SaleCategory category;
  final int askingPriceAgorot;
  final int? soldPriceAgorot;
  final SaleStatus status;
  final String buyerName;
  final String notes;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? soldAt;

  bool get isActive =>
      status == SaleStatus.draft ||
      status == SaleStatus.published ||
      status == SaleStatus.reserved;

  SaleItem copyWith({
    String? title,
    String? description,
    SaleCategory? category,
    int? askingPriceAgorot,
    int? soldPriceAgorot,
    bool clearSoldPrice = false,
    SaleStatus? status,
    String? buyerName,
    String? notes,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    DateTime? soldAt,
    bool clearSoldAt = false,
  }) {
    return SaleItem(
      id: id,
      moveId: moveId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      askingPriceAgorot: askingPriceAgorot ?? this.askingPriceAgorot,
      soldPriceAgorot:
          clearSoldPrice ? null : (soldPriceAgorot ?? this.soldPriceAgorot),
      status: status ?? this.status,
      buyerName: buyerName ?? this.buyerName,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      publishedAt:
          clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
      soldAt: clearSoldAt ? null : (soldAt ?? this.soldAt),
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return title.toLowerCase().contains(normalized) ||
        description.toLowerCase().contains(normalized) ||
        buyerName.toLowerCase().contains(normalized) ||
        notes.toLowerCase().contains(normalized) ||
        saleCategoryLabel(category).contains(normalized) ||
        saleStatusLabel(status).contains(normalized);
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'id': id,
        'moveId': moveId,
        'title': title,
        'description': description,
        'category': category.name,
        'askingPriceAgorot': askingPriceAgorot,
        'soldPriceAgorot': soldPriceAgorot,
        'status': status.name,
        'buyerName': buyerName,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'publishedAt': publishedAt?.toIso8601String(),
        'soldAt': soldAt?.toIso8601String(),
      };

  factory SaleItem.fromJson(Map<String, Object?> json) {
    final askingPriceAgorot = _readMoneyAgorot(
      json,
      agorotKey: 'askingPriceAgorot',
      legacyShekelsKey: 'askingPrice',
    );
    final soldPriceAgorot = _readNullableMoneyAgorot(
      json,
      agorotKey: 'soldPriceAgorot',
      legacyShekelsKey: 'soldPrice',
    );

    return SaleItem(
      id: (json['id'] as String?) ??
          'sale_${DateTime.now().microsecondsSinceEpoch}',
      moveId: (json['moveId'] as String?) ?? '',
      title: (json['title'] as String?) ?? (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: _enumByName(
        SaleCategory.values,
        json['category'] as String?,
        SaleCategory.other,
      ),
      askingPriceAgorot: askingPriceAgorot,
      soldPriceAgorot: soldPriceAgorot,
      status: _enumByName(
        SaleStatus.values,
        json['status'] as String?,
        (json['sold'] as bool?) == true
            ? SaleStatus.sold
            : SaleStatus.draft,
      ),
      buyerName: (json['buyerName'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      createdAt: _readDate(json['createdAt']) ?? DateTime.now(),
      publishedAt: _readDate(json['publishedAt']),
      soldAt: _readDate(json['soldAt']),
    );
  }
}

class SaleStats {
  const SaleStats({
    required this.totalItems,
    required this.activeItems,
    required this.soldItems,
    required this.expectedRevenueAgorot,
    required this.actualRevenueAgorot,
  });

  final int totalItems;
  final int activeItems;
  final int soldItems;
  final int expectedRevenueAgorot;
  final int actualRevenueAgorot;

  double get progress => totalItems == 0 ? 0 : soldItems / totalItems;
}

SaleStats calculateSaleStats(Iterable<SaleItem> items) {
  final list = items.toList();
  return SaleStats(
    totalItems: list.length,
    activeItems: list.where((item) => item.isActive).length,
    soldItems: list.where((item) => item.status == SaleStatus.sold).length,
    expectedRevenueAgorot: list
        .where((item) => item.isActive)
        .fold(0, (total, item) => total + item.askingPriceAgorot),
    actualRevenueAgorot: list
        .where((item) => item.status == SaleStatus.sold)
        .fold(
          0,
          (total, item) =>
              total + (item.soldPriceAgorot ?? item.askingPriceAgorot),
        ),
  );
}

String saleStatusLabel(SaleStatus status) => switch (status) {
      SaleStatus.draft => 'טיוטה',
      SaleStatus.published => 'פורסם',
      SaleStatus.reserved => 'שמור לקונה',
      SaleStatus.sold => 'נמכר',
      SaleStatus.donated => 'נמסר',
      SaleStatus.cancelled => 'בוטל',
    };

String saleCategoryLabel(SaleCategory category) => switch (category) {
      SaleCategory.furniture => 'ריהוט',
      SaleCategory.appliances => 'מוצרי חשמל',
      SaleCategory.kitchen => 'מטבח',
      SaleCategory.electronics => 'אלקטרוניקה',
      SaleCategory.children => 'ילדים',
      SaleCategory.clothing => 'בגדים',
      SaleCategory.tools => 'כלי עבודה',
      SaleCategory.other => 'שונות',
    };

String formatShekels(int agorot) {
  final value = agorot / 100;
  return value == value.roundToDouble()
      ? '₪${value.toInt()}'
      : '₪${value.toStringAsFixed(2)}';
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}

DateTime? _readDate(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

int _readMoneyAgorot(
  Map<String, Object?> json, {
  required String agorotKey,
  required String legacyShekelsKey,
}) {
  final agorot = json[agorotKey];
  if (agorot is num) {
    return agorot.round();
  }
  final legacy = json[legacyShekelsKey];
  if (legacy is num) {
    return (legacy * 100).round();
  }
  return 0;
}

int? _readNullableMoneyAgorot(
  Map<String, Object?> json, {
  required String agorotKey,
  required String legacyShekelsKey,
}) {
  if (json[agorotKey] == null && json[legacyShekelsKey] == null) {
    return null;
  }
  return _readMoneyAgorot(
    json,
    agorotKey: agorotKey,
    legacyShekelsKey: legacyShekelsKey,
  );
}
