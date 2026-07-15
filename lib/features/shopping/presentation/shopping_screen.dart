import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../moves/data/move_repository.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping_item.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  String _query = '';

  Future<void> _openEditor([ShoppingItem? existing]) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final quantityController = TextEditingController(text: '${existing?.quantity ?? 1}');
    final estimatedController = TextEditingController(text: '${existing?.estimatedPriceShekels ?? 0}');
    final actualController = TextEditingController(text: existing?.actualPriceShekels?.toString() ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    var category = existing?.category ?? ShoppingCategory.other;
    var status = existing?.status ?? ShoppingStatus.needed;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'פריט קניות חדש' : 'עריכת פריט'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'שם הפריט')),
                const SizedBox(height: 10),
                DropdownButtonFormField<ShoppingCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'קטגוריה'),
                  items: ShoppingCategory.values.map((value) => DropdownMenuItem(value: value, child: Text(shoppingCategoryLabel(value)))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => category = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'כמות')),
                const SizedBox(height: 10),
                TextField(controller: estimatedController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'מחיר משוער ליחידה', prefixText: '₪ ')),
                const SizedBox(height: 10),
                DropdownButtonFormField<ShoppingStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'סטטוס'),
                  items: ShoppingStatus.values.map((value) => DropdownMenuItem(value: value, child: Text(shoppingStatusLabel(value)))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => status = value);
                    }
                  },
                ),
                if (status == ShoppingStatus.purchased) ...[
                  const SizedBox(height: 10),
                  TextField(controller: actualController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'מחיר בפועל ליחידה', prefixText: '₪ ')),
                ],
                const SizedBox(height: 10),
                TextField(controller: notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'הערות')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('שמירה')),
          ],
        ),
      ),
    );
    if (saved != true || titleController.text.trim().isEmpty) {
      return;
    }
    final move = await ref.read(currentMoveProvider.future);
    if (move == null) {
      return;
    }
    final now = DateTime.now();
    final item = ShoppingItem(
      id: existing?.id ?? 'shopping_${now.microsecondsSinceEpoch}',
      moveId: move.id,
      title: titleController.text.trim(),
      category: category,
      quantity: int.tryParse(quantityController.text) ?? 1,
      estimatedPriceShekels: int.tryParse(estimatedController.text) ?? 0,
      actualPriceShekels: actualController.text.trim().isEmpty ? null : int.tryParse(actualController.text),
      status: status,
      notes: notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
    );
    await (await ref.read(shoppingRepositoryProvider.future)).upsert(item);
    ref.invalidate(shoppingItemsProvider);
    ref.invalidate(shoppingStatsProvider);
  }

  Future<void> _delete(ShoppingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת פריט'),
        content: Text('למחוק את ${item.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('מחיקה')),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await (await ref.read(shoppingRepositoryProvider.future)).delete(item.id);
    ref.invalidate(shoppingItemsProvider);
    ref.invalidate(shoppingStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shoppingItemsProvider);
    final statsAsync = ref.watch(shoppingStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('רשימת קניות')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(hintText: 'חיפוש פריט', leading: const Icon(Icons.search), onChanged: (value) => setState(() => _query = value)),
          ),
          statsAsync.when(
            data: (stats) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${stats.purchased}/${stats.total} נקנו'), Text('${(stats.progress * 100).round()}%')]),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: stats.progress),
                      const SizedBox(height: 8),
                      Text('משוער: ₪${stats.estimatedTotalShekels} · בפועל: ₪${stats.actualTotalShekels}'),
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
                final filtered = items.where((item) => item.matches(_query)).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('עדיין אין פריטים ברשימת הקניות'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _openEditor(item),
                        leading: Checkbox(
                          value: item.status == ShoppingStatus.purchased,
                          onChanged: (value) async {
                            await (await ref.read(shoppingRepositoryProvider.future)).upsert(item.copyWith(status: value == true ? ShoppingStatus.purchased : ShoppingStatus.needed));
                            ref.invalidate(shoppingItemsProvider);
                            ref.invalidate(shoppingStatsProvider);
                          },
                        ),
                        title: Text(item.title),
                        subtitle: Text('${shoppingCategoryLabel(item.category)} · כמות ${item.quantity} · ₪${item.actualPriceShekels ?? item.estimatedPriceShekels}'),
                        trailing: IconButton(onPressed: () => _delete(item), icon: const Icon(Icons.delete_outline)),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('שגיאה: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _openEditor, icon: const Icon(Icons.add), label: const Text('פריט חדש')),
    );
  }
}
