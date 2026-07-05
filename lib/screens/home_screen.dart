import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import 'add_expense_screen.dart';

/// 首页 - 显示今日支出、快捷记账按钮、最近记录
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayTotal = expenseProvider.todayTotal;
    final recentExpenses = expenseProvider.expenses.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('小账本'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: ListenableBuilder(
        listenable: expenseProvider,
        builder: (context, _) {
          final recent = expenseProvider.expenses.take(5).toList();
          return SafeArea(
            child: Column(
              children: [
                // 今日支出卡片
                _buildTodayCard(theme),
                // 记账按钮
                _buildAddButton(theme),
                // 最近记录
                if (recent.isNotEmpty) ...[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.history,
                            size: 20, color: theme.colorScheme.outline),
                        const SizedBox(width: 8),
                        Text('最近记录',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recent.length,
                      itemBuilder: (context, index) {
                        final expense = recent[index];
                        return _buildExpenseItem(expense, theme);
                      },
                    ),
                  ),
                ] else
                  // 空状态
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: theme.colorScheme.outlineVariant),
                          const SizedBox(height: 16),
                          Text('还没有记录',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.outline)),
                          const SizedBox(height: 8),
                          Text('点击下方按钮开始记账吧',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outlineVariant)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('今日支出',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: '¥', decimalDigits: 2)
                  .format(expenseProvider.todayTotal),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: expenseProvider.todayTotal > 0
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '本月累计 ${NumberFormat.currency(symbol: '¥', decimalDigits: 2).format(expenseProvider.thisMonthTotal)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: () async {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(),
              ),
            );
            if (result != null && mounted) {
              // 从返回数据创建Expense并添加
              final expense = _createExpenseFromResult(result);
              appState.addExpense(expense);
            }
          },
          icon: const Icon(Icons.add_circle_outline, size: 28),
          label: const Text('记一笔', style: TextStyle(fontSize: 18)),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(expense, ThemeData theme) {
    final dateStr = DateFormat('MM/dd HH:mm').format(expense.date);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.shopping_bag_outlined,
              color: theme.colorScheme.onPrimaryContainer, size: 20),
        ),
        title: Text(
          '${expense.majorCategory} · ${expense.minorCategory}',
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          dateStr,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        trailing: Text(
          NumberFormat.currency(symbol: '¥', decimalDigits: 2)
              .format(expense.amount),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 从AddExpenseScreen返回的数据创建Expense对象
  dynamic _createExpenseFromResult(Map<String, dynamic> result) {
    // 构建Expense对象
    final majorCategory = result['majorCategory'] as String;
    // 使用默认小分类的第一个作为默认值...
    // 这里由AddExpenseScreen负责完整构建
    return result['expense'];
  }
}
