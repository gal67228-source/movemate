import 'package:flutter/material.dart';

enum GlobalSearchType { inventory, box, sale, task, shopping }

extension GlobalSearchTypeLabel on GlobalSearchType {
  String get label => switch (this) {
        GlobalSearchType.inventory => 'ציוד בחדרים',
        GlobalSearchType.box => 'ארגזים',
        GlobalSearchType.sale => 'מכירות',
        GlobalSearchType.task => 'משימות',
        GlobalSearchType.shopping => 'קניות',
      };

  IconData get icon => switch (this) {
        GlobalSearchType.inventory => Icons.chair_outlined,
        GlobalSearchType.box => Icons.inventory_2_outlined,
        GlobalSearchType.sale => Icons.sell_outlined,
        GlobalSearchType.task => Icons.checklist_rounded,
        GlobalSearchType.shopping => Icons.shopping_cart_outlined,
      };
}

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.route,
    this.details = '',
    this.searchTerms = const [],
  });

  final String id;
  final GlobalSearchType type;
  final String title;
  final String subtitle;
  final String details;
  final String route;
  final List<String> searchTerms;

  bool matches(String query) {
    final normalizedQuery = normalizeSearchText(query);
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final searchableText = <String>[
      title,
      subtitle,
      details,
      type.label,
      ...searchTerms,
    ].map(normalizeSearchText).join(' ');

    return normalizedQuery
        .split(' ')
        .where((part) => part.isNotEmpty)
        .every(searchableText.contains);
  }
}

String normalizeSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('״', '"')
      .replaceAll('׳', "'")
      .replaceAll(RegExp(r'\s+'), ' ');
}

List<GlobalSearchResult> filterGlobalSearchResults({
  required Iterable<GlobalSearchResult> results,
  required String query,
  GlobalSearchType? type,
}) {
  final filtered = results.where((result) {
    return (type == null || result.type == type) && result.matches(query);
  }).toList();

  filtered.sort((a, b) {
    final typeComparison = a.type.index.compareTo(b.type.index);
    if (typeComparison != 0) {
      return typeComparison;
    }
    return a.title.compareTo(b.title);
  });
  return filtered;
}
