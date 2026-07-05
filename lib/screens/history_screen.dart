import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../data/categories.dart';
import '../data/preferences.dart';
import 'add_expense_screen.dart';

/// 明细页面 - 日期快捷筛选、搜索、编辑、删除
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  // 日期快捷选择: 0=近7天 1=本周 2=本月 3=本年 4=自定义
  int _datePreset = -1;
  DateTime? _customStart;
  DateTime? _customEnd;

  // 筛选状态
  String? _filterType;
  String? _filterCategory;
  String? _filterPayment;

  @override
  void initState() {
    super.initState();
    _datePreset = appPrefs.defaultDateRange;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---- 日期快捷范围 ----
  (DateTime, DateTime) _presetRange(int preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case 0: // 近7天
        return (today.subtract(const Duration(days: 6)), today.add(const Duration(days: 1)));
      case 1: // 本周（周一到周日）
        final weekday = now.weekday; // 1=周一
        final monday = today.subtract(Duration(days: weekday - 1));
        return (monday, monday.add(const Duration(days: 7)));
      case 2: // 本月
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0).add(const Duration(days: 1)));
      case 3: // 本年
        return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
      default:
        return (DateTime(2020), DateTime.now().add(const Duration(days: 1)));
    }
  }

  String _presetLabel(int preset) {
    switch (preset) { case 0: return '近7天'; case 1: return '本周'; case 2: return '本月'; case 3: return '本年'; default: return ''; }
  }

  List _getFilteredList() {
    var list = appState.expenses;

    if (_datePreset >= 0 && _datePreset <= 3) {
      final (start, end) = _presetRange(_datePreset);
      list = appState.filterExpensesLocal(startDate: start, endDate: end);
    } else if (_datePreset == 4 && (_customStart != null || _customEnd != null)) {
      list = appState.filterExpensesLocal(startDate: _customStart, endDate: _customEnd);
    }

    if (_filterType != null || _filterCategory != null || _filterPayment != null) {
      list = appState.filterExpensesLocal(
        type: _filterType,
        majorCategory: _filterCategory,
        paymentMethod: _filterPayment,
      );
    }

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

  double _filteredTotal(List filtered) {
    double expense = 0, income = 0;
    for (final e in filtered) {
      if (e.type == 'expense') { expense += e.amount; } else { income += e.amount; }
    }
    return expense - income;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSearching ? _searchField(theme) : const Text('明细'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() { _isSearching = !_isSearching; if (!_isSearching) _searchCtrl.clear(); }),
          ),
          IconButton(
            icon: Icon(Icons.filter_alt_outlined),
            onPressed: () => _showFilterPanel(theme),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final filtered = _getFilteredList();
          final net = _filteredTotal(filtered);

          if (appState.expenses.isEmpty) return _empty(theme);

          return Column(children: [
            // 日期快捷栏
            _buildDateBar(theme),
            // 汇总条
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: theme.colorScheme.surfaceContainerLow,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _sumItem(theme, '支出 ¥${NumberFormat.currency(symbol: '', decimalDigits: 0).format(filtered.where((e) => e.type == 'expense').fold(0.0, (s, e) => s + e.amount))}', theme.colorScheme.error),
                _sumItem(theme, '收入 ¥${NumberFormat.currency(symbol: '', decimalDigits: 0).format(filtered.where((e) => e.type == 'income').fold(0.0, (s, e) => s + e.amount))}', Colors.green),
                _sumItem(theme, '${filtered.length} 笔', null),
              ]),
            ),
            // 列表
            Expanded(
              child: filtered.isEmpty
                ? Center(child: Text('无匹配记录', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: filtered.length,
                    itemBuilder: (c, i) => _card(filtered[i], theme)),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildDateBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(children: [
        Expanded(
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            for (int i = 0; i <= 4; i++) ...[
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: i == 4
                  ? ActionChip(
                      label: Text(_datePreset == 4 && (_customStart != null || _customEnd != null)
                        ? '${_customStart != null ? DateFormat('MM/dd').format(_customStart!) : '...'}~${_customEnd != null ? DateFormat('MM/dd').format(_customEnd!) : '...'}'
                        : '自定义',
                        style: const TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.calendar_today, size: 14),
                      onPressed: () => _showDateRangePicker(theme),
                      backgroundColor: _datePreset == 4 ? theme.colorScheme.primaryContainer : null,
                    )
                  : ChoiceChip(
                      label: Text(_presetLabel(i), style: const TextStyle(fontSize: 12)),
                      selected: _datePreset == i,
                      onSelected: (_) => setState(() {
                        _datePreset = i; _customStart = null; _customEnd = null;
                        appPrefs.setDefaultDateRange(i);
                      }),
                    ),
              ),
            ],
          ])),
        ),
      ]),
    );
  }

  Future<void> _showDateRangePicker(ThemeData theme) async {
    DateTime start = _customStart ?? DateTime.now().subtract(const Duration(days: 7));
    DateTime end = _customEnd ?? DateTime.now();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) =>
        Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('自定义日期范围', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(context: ctx, initialDate: start, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (d != null) setS(() => start = d);
                },
                child: Text(DateFormat('yyyy/MM/dd').format(start)))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('至')),
              Expanded(child: OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(context: ctx, initialDate: end, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (d != null) setS(() => end = d);
                },
                child: Text(DateFormat('yyyy/MM/dd').format(end)))),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () {
                setState(() { _datePreset = 4; _customStart = start; _customEnd = end; });
                Navigator.pop(ctx);
              }, child: const Text('应用'))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _sumItem(ThemeData t, String l, Color? c) => Text(l, style: t.textTheme.bodySmall?.copyWith(color: c ?? t.colorScheme.outline, fontWeight: c != null ? FontWeight.bold : null));

  Widget _empty(ThemeData theme) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.outlineVariant),
    const SizedBox(height: 16),
    Text('暂无记录', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)),
  ]));

  Widget _searchField(ThemeData theme) => TextField(
    controller: _searchCtrl, autofocus: true,
    decoration: InputDecoration(hintText: '搜索备注、分类...', border: InputBorder.none, hintStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6))),
    style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
    onChanged: (_) => setState(() {}),
  );

  Widget _card(expense, ThemeData theme) {
    final dateStr = DateFormat('MM月dd日 HH:mm').format(expense.date);
    final isExpense = expense.type == 'expense';
    final color = isExpense ? theme.colorScheme.error : Colors.green;
    final isToday = DateTime(expense.date.year, expense.date.month, expense.date.day) == DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return Dismissible(
      key: Key('tx_${expense.id}_${expense.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.delete, color: theme.colorScheme.onError)),
      confirmDismiss: (_) => _confirmDelete(context, expense, theme),
      onDismissed: (_) {
        final idx = appState.expenses.indexOf(expense);
        if (idx >= 0) appState.deleteExpense(idx);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除'), duration: Duration(seconds: 2)));
      },
      child: Card(margin: const EdgeInsets.only(bottom: 6), child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => AddExpenseScreen(existingExpense: expense)));
          if (result != null && mounted) {
            final updated = result['expense'];
            final idx = appState.expenses.indexOf(expense);
            if (idx >= 0) appState.updateExpense(idx, updated);
          }
        },
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(isExpense ? Icons.trending_down : Icons.trending_up, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${expense.majorCategory} · ${expense.minorCategory}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Row(children: [
              if (isToday) ...[Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: theme.colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(3)), child: const Text('今天', style: TextStyle(fontSize: 10))), const SizedBox(width: 5)],
              Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(width: 5),
              Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(3)), child: Text(expense.paymentMethod, style: const TextStyle(fontSize: 10))),
            ]),
          ])),
          Text('${isExpense ? '-' : '+'}¥${expense.amount.toStringAsFixed(2)}', style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ])),
      )),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, expense, ThemeData theme) {
    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(expense.date);
    final isExpense = expense.type == 'expense';
    final amountStr = NumberFormat.currency(symbol: '¥', decimalDigits: 2).format(expense.amount);
    return showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 26), const SizedBox(width: 8), const Text('确认删除')]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('确定要删除这笔记录吗？删除后无法恢复。', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
        const SizedBox(height: 14),
        Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _dr(theme, '类型', isExpense ? '支出' : '收入', isExpense ? theme.colorScheme.error : Colors.green),
            const SizedBox(height: 6), _dr(theme, '金额', amountStr, isExpense ? theme.colorScheme.error : Colors.green),
            const SizedBox(height: 6), _dr(theme, '分类', '${expense.majorCategory} · ${expense.minorCategory}', null),
            const SizedBox(height: 6), _dr(theme, '日期', dateStr, null),
            const SizedBox(height: 6), _dr(theme, '方式', expense.paymentMethod, null),
            if (expense.note != null && expense.note!.isNotEmpty) ...[const SizedBox(height: 6), _dr(theme, '备注', expense.note!, null)],
          ])),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error), child: const Text('确认删除')),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ));
  }

  Widget _dr(ThemeData t, String l, String v, Color? c) => Row(children: [SizedBox(width: 36, child: Text(l, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline))), Expanded(child: Text(v, style: t.textTheme.bodyMedium?.copyWith(color: c, fontWeight: c != null ? FontWeight.w600 : null)))]);

  // ---- 筛选面板 ----
  void _showFilterPanel(ThemeData theme) {
    String? tt = _filterType, tc = _filterCategory, tp = _filterPayment;
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, sS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('筛选条件', style: theme.textTheme.titleLarge), const SizedBox(height: 16),
          Text('类型', style: theme.textTheme.titleSmall), const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            _fc('全部', null, tt, () => sS(() => tt = null)),
            _fc('支出', 'expense', tt, () => sS(() => tt = 'expense')),
            _fc('收入', 'income', tt, () => sS(() => tt = 'income')),
          ]),
          const SizedBox(height: 12),
          Text('分类', style: theme.textTheme.titleSmall), const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: [
            _fc('全部', null, tc, () => sS(() => tc = null)),
            ...appState.getDistinctCategories().map((c) => _fc(c, c, tc, () => sS(() => tc = c))),
          ]),
          const SizedBox(height: 12),
          Text('支付方式', style: theme.textTheme.titleSmall), const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            _fc('全部', null, tp, () => sS(() => tp = null)),
            ...paymentMethods.map((p) => _fc(p, p, tp, () => sS(() => tp = p))),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () { setState(() { _filterType = tt; _filterCategory = tc; _filterPayment = tp; }); Navigator.pop(ctx); }, child: const Text('应用筛选'))),
          ]),
        ]),
      )));
  }

  Widget _fc(String l, String? v, String? cur, VoidCallback t) => ActionChip(
    label: Text(l, style: const TextStyle(fontSize: 12)), onPressed: t,
    backgroundColor: v == cur ? Theme.of(context).colorScheme.primaryContainer : null);
}
