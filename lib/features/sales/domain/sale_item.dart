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
    required this.askingPriceShekels,
    required this.soldPriceShekels,
    required this.status,
    required this.buyerName,
    required this.notes,
    required this.createdAt,
    required this.publishedAt,
    required this.soldAt,
    this.quantity = 1,
    this.sourcePackingItemId,
  });

  final String id;
  final String moveId;
  final String title;
  final String description;
  final SaleCategory category;
  final int askingPriceShekels;
  final int? soldPriceShekels;
  final SaleStatus status;
  final String buyerName;
  final String notes;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? soldAt;
  final int quantity;
  final String? sourcePackingItemId;

  bool get isActive =>
      status == SaleStatus.draft ||
      status == SaleStatus.published ||
      status == SaleStatus.reserved;

  SaleItem copyWith({
    String? title,
    String? description,
    SaleCategory? category,
    int? askingPriceShekels,
    int? soldPriceShekels,
    bool clearSoldPrice = false,
    SaleStatus? status,
    String? buyerName,
    String? notes,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    DateTime? soldAt,
    bool clearSoldAt = false,
    int? quantity,
    String? sourcePackingItemId,
    bool clearSourcePackingItemId = false,
  }) {
    return SaleItem(
      id: id,
      moveId: moveId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      askingPriceShekels:
          askingPriceShekels ?? this.askingPriceShekels,
      soldPriceShekels:
          clearSoldPrice ? null : (soldPriceShekels ?? this.soldPriceShekels),
      status: status ?? this.status,
      buyerName: buyerName ?? this.buyerName,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      publishedAt:
          clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
      soldAt: clearSoldAt ? null : (soldAt ?? this.soldAt),
      quantity: quantity ?? this.quantity,
      sourcePackingItemId: clearSourcePackingItemId
          ? null
          : (sourcePackingItemId ?? this.sourcePackingItemId),
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
        'schemaVersion': 3,
        'id': id,
        'moveId': moveId,
        'title': title,
        'description': description,
        'category': category.name,
        'askingPriceShekels': askingPriceShekels,
        'soldPriceShekels': soldPriceShekels,
        'status': status.name,
        'buyerName': buyerName,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'publishedAt': publishedAt?.toIso8601String(),
        'soldAt': soldAt?.toIso8601String(),
        'quantity': quantity,
        'sourcePackingItemId': sourcePackingItemId,
      };

  factory SaleItem.fromJson(Map<String, Object?> json) {
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
      askingPriceShekels: _readMoneyShekels(
        json,
        shekelsKey: 'askingPriceShekels',
        legacyShekelsKey: 'askingPrice',
        legacyAgorotKey: 'askingPriceAgorot',
      ),
      soldPriceShekels: _readNullableMoneyShekels(
        json,
        shekelsKey: 'soldPriceShekels',
        legacyShekelsKey: 'soldPrice',
        legacyAgorotKey: 'soldPriceAgorot',
      ),
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
      quantity: ((json['quantity'] as num?)?.toInt() ?? 1).clamp(1, 999).toInt(),
      sourcePackingItemId: json['sourcePackingItemId'] as String?,
    );
  }
}

class SaleStats {
  const SaleStats({
    required this.totalItems,
    required this.activeItems,
    required this.soldItems,
    required this.expectedRevenueShekels,
    required this.actualRevenueShekels,
  });

  final int totalItems;
  final int activeItems;
  final int soldItems;
  final int expectedRevenueShekels;
  final int actualRevenueShekels;

  double get progress => totalItems == 0 ? 0 : soldItems / totalItems;
}

SaleStats calculateSaleStats(Iterable<SaleItem> items) {
  final list = items.toList();
  return SaleStats(
    totalItems: list.length,
    activeItems: list.where((item) => item.isActive).length,
    soldItems: list.where((item) => item.status == SaleStatus.sold).length,
    expectedRevenueShekels: list
        .where((item) => item.isActive)
        .fold(0, (total, item) => total + item.askingPriceShekels),
    actualRevenueShekels: list
        .where((item) => item.status == SaleStatus.sold)
        .fold(
          0,
          (total, item) =>
              total + (item.soldPriceShekels ?? item.askingPriceShekels),
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

String formatShekels(int shekels) => '₪$shekels';

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

int _readMoneyShekels(
  Map<String, Object?> json, {
  required String shekelsKey,
  required String legacyShekelsKey,
  required String legacyAgorotKey,
}) {
  final shekels = json[shekelsKey];
  if (shekels is num) {
    return shekels.round();
  }
  final legacyShekels = json[legacyShekelsKey];
  if (legacyShekels is num) {
    return legacyShekels.round();
  }
  final legacyAgorot = json[legacyAgorotKey];
  if (legacyAgorot is num) {
    return (legacyAgorot / 100).round();
  }
  return 0;
}

int? _readNullableMoneyShekels(
  Map<String, Object?> json, {
  required String shekelsKey,
  required String legacyShekelsKey,
  required String legacyAgorotKey,
}) {
  if (json[shekelsKey] == null &&
      json[legacyShekelsKey] == null &&
      json[legacyAgorotKey] == null) {
    return null;
  }
  return _readMoneyShekels(
    json,
    shekelsKey: shekelsKey,
    legacyShekelsKey: legacyShekelsKey,
    legacyAgorotKey: legacyAgorotKey,
  );
}
