import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../moves/data/move_repository.dart';
import '../../sales/data/sale_repository.dart';
import '../domain/budget_models.dart';

const _settingsKey = 'budget_settings';
const _expensesKey = 'expenses';

class BudgetRepository {
  BudgetRepository(this._storage);
  final LocalStorage _storage;

  BudgetSettings getSettings(String moveId) {
    final json = _storage.readObjectList(_settingsKey).where((item) => item['moveId'] == moveId);
    return json.isEmpty ? BudgetSettings(moveId: moveId, totalBudgetShekels: 0) : BudgetSettings.fromJson(json.first);
  }

  List<Expense> getExpenses(String moveId) => _storage.readObjectList(_expensesKey).map(Expense.fromJson).where((item) => item.moveId == moveId).toList()..sort((a, b) => b.date.compareTo(a.date));

  Future<void> saveSettings(BudgetSettings settings) async {
    final all = _storage.readObjectList(_settingsKey);
    all.removeWhere((item) => item['moveId'] == settings.moveId);
    all.add(settings.toJson());
    await _storage.writeObjectList(_settingsKey, all);
  }

  Future<void> upsertExpense(Expense expense) async {
    final all = _storage.readObjectList(_expensesKey).map(Expense.fromJson).toList();
    final index = all.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      all.add(expense);
    } else {
      all[index] = expense;
    }
    await _storage.writeObjectList(_expensesKey, all.map((item) => item.toJson()).toList());
  }

  Future<void> deleteExpense(String id) async {
    final all = _storage.readObjectList(_expensesKey).map(Expense.fromJson).where((item) => item.id != id).toList();
    await _storage.writeObjectList(_expensesKey, all.map((item) => item.toJson()).toList());
  }
}

final budgetRepositoryProvider = FutureProvider<BudgetRepository>((ref) async => BudgetRepository(await ref.watch(localStorageProvider.future)));
final budgetSettingsProvider = FutureProvider<BudgetSettings>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) {
    return const BudgetSettings(moveId: '', totalBudgetShekels: 0);
  }
  return (await ref.watch(budgetRepositoryProvider.future)).getSettings(move.id);
});
final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final move = await ref.watch(currentMoveProvider.future);
  if (move == null) {
    return [];
  }
  return (await ref.watch(budgetRepositoryProvider.future)).getExpenses(move.id);
});
final budgetStatsProvider = FutureProvider<BudgetStats>((ref) async {
  final settings = await ref.watch(budgetSettingsProvider.future);
  final expenses = await ref.watch(expensesProvider.future);
  final sales = await ref.watch(saleStatsProvider.future);
  return calculateBudgetStats(settings: settings, expenses: expenses, saleIncomeShekels: sales.actualRevenueShekels);
});
