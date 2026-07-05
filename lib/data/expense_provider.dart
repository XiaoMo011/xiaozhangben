import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/recurring_template.dart';
import 'database.dart';

/// 应用核心状态管理
/// 从 SQLite 数据库读写数据，通过 ChangeNotifier 通知 UI 刷新
class ExpenseProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase();

  // ---- 内存缓存 ----
  List<Expense> _expenses = [];
  List<RecurringTemplate> _templates = [];
  bool _loaded = false;

  // ==================== 生命周期 ====================

  /// 从数据库加载所有数据到内存缓存
  Future<void> loadAll() async {
    _expenses = await _db.getAllExpenses();
    _templates = await _db.getAllTemplates();
    _loaded = true;
    notifyListeners();
  }

  /// 释放内存缓存（需要时重新 loadAll）
  void clearCache() {
    _expenses = [];
    _templates = [];
    _loaded = false;
  }

  bool get isLoaded => _loaded;

  // ==================== 交易查询 ====================

  /// 所有交易（按日期倒序，最新在前）
  List<Expense> get expenses => _expenses;

  /// 仅支出
  List<Expense> get expenseOnly =>
      _expenses.where((e) => e.type == 'expense').toList();

  /// 仅收入
  List<Expense> get incomeOnly =>
      _expenses.where((e) => e.type == 'income').toList();

  /// 今日支出
  double get todayExpenseTotal {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _expenses
        .where((e) {
          if (e.type != 'expense') return false;
          final d = e.date;
          return d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
        })
        .fold(0.0, (s, e) => s + e.amount);
  }

  /// 今日收入
  double get todayIncomeTotal {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _expenses
        .where((e) {
          if (e.type != 'income') return false;
          final d = e.date;
          return d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
        })
        .fold(0.0, (s, e) => s + e.amount);
  }

  /// 本月支出
  double get thisMonthExpenseTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.type == 'expense' &&
            e.date.year == now.year &&
            e.date.month == now.month)
        .fold(0.0, (s, e) => s + e.amount);
  }

  /// 本月收入
  double get thisMonthIncomeTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.type == 'income' &&
            e.date.year == now.year &&
            e.date.month == now.month)
        .fold(0.0, (s, e) => s + e.amount);
  }

  /// 本月结余（收入 - 支出）
  double get thisMonthBalance =>
      thisMonthIncomeTotal - thisMonthExpenseTotal;

  // ==================== 交易操作 ====================

  /// 添加交易
  Future<void> addExpense(Expense expense) async {
    final id = await _db.insertExpense(expense);
    final saved = expense.copyWith(id: id);
    _expenses.insert(0, saved); // 保持日期倒序
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  /// 更新交易
  Future<void> updateExpense(int index, Expense updated) async {
    if (index < 0 || index >= _expenses.length) return;
    // updated 可能没有 id（编辑后返回），保持原 id
    final withId = updated.copyWith(id: _expenses[index].id);
    await _db.updateExpense(withId);
    _expenses[index] = withId;
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  /// 删除交易
  Future<void> deleteExpense(int index) async {
    if (index < 0 || index >= _expenses.length) return;
    final id = _expenses[index].id;
    if (id != null) {
      await _db.deleteExpense(id);
    }
    _expenses.removeAt(index);
    notifyListeners();
  }

  /// 批量导入（JSON 还原时使用）
  Future<void> importExpenses(List<Expense> expenses) async {
    if (expenses.isEmpty) return;
    await _db.insertExpenses(expenses);
    await loadAll(); // 重新加载保持一致性
  }

  /// 搜索交易（实时，不走数据库）
  List<Expense> searchExpensesLocal(String keyword) {
    if (keyword.isEmpty) return _expenses;
    final kw = keyword.toLowerCase();
    return _expenses.where((e) {
      return e.note?.toLowerCase().contains(kw) == true ||
          e.majorCategory.toLowerCase().contains(kw) ||
          e.minorCategory.toLowerCase().contains(kw);
    }).toList();
  }

  /// 筛选交易
  List<Expense> filterExpensesLocal({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? majorCategory,
    String? paymentMethod,
  }) {
    return _expenses.where((e) {
      if (type != null && e.type != type) return false;
      if (startDate != null && e.date.isBefore(startDate)) return false;
      if (endDate != null &&
          e.date.isAfter(endDate.add(const Duration(days: 1)))) return false;
      if (majorCategory != null && e.majorCategory != majorCategory) {
        return false;
      }
      if (paymentMethod != null && e.paymentMethod != paymentMethod) {
        return false;
      }
      return true;
    }).toList();
  }

  /// 获取所有出现过的分类名
  List<String> getDistinctCategories() {
    return _expenses
        .map((e) => e.majorCategory)
        .toSet()
        .toList()
      ..sort();
  }

  // ==================== 预算 ====================

  /// 获取当月预算（从数据库）
  Future<Budget?> getCurrentMonthBudget() async {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return await _db.getBudget(month);
  }

  /// 设置/更新当月预算
  Future<void> setCurrentMonthBudget(double amount) async {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await _db.setBudget(Budget(month: month, amount: amount));
    notifyListeners();
  }

  /// 当月预算使用比例（0.0 ~ ∞）
  double getBudgetUsageRatio(double budgetAmount) {
    if (budgetAmount <= 0) return 0;
    return thisMonthExpenseTotal / budgetAmount;
  }

  // ==================== 周期模板 ====================

  List<RecurringTemplate> get templates => _templates;

  /// 新增周期模板
  Future<void> addTemplate(RecurringTemplate template) async {
    final id = await _db.insertTemplate(template);
    _templates.add(RecurringTemplate.fromMap({
      ...template.toMap(),
      'id': id,
    }));
    notifyListeners();
  }

  /// 更新周期模板
  Future<void> updateTemplate(int index, RecurringTemplate template) async {
    if (index < 0 || index >= _templates.length) return;
    await _db.updateTemplate(template);
    _templates[index] = template;
    notifyListeners();
  }

  /// 删除周期模板
  Future<void> deleteTemplate(int index) async {
    if (index < 0 || index >= _templates.length) return;
    final id = _templates[index].id;
    if (id != null) {
      await _db.deleteTemplate(id);
    }
    _templates.removeAt(index);
    notifyListeners();
  }

  // ==================== 统计查询 ====================

  /// 按分类统计（支出/收入，指定日期范围）
  Map<String, double> getCategoryTotalsInRange({
    required String type,
    required DateTime start,
    required DateTime end,
  }) {
    final map = <String, double>{};
    for (final e in _expenses) {
      if (e.type != type) continue;
      if (e.date.isBefore(start) || e.date.isAfter(end)) continue;
      map[e.majorCategory] = (map[e.majorCategory] ?? 0) + e.amount;
    }
    return map;
  }

  /// 按日期统计
  Map<DateTime, double> getDailyTotalsInRange({
    required String type,
    required DateTime start,
    required DateTime end,
  }) {
    final map = <DateTime, double>{};
    for (final e in _expenses) {
      if (e.type != type) continue;
      if (e.date.isBefore(start) || e.date.isAfter(end)) continue;
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      map[day] = (map[day] ?? 0) + e.amount;
    }
    return map;
  }

  // ==================== 内存管理 ====================

  /// 清理旧数据（保留最近 1000 条）
  Future<int> cleanOldData() async {
    final deleted = await _db.cleanOldTransactions(keepCount: 1000);
    if (deleted > 0) {
      await loadAll(); // 重新加载
    }
    return deleted;
  }

  /// 压缩数据库
  Future<void> vacuum() async {
    await _db.vacuum();
  }

  /// 获取数据库大小（可读格式）
  Future<String> getDatabaseSizeReadable() async {
    final bytes = await _db.getDatabaseSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
