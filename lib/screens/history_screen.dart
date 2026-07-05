import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import 'add_expense_screen.dart';

/// 明细页面 - 查看所有支出记录，支持删除和筛选
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('明细'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final expenses = appState.expenses;

          if (expenses.isEmpty) {
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
              // 本月汇总
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surfaceContainerLow,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(theme, '本月支出',
                        appState.thisMonthTotal),
                    _buildSummaryItem(
                        theme, '共${expenses.length}笔', null),
                  ],
                ),
              ),
              // 列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    return _buildExpenseCard(
                        expenses[index], index, theme);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(ThemeData theme, String label, double? amount) {
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline)),
        if (amount != null)
          Text(
            NumberFormat.currency(symbol: '¥', decimalDigits: 2)
                .format(amount),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildExpenseCard(expense, int index, ThemeData theme) {
    final dateStr = DateFormat('MM月dd日 HH:mm').format(expense.date);
    final isToday = DateTime(expense.date.year, expense.date.month,
            expense.date.day) ==
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Dismissible(
      key: Key('expense_${expense.hashCode}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: Text(
                '确定要删除这笔 ¥${expense.amount.toStringAsFixed(2)} 的记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        appState.deleteExpense(index);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('已删除'),
              duration: Duration(seconds: 2)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            // 编辑记录
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (ctx) =>
                    AddExpenseScreen(existingExpense: expense),
              ),
            );
            if (result != null && mounted) {
              final updated = result['expense'];
              appState.updateExpense(index, updated);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 分类图标
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${expense.majorCategory} · ${expense.minorCategory}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isToday)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('今天',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme
                                          .onTertiaryContainer)),
                            ),
                          if (isToday) const SizedBox(width: 6),
                          Text(dateStr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline)),
                          if (expense.note != null &&
                              expense.note!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                expense.note!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // 金额
                Text(
                  NumberFormat.currency(symbol: '¥', decimalDigits: 2)
                      .format(expense.amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
