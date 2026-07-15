import 'package:flutter_test/flutter_test.dart';
import 'package:movemate/features/budget/domain/budget_models.dart';

void main() {
  test('calculates budget balance in whole shekels', () {
    final stats = calculateBudgetStats(
      settings: const BudgetSettings(moveId: 'move-1', totalBudgetShekels: 10000),
      expenses: [
        Expense(id: '1', moveId: 'move-1', title: 'הובלה', category: ExpenseCategory.moving, plannedShekels: 2500, actualShekels: 2700, paid: true, date: DateTime(2026), notes: ''),
        Expense(id: '2', moveId: 'move-1', title: 'ניקיון', category: ExpenseCategory.cleaning, plannedShekels: 500, actualShekels: null, paid: false, date: DateTime(2026), notes: ''),
      ],
      saleIncomeShekels: 1000,
    );
    expect(stats.plannedExpensesShekels, 3000);
    expect(stats.actualExpensesShekels, 2700);
    expect(stats.projectedBalanceShekels, 8000);
    expect(stats.actualBalanceShekels, 8300);
  });
}
