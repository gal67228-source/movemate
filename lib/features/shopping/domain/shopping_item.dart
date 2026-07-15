enum ShoppingStatus { needed, purchased, cancelled }

enum ShoppingCategory { packing, cleaning, kitchen, furniture, electrical, repairs, other }

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.moveId,
    required this.title,
    required this.category,
    required this.quantity,
    required this.estimatedPriceShekels,
    required this.actualPriceShekels,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String moveId;
  final String title;
  final ShoppingCategory category;
  final int quantity;
  final int estimatedPriceShekels;
  final int? actualPriceShekels;
  final ShoppingStatus status;
  final String notes;
  final DateTime createdAt;

  ShoppingItem copyWith({
    String? title,
    ShoppingCategory? category,
    int? quantity,
    int? estimatedPriceShekels,
    int? actualPriceShekels,
    bool clearActualPrice = false,
    ShoppingStatus? status,
    String? notes,
  }) {
    return ShoppingItem(
      id: id,
      moveId: moveId,
      title: title ?? this.title,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      estimatedPriceShekels: estimatedPriceShekels ?? this.estimatedPriceShekels,
      actualPriceShekels: clearActualPrice ? null : (actualPriceShekels ?? this.actualPriceShekels),
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  bool matches(String query) {
    final value = query.trim().toLowerCase();
    return value.isEmpty || title.toLowerCase().contains(value) || notes.toLowerCase().contains(value) || shoppingCategoryLabel(category).contains(value);
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'id': id,
        'moveId': moveId,
        'title': title,
        'category': category.name,
        'quantity': quantity,
        'estimatedPriceShekels': estimatedPriceShekels,
        'actualPriceShekels': actualPriceShekels,
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ShoppingItem.fromJson(Map<String, Object?> json) => ShoppingItem(
        id: (json['id'] as String?) ?? 'shopping_${DateTime.now().microsecondsSinceEpoch}',
        moveId: (json['moveId'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        category: _enumByName(ShoppingCategory.values, json['category'] as String?, ShoppingCategory.other),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        estimatedPriceShekels: (json['estimatedPriceShekels'] as num?)?.toInt() ?? 0,
        actualPriceShekels: (json['actualPriceShekels'] as num?)?.toInt(),
        status: _enumByName(ShoppingStatus.values, json['status'] as String?, ShoppingStatus.needed),
        notes: (json['notes'] as String?) ?? '',
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
      );
}

class ShoppingStats {
  const ShoppingStats({required this.total, required this.purchased, required this.estimatedTotalShekels, required this.actualTotalShekels});
  final int total;
  final int purchased;
  final int estimatedTotalShekels;
  final int actualTotalShekels;
  double get progress => total == 0 ? 0 : purchased / total;
}

ShoppingStats calculateShoppingStats(Iterable<ShoppingItem> items) {
  final active = items.where((item) => item.status != ShoppingStatus.cancelled).toList();
  return ShoppingStats(
    total: active.length,
    purchased: active.where((item) => item.status == ShoppingStatus.purchased).length,
    estimatedTotalShekels: active.fold(0, (sum, item) => sum + (item.estimatedPriceShekels * item.quantity)),
    actualTotalShekels: active.where((item) => item.status == ShoppingStatus.purchased).fold(0, (sum, item) => sum + ((item.actualPriceShekels ?? item.estimatedPriceShekels) * item.quantity)),
  );
}

String shoppingStatusLabel(ShoppingStatus status) => switch (status) {
      ShoppingStatus.needed => 'צריך לקנות',
      ShoppingStatus.purchased => 'נקנה',
      ShoppingStatus.cancelled => 'בוטל',
    };

String shoppingCategoryLabel(ShoppingCategory category) => switch (category) {
      ShoppingCategory.packing => 'חומרי אריזה',
      ShoppingCategory.cleaning => 'ניקיון',
      ShoppingCategory.kitchen => 'מטבח',
      ShoppingCategory.furniture => 'ריהוט',
      ShoppingCategory.electrical => 'חשמל',
      ShoppingCategory.repairs => 'תיקונים',
      ShoppingCategory.other => 'שונות',
    };

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}
