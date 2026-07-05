import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_state.dart';
import '../data/preferences.dart';
import 'add_expense_screen.dart';

/// 首页 —— 今日收支、月度概览、快捷记账
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('小账本'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: appPrefs,
        builder: (context, _) {
          return ListenableBuilder(
            listenable: appState,
            builder: (context, _) {
              final recent = appState.expenses.take(5).toList();
              return Stack(
                children: [
                  // 背景图片层
                  _buildBackground(theme),
                  // 内容层
                  SafeArea(
                    child: Column(children: [
                      if (recent.isEmpty && appState.expenses.isEmpty)
                        Expanded(child: _buildEmptyState(theme))
                      else
                        Expanded(child: CustomScrollView(slivers: [
                          SliverToBoxAdapter(child: _buildTodayCard(theme)),
                          SliverToBoxAdapter(child: _buildMonthRow(theme)),
                          SliverToBoxAdapter(child: _buildAddButton(theme)),
                          if (recent.isNotEmpty) ...[
                            SliverToBoxAdapter(child: _buildSectionTitle(theme)),
                            SliverList(delegate: SliverChildBuilderDelegate(
                              (context, i) => _buildItem(recent[i], theme),
                              childCount: recent.length,
                            )),
                          ],
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        ])),
                    ]),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ---- 背景 ----
  Widget _buildBackground(ThemeData theme) {
    final bgPath = appPrefs.bgImagePath;
    if (bgPath != null && File(bgPath).existsSync()) {
      return Positioned.fill(
        child: Opacity(
          opacity: 0.06,
          child: Image.file(File(bgPath), fit: BoxFit.cover),
        ),
      );
    }
    // 默认渐变背景
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.15),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.35],
          ),
        ),
      ),
    );
  }

  // ---- 空状态 ----
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.receipt_long_outlined, size: 36, color: theme.colorScheme.primary.withOpacity(0.6)),
        ),
        const SizedBox(height: 20),
        Text('开始记账吧', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.outline)),
        const SizedBox(height: 8),
        Text('点击下方按钮记录第一笔', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outlineVariant)),
        const SizedBox(height: 32),
        _buildAddButton(theme),
      ]),
    );
  }

  // ---- 今日收支 ----
  Widget _buildTodayCard(ThemeData theme) {
    final fmt = (double v) => NumberFormat.currency(symbol: '¥', decimalDigits: 2).format(v);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Row(children: [
            Expanded(child: _statCol(theme, '今日支出', fmt(appState.todayExpenseTotal), theme.colorScheme.error)),
            Container(width: 1, height: 36, color: Colors.grey.shade200),
            Expanded(child: _statCol(theme, '今日收入', fmt(appState.todayIncomeTotal), Colors.green)),
          ]),
        ),
      ),
    );
  }

  Widget _statCol(ThemeData theme, String label, String value, Color color) {
    return Column(children: [
      Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
      const SizedBox(height: 6),
      Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
    ]);
  }

  // ---- 月度概览 ----
  Widget _buildMonthRow(ThemeData theme) {
    final fmt = (double v) => NumberFormat.currency(symbol: '¥', decimalDigits: 0).format(v);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        _miniBadge(theme, '本月支出', fmt(appState.thisMonthExpenseTotal), theme.colorScheme.error),
        const SizedBox(width: 10),
        _miniBadge(theme, '本月收入', fmt(appState.thisMonthIncomeTotal), Colors.green),
        const SizedBox(width: 10),
        _miniBadge(theme, '结余', fmt(appState.thisMonthBalance), appState.thisMonthBalance >= 0 ? Colors.green : theme.colorScheme.error),
      ]),
    );
  }

  Widget _miniBadge(ThemeData theme, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // ---- 记账按钮 ----
  Widget _buildAddButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        height: 50,
        child: FilledButton.icon(
          onPressed: () async {
            final r = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
            if (r != null && mounted) await appState.addExpense(r['expense']);
          },
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text('记一笔', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text('最近记录', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.outline)),
    );
  }

  // ---- 记录项 ----
  Widget _buildItem(expense, ThemeData theme) {
    final isExpense = expense.type == 'expense';
    final c = isExpense ? theme.colorScheme.error : Colors.green;
    final dateStr = DateFormat('MM/dd HH:mm').format(expense.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final r = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => AddExpenseScreen(existingExpense: expense)));
          if (r != null && mounted) {
            final u = r['expense']; final idx = appState.expenses.indexOf(expense);
            if (idx >= 0) await appState.updateExpense(idx, u);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Icon(isExpense ? Icons.trending_down : Icons.trending_up, color: c, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${expense.majorCategory} · ${expense.minorCategory}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Row(children: [
                Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(3)), child: Text(expense.paymentMethod, style: const TextStyle(fontSize: 10, color: Colors.grey))),
              ]),
            ])),
            Text('${isExpense ? "-" : "+"}¥${expense.amount.toStringAsFixed(2)}', style: theme.textTheme.titleSmall?.copyWith(color: c, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
