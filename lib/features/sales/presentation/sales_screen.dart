import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/sale_repository.dart';
import '../domain/sale_item.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  SaleStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteItem(SaleItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת פריט'),
        content: Text('למחוק את "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('מחיקה'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final repository = await ref.read(saleRepositoryProvider.future);
    await repository.delete(item.id);
    ref.invalidate(saleItemsProvider);
    ref.invalidate(saleStatsProvider);
  }

  Future<void> _markSold(SaleItem item) async {
    final repository = await ref.read(saleRepositoryProvider.future);
    await repository.upsert(
      item.copyWith(
        status: SaleStatus.sold,
        soldPriceShekels: item.soldPriceShekels ?? item.askingPriceShekels,
        soldAt: item.soldAt ?? DateTime.now(),
      ),
    );
    ref.invalidate(saleItemsProvider);
    ref.invalidate(saleStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(saleItemsProvider);
    final statsAsync = ref.watch(saleStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ציוד למכירה')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'חיפוש פריט',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('הכול'),
                  selected: _statusFilter == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _statusFilter = null);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ...SaleStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(saleStatusLabel(status)),
                      selected: _statusFilter == status,
                      onSelected: (selected) {
                        setState(() => _statusFilter = selected ? status : null);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          statsAsync.when(
            data: (stats) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(child: Text('${stats.totalItems} פריטים')),
                      Text('${formatShekels(stats.expectedRevenueShekels)} צפוי'),
                      const SizedBox(width: 12),
                      Text('${formatShekels(stats.actualRevenueShekels)} התקבל'),
                    ],
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                final filtered = items
                    .where((item) => item.matches(_query))
                    .where(
                      (item) =>
                          _statusFilter == null || item.status == _statusFilter,
                    )
                    .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      items.isEmpty
                          ? 'עדיין לא הוספת פריטים למכירה'
                          : 'לא נמצאו פריטים מתאימים',
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(saleItemsProvider);
                    ref.invalidate(saleStatsProvider);
                    await ref.read(saleItemsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push(
                            '/sales/edit?id=${item.id}',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  child: Icon(_categoryIcon(item.category)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(saleCategoryLabel(item.category)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Chip(
                                            label: Text(
                                              formatShekels(
                                                item.askingPriceShekels,
                                              ),
                                            ),
                                          ),
                                          Chip(
                                            label: Text(
                                              saleStatusLabel(item.status),
                                            ),
                                          ),
                                          if (item.status == SaleStatus.sold)
                                            Chip(
                                              label: Text(
                                                'נמכר ב־${formatShekels(item.soldPriceShekels ?? item.askingPriceShekels)}',
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'sold') {
                                      _markSold(item);
                                    } else if (value == 'edit') {
                                      context.push('/sales/edit?id=${item.id}');
                                    } else if (value == 'delete') {
                                      _deleteItem(item);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (item.status != SaleStatus.sold)
                                      const PopupMenuItem(
                                        value: 'sold',
                                        child: Text('סמן כנמכר'),
                                      ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('עריכה'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('מחיקה'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('שגיאה: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sales/edit'),
        icon: const Icon(Icons.add),
        label: const Text('פריט חדש'),
      ),
    );
  }
}

IconData _categoryIcon(SaleCategory category) => switch (category) {
      SaleCategory.furniture => Icons.chair_outlined,
      SaleCategory.appliances => Icons.kitchen_outlined,
      SaleCategory.kitchen => Icons.restaurant_outlined,
      SaleCategory.electronics => Icons.devices_outlined,
      SaleCategory.children => Icons.toys_outlined,
      SaleCategory.clothing => Icons.checkroom_outlined,
      SaleCategory.tools => Icons.handyman_outlined,
      SaleCategory.other => Icons.inventory_2_outlined,
    };
