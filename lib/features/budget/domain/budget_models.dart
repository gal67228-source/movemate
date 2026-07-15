enum ExpenseCategory { moving, packing, cleaning, repairs, furniture, utilities, other }

class BudgetSettings {
  const BudgetSettings({required this.moveId, required this.totalBudgetShekels});
  final String moveId;
  final int totalBudgetShekels;
  Map<String, Object?> toJson() => {'moveId': moveId, 'totalBudgetShekels': totalBudgetShekels};
  factory BudgetSettings.fromJson(Map<String, Object?> json) => BudgetSettings(moveId: (json['moveId'] as String?) ?? '', totalBudgetShekels: (json['totalBudgetShekels'] as num?)?.toInt() ?? 0);
}

class Expense {
  const Expense({required this.id, required this.moveId, required this.title, required this.category, required this.plannedShekels, required this.actualShekels, required this.paid, required this.date, required this.notes});
  final String id;
  final String moveId;
  final String title;
  final ExpenseCategory category;
  final int plannedShekels;
  final int? actualShekels;
  final bool paid;
  final DateTime date;
  final String notes;

  Map<String, Object?> toJson() => {'id': id, 'moveId': moveId, 'title': title, 'category': category.name, 'plannedShekels': plannedShekels, 'actualShekels': actualShekels, 'paid': paid, 'date': date.toIso8601String(), 'notes': notes};
  factory Expense.fromJson(Map<String, Object?> json) => Expense(
        id: (json['id'] as String?) ?? 'expense_${DateTime.now().microsecondsSinceEpoch}',
        moveId: (json['moveId'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        category: _enumByName(ExpenseCategory.values, json['category'] as String?, ExpenseCategory.other),
        plannedShekels: (json['plannedShekels'] as num?)?.toInt() ?? 0,
        actualShekels: (json['actualShekels'] as num?)?.toInt(),
        paid: (json['paid'] as bool?) ?? false,
        date: DateTime.tryParse((json['date'] as String?) ?? '') ?? DateTime.now(),
        notes: (json['notes'] as String?) ?? '',
      );
}

class BudgetStats {
  const BudgetStats({required this.budgetShekels, required this.plannedExpensesShekels, required this.actualExpensesShekels, required this.saleIncomeShekels});
  final int budgetShekels;
  final int plannedExpensesShekels;
  final int actualExpensesShekels;
  final int saleIncomeShekels;
  int get projectedBalanceShekels => budgetShekels + saleIncomeShekels - plannedExpensesShekels;
  int get actualBalanceShekels => budgetShekels + saleIncomeShekels - actualExpensesShekels;
}

BudgetStats calculateBudgetStats({required BudgetSettings settings, required Iterable<Expense> expenses, required int saleIncomeShekels}) => BudgetStats(
      budgetShekels: settings.totalBudgetShekels,
      plannedExpensesShekels: expenses.fold(0, (sum, item) => sum + item.plannedShekels),
      actualExpensesShekels: expenses.fold(0, (sum, item) => sum + (item.actualShekels ?? (item.paid ? item.plannedShekels : 0))),
      saleIncomeShekels: saleIncomeShekels,
    );

String expenseCategoryLabel(ExpenseCategory category) => switch (category) {
      ExpenseCategory.moving => 'הובלה',
      ExpenseCategory.packing => 'אריזה',
      ExpenseCategory.cleaning => 'ניקיון',
      ExpenseCategory.repairs => 'תיקונים',
      ExpenseCategory.furniture => 'ריהוט',
      ExpenseCategory.utilities => 'חשבונות',
      ExpenseCategory.other => 'שונות',
    };

String formatMoney(int shekels) => '₪$shekels';

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}
