import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../moves/data/move_repository.dart';
import '../data/sale_repository.dart';
import '../domain/sale_item.dart';

class SaleEditorScreen extends ConsumerStatefulWidget {
  const SaleEditorScreen({super.key, this.itemId});

  final String? itemId;

  @override
  ConsumerState<SaleEditorScreen> createState() => _SaleEditorScreenState();
}

class _SaleEditorScreenState extends ConsumerState<SaleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _askingPriceController = TextEditingController();
  final _soldPriceController = TextEditingController();
  final _buyerController = TextEditingController();
  final _notesController = TextEditingController();

  SaleCategory _category = SaleCategory.other;
  SaleStatus _status = SaleStatus.draft;
  SaleItem? _existingItem;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _askingPriceController.dispose();
    _soldPriceController.dispose();
    _buyerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadItem(List<SaleItem> items) {
    if (_loaded) {
      return;
    }
    _loaded = true;
    if (widget.itemId == null) {
      return;
    }
    final matches = items.where((item) => item.id == widget.itemId);
    if (matches.isEmpty) {
      return;
    }
    final item = matches.first;
    _existingItem = item;
    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _quantityController.text = item.quantity.toString();
    _askingPriceController.text = _priceInput(item.askingPriceShekels);
    _soldPriceController.text = item.soldPriceShekels == null
        ? ''
        : _priceInput(item.soldPriceShekels!);
    _buyerController.text = item.buyerName;
    _notesController.text = item.notes;
    _category = item.category;
    _status = item.status;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final move = await ref.read(currentMoveProvider.future);
    if (move == null) {
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final sold = _status == SaleStatus.sold;
    final published = _status == SaleStatus.published ||
        _status == SaleStatus.reserved ||
        sold;
    final item = SaleItem(
      id: _existingItem?.id ?? 'sale_${now.microsecondsSinceEpoch}',
      moveId: move.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      askingPriceShekels: _parsePrice(_askingPriceController.text),
      soldPriceShekels: _soldPriceController.text.trim().isEmpty
          ? null
          : _parsePrice(_soldPriceController.text),
      status: _status,
      buyerName: _buyerController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: _existingItem?.createdAt ?? now,
      publishedAt: published
          ? (_existingItem?.publishedAt ?? now)
          : _existingItem?.publishedAt,
      soldAt: sold ? (_existingItem?.soldAt ?? now) : null,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      sourcePackingItemId: _existingItem?.sourcePackingItemId,
    );
    final repository = await ref.read(saleRepositoryProvider.future);
    await repository.upsert(item);
    ref.invalidate(saleItemsProvider);
    ref.invalidate(saleStatsProvider);
    if (!mounted) {
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(saleItemsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? 'פריט חדש למכירה' : 'עריכת פריט'),
      ),
      body: itemsAsync.when(
        data: (items) {
          _loadItem(items);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'שם הפריט',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'יש להזין שם פריט'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'כמות'),
                  validator: (value) {
                    final quantity = int.tryParse(value ?? '');
                    if (quantity == null || quantity < 1) {
                      return 'יש להזין כמות של 1 ומעלה';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'תיאור',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SaleCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'קטגוריה'),
                  items: SaleCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(saleCategoryLabel(category)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _askingPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'מחיר מבוקש',
                    prefixText: '₪ ',
                  ),
                  validator: _validatePrice,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SaleStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'סטטוס'),
                  items: SaleStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(saleStatusLabel(status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                if (_status == SaleStatus.sold) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _soldPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'מחיר מכירה בפועל',
                      prefixText: '₪ ',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return null;
                      }
                      return _validatePrice(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _buyerController,
                    decoration: const InputDecoration(labelText: 'שם הקונה'),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'הערות',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('שמירה'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('שגיאה: $error')),
      ),
    );
  }
}

String? _validatePrice(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'יש להזין מחיר';
  }
  final parsed = int.tryParse(value.trim());
  if (parsed == null || parsed < 0) {
    return 'יש להזין מחיר תקין';
  }
  return null;
}

int _parsePrice(String value) {
  return int.tryParse(value.trim()) ?? 0;
}

String _priceInput(int shekels) => shekels.toString();
