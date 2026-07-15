import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../moves/data/move_repository.dart';
import '../data/budget_repository.dart';
import '../domain/budget_models.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  Future<void> _editBudget(BuildContext context, WidgetRef ref, BudgetSettings settings) async {
    final controller = TextEditingController(text: settings.totalBudgetShekels.toString());
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הגדרת תקציב'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'תקציב כולל', prefixText: '₪ ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('שמירה')),
        ],
      ),
    );
    if (save != true) {
      return;
    }
    await (await ref.read(budgetRepositoryProvider.future)).saveSettings(BudgetSettings(moveId: settings.moveId, totalBudgetShekels: int.tryParse(controller.text) ?? 0));
    ref.invalidate(budgetSettingsProvider);
    ref.invalidate(budgetStatsProvider);
  }

  Future<void> _editExpense(BuildContext context, WidgetRef ref, [Expense? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final planned = TextEditingController(text: '${existing?.plannedShekels ?? 0}');
    final actual = TextEditingController(text: existing?.actualShekels?.toString() ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    var category = existing?.category ?? ExpenseCategory.other;
    var paid = existing?.paid ?? false;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'הוצאה חדשה' : 'עריכת הוצאה'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'שם ההוצאה')),
                const SizedBox(height: 10),
                DropdownButtonFormField<ExpenseCategory>(initialValue: category, decoration: const InputDecoration(labelText: 'קטגוריה'), items: ExpenseCategory.values.map((value) => DropdownMenuItem(value: value, child: Text(expenseCategoryLabel(value)))).toList(), onChanged: (value) { if (value != null) { setState(() => category = value); } }),
                const SizedBox(height: 10),
                TextField(controller: planned, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום מתוכנן', prefixText: '₪ ')),
                const SizedBox(height: 10),
                TextField(controller: actual, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'סכום בפועל', prefixText: '₪ ')),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('שולם'), value: paid, onChanged: (value) => setState(() => paid = value)),
                TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'הערות')),
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
    if (save != true || title.text.trim().isEmpty) {
      return;
    }
    final move = await ref.read(currentMoveProvider.future);
    if (move == null) {
      return;
    }
    await (await ref.read(budgetRepositoryProvider.future)).upsertExpense(Expense(id: existing?.id ?? 'expense_${DateTime.now().microsecondsSinceEpoch}', moveId: move.id, title: title.text.trim(), category: category, plannedShekels: int.tryParse(planned.text) ?? 0, actualShekels: actual.text.trim().isEmpty ? null : int.tryParse(actual.text), paid: paid, date: existing?.date ?? DateTime.now(), notes: notes.text.trim()));
    ref.invalidate(expensesProvider);
    ref.invalidate(budgetStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(budgetSettingsProvider);
    final statsAsync = ref.watch(budgetStatsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('תקציב מעבר')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          statsAsync.when(
            data: (stats) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('תקציב כולל', style: Theme.of(context).textTheme.titleMedium), Text(formatMoney(stats.budgetShekels))]),
                    const Divider(height: 24),
                    Text('הוצאות מתוכננות: ${formatMoney(stats.plannedExpensesShekels)}'),
                    Text('הוצאות בפועל: ${formatMoney(stats.actualExpensesShekels)}'),
                    Text('הכנסות ממכירות: ${formatMoney(stats.saleIncomeShekels)}'),
                    const SizedBox(height: 8),
                    Text('יתרה בפועל: ${formatMoney(stats.actualBalanceShekels)}', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text('שגיאה: $error'),
          ),
          const SizedBox(height: 10),
          settingsAsync.when(
            data: (settings) => OutlinedButton.icon(onPressed: () => _editBudget(context, ref, settings), icon: const Icon(Icons.edit_outlined), label: const Text('עריכת תקציב כולל')),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 18),
          Text('הוצאות', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          expensesAsync.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('עדיין אין הוצאות'))));
              }
              return Column(
                children: expenses.map((expense) => Card(
                  child: ListTile(
                    onTap: () => _editExpense(context, ref, expense),
                    leading: Icon(expense.paid ? Icons.check_circle : Icons.receipt_long_outlined),
                    title: Text(expense.title),
                    subtitle: Text('${expenseCategoryLabel(expense.category)} · ${expense.paid ? 'שולם' : 'לא שולם'}'),
                    trailing: Text(formatMoney(expense.actualShekels ?? expense.plannedShekels)),
                  ),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('שגיאה: $error'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _editExpense(context, ref), icon: const Icon(Icons.add), label: const Text('הוצאה חדשה')),
    );
  }
}
