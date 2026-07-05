import 'package:flutter/material.dart';
import '../models/expense.dart';

/// 简单的状态管理 - 使用 ChangeNotifier 管理支出数据
/// 后续可替换为更完善的状态管理方案（Provider/Riverpod/BLoC）
class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];

  /// 获取所有支出记录（按日期倒序）
  List<Expense> get expenses {
    final sorted = List<Expense>.from(_expenses);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// 获取今日支出总额
  double get todayTotal {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _expenses
        .where((e) {
          final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
          return expenseDate == today;
        })
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// 获取本月支出总额
  double get thisMonthTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// 获取上月支出总额
  double get lastMonthTotal {
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final year = now.month == 1 ? now.year - 1 : now.year;
    return _expenses
        .where((e) => e.date.year == year && e.date.month == lastMonth)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// 获取本年支出总额
  double get thisYearTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// 添加一条支出记录
  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  /// 更新一条支出记录
  void updateExpense(int index, Expense updated) {
    _expenses[index] = updated;
    notifyListeners();
  }

  /// 删除一条支出记录
  void deleteExpense(int index) {
    _expenses.removeAt(index);
    notifyListeners();
  }

  /// 按日期范围筛选
  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses
        .where((e) =>
            e.date.isAfter(start.subtract(const Duration(days: 1))) &&
            e.date.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// 按分类统计（返回各大类金额汇总，用于饼图）
  Map<String, double> getCategoryTotals(DateTime? start, DateTime? end) {
    final Map<String, double> totals = {};
    final filtered = start != null && end != null
        ? getExpensesByDateRange(start, end)
        : _expenses;

    for (final expense in filtered) {
      totals[expense.majorCategory] =
          (totals[expense.majorCategory] ?? 0) + expense.amount;
    }
    return totals;
  }

  /// 按日期统计（返回每日金额汇总，用于柱状图）
  Map<DateTime, double> getDailyTotals(DateTime start, DateTime end) {
    final Map<DateTime, double> totals = {};
    final filtered = getExpensesByDateRange(start, end);

    for (final expense in filtered) {
      final day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      totals[day] = (totals[day] ?? 0) + expense.amount;
    }
    return totals;
  }
}
