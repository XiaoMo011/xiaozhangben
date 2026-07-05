import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../data/categories.dart';
import 'add_expense_screen.dart';

/// 明细页面 - 搜索、筛选、编辑、删除
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  // 筛选状态
  String? _filterType;
  DateTime? _filterStart;
  DateTime? _filterEnd;
  String? _filterCategory;
  String? _filterPayment;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredList() {
    var list = appState.expenses;

    // 条件筛选先执行
    if (_filterType != null ||
        _filterStart != null ||
        _filterEnd != null ||
        _filterCategory != null ||
        _filterPayment != null) {
      list = appState.filterExpensesLocal(
        type: _filterType,
        startDate: _filterStart,
        endDate: _filterEnd,
        majorCategory: _filterCategory,
        paymentMethod: _filterPayment,
      );
    }

    // 搜索在筛选结果上叠加
    if (_isSearching && _searchCtrl.text.isNotEmpty) {
      final kw = _searchCtrl.text.toLowerCase();
      list = list.where((e) =>
        (e.note?.toLowerCase().contains(kw) == true) ||
        e.majorCategory.toLowerCase().contains(kw) ||
        e.minorCategory.toLowerCase().contains(kw)
      ).toList();
    }

    return list;
  }

  bool get _hasActiveFilters =>
      _filterType != null ||
      _filterStart != null ||
      _filterEnd != null ||
      _filterCategory != null ||
      _filterPayment != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSearching ? _buildSearchField(theme) : const Text('明细'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchCtrl.clear();
            }),
          ),
          IconButton(
            icon: Icon(
              _hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _hasActiveFilters ? theme.colorScheme.primary : null,
            ),
            onPressed: () => _showFilterPanel(theme),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final filtered = _getFilteredList();

          if (appState.expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('暂无记录',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 汇总 + 筛选标记
              if (_hasActiveFilters)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('已筛选：${filtered.length} 条',
                          style: theme.textTheme.bodySmall),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          _filterType = null;
                          _filterStart = null;
                          _filterEnd = null;
                          _filterCategory = null;
                          _filterPayment = null;
                        }),
                        child: const Text('清除筛选'),
                      ),
                    ],
                  ),
                ),
              // 汇总条
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: theme.colorScheme.surfaceContainerLow,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _sumItem(theme, '本月支出', appState.thisMonthExpenseTotal,
                        theme.colorScheme.error),
                    _sumItem(theme, '本月收入', appState.thisMonthIncomeTotal,
                        Colors.green),
                    _sumItem(theme, '共${filtered.length}笔', null, null),
                  ],
                ),
              ),
              // 列表
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('无匹配记录',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: theme.colorScheme.outline)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _buildCard(filtered[index], theme),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sumItem(ThemeData theme, String label, double? amount, Color? color) {
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        if (amount != null)
          Text(
            NumberFormat.currency(symbol: '¥', decimalDigits: 0).format(amount),
            style: theme.textTheme.titleSmall
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchCtrl,
      autofocus: true,
      decoration: InputDecoration(
        hintText: '搜索备注、分类...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6)),
      ),
      style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildCard(expense, ThemeData theme) {
    final dateStr = DateFormat('MM月dd日 HH:mm').format(expense.date);
    final isExpense = expense.type == 'expense';
    final amountColor = isExpense ? theme.colorScheme.error : Colors.green;
    final prefix = isExpense ? '-' : '+';
    final isToday = DateTime(expense.date.year, expense.date.month, expense.date.day) ==
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Dismissible(
      key: Key('tx_${expense.id}_${expense.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) => _showDeleteDialog(context, expense, theme),
      onDismissed: (_) {
        final idx = appState.expenses.indexOf(expense);
        if (idx >= 0) appState.deleteExpense(idx);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除'), duration: Duration(seconds: 2)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(existingExpense: expense)),
            );
            if (result != null && mounted) {
              final updated = result['expense'];
              final idx = appState.expenses.indexOf(expense);
              if (idx >= 0) appState.updateExpense(idx, updated);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isExpense ? Icons.trending_down : Icons.trending_up,
                    color: amountColor, size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${expense.majorCategory} · ${expense.minorCategory}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (isToday) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text('今天', style: const TextStyle(fontSize: 10)),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(dateStr,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                          const SizedBox(width: 5),
                          _typeBadge(expense.paymentMethod, theme),
                        ],
                      ),
                    ],
                  ),
                ),
                Text('$prefix¥${expense.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: amountColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeBadge(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }

  // ==================== 筛选面板 ====================

  void _showFilterPanel(ThemeData theme) {
    String? tempType = _filterType;
    DateTime? tempStart = _filterStart;
    DateTime? tempEnd = _filterEnd;
    String? tempCategory = _filterCategory;
    String? tempPayment = _filterPayment;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('筛选条件', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  // 类型
                  Text('类型', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('全部', null, tempType, () => setSheet(() => tempType = null)),
                      _filterChip('支出', 'expense', tempType, () => setSheet(() => tempType = 'expense')),
                      _filterChip('收入', 'income', tempType, () => setSheet(() => tempType = 'income')),
                    ].map((w) => w).toList(),
                  ),
                  const SizedBox(height: 12),
                  // 日期范围
                  Text('日期范围', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: tempStart ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setSheet(() => tempStart = d);
                          },
                          child: Text(tempStart != null
                              ? DateFormat('MM/dd').format(tempStart!)
                              : '开始日期'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('至', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: tempEnd ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setSheet(() => tempEnd = d);
                          },
                          child: Text(tempEnd != null
                              ? DateFormat('MM/dd').format(tempEnd!)
                              : '结束日期'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 分类
                  Text('分类', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _filterChip('全部', null, tempCategory, () => setSheet(() => tempCategory = null)),
                      ...appState.getDistinctCategories().map((c) =>
                          _filterChip(c, c, tempCategory, () => setSheet(() => tempCategory = c))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 支付方式
                  Text('支付方式', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('全部', null, tempPayment, () => setSheet(() => tempPayment = null)),
                      ...paymentMethods.map((p) =>
                          _filterChip(p, p, tempPayment, () => setSheet(() => tempPayment = p))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _filterType = tempType;
                              _filterStart = tempStart;
                              _filterEnd = tempEnd;
                              _filterCategory = tempCategory;
                              _filterPayment = tempPayment;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('应用筛选'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip(String label, String? value, String? current,
      VoidCallback onTap) {
    final isSelected = value == current;
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
    );
  }

  // ==================== 删除确认 ====================

  Future<bool?> _showDeleteDialog(BuildContext context, expense, ThemeData theme) {
    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(expense.date);
    final isExpense = expense.type == 'expense';
    final amountStr = NumberFormat.currency(symbol: '¥', decimalDigits: 2).format(expense.amount);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 26),
          const SizedBox(width: 8),
          const Text('确认删除'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除这笔记录吗？删除后无法恢复。',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(theme, '类型', isExpense ? '支出' : '收入',
                      isExpense ? theme.colorScheme.error : Colors.green),
                  const SizedBox(height: 6),
                  _detailRow(theme, '金额', '$amountStr',
                      isExpense ? theme.colorScheme.error : Colors.green),
                  const SizedBox(height: 6),
                  _detailRow(theme, '分类', '${expense.majorCategory} · ${expense.minorCategory}', null),
                  const SizedBox(height: 6),
                  _detailRow(theme, '日期', dateStr, null),
                  const SizedBox(height: 6),
                  _detailRow(theme, '方式', expense.paymentMethod, null),
                  if (expense.note != null && expense.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _detailRow(theme, '备注', expense.note!, null),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            child: const Text('确认删除'),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value, Color? color) {
    return Row(
      children: [
        SizedBox(
            width: 36,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline))),
        Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: color, fontWeight: color != null ? FontWeight.w600 : null))),
      ],
    );
  }
}
