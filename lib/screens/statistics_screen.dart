import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/app_state.dart';
import '../data/categories.dart';

/// 统计页面 - 饼图（分类占比）+ 柱状图（每日趋势）
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  // 当前选中的时间范围：0=本月, 1=上月, 2=本年
  int _selectedPeriod = 0;

  // 固定的12种图表颜色
  static const List<Color> _chartColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
    Color(0xFF795548),
    Color(0xFFCDDC39),
    Color(0xFF03A9F4),
    Color(0xFFFFEB3B),
  ];

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: // 本月
        return DateTime(now.year, now.month, 1);
      case 1: // 上月
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final year = now.month == 1 ? now.year - 1 : now.year;
        return DateTime(year, lastMonth, 1);
      case 2: // 本年
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: // 本月
        return DateTime(now.year, now.month + 1, 0);
      case 1: // 上月
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final year = now.month == 1 ? now.year - 1 : now.year;
        return DateTime(year, lastMonth + 1, 0);
      case 2: // 本年
        return DateTime(now.year, 12, 31);
      default:
        return now;
    }
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case 0:
        return '本月';
      case 1:
        return '上月';
      case 2:
        return '本年';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final categoryTotals =
              appState.getCategoryTotals(_startDate, _endDate);
          final dailyTotals =
              appState.getDailyTotals(_startDate, _endDate);
          final totalAmount =
              categoryTotals.values.fold(0.0, (sum, v) => sum + v);

          if (totalAmount == 0) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pie_chart,
                      size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('${_periodLabel}暂无支出记录',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 时间范围切换
                _buildPeriodSelector(theme),
                const SizedBox(height: 16),
                // 总金额
                Text(
                  '${_periodLabel}合计 ${NumberFormat.currency(symbol: '¥', decimalDigits: 2).format(totalAmount)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // 饼图
                Text('分类占比', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: _buildPieChart(categoryTotals, theme),
                ),
                const SizedBox(height: 16),
                // 分类排名列表
                _buildCategoryRanking(categoryTotals, totalAmount, theme),
                const SizedBox(height: 24),
                // 柱状图
                if (dailyTotals.isNotEmpty) ...[
                  Text('每日趋势', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: _buildBarChart(dailyTotals, theme),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('本月')),
        ButtonSegment(value: 1, label: Text('上月')),
        ButtonSegment(value: 2, label: Text('本年')),
      ],
      selected: {_selectedPeriod},
      onSelectionChanged: (selected) {
        setState(() {
          _selectedPeriod = selected.first;
        });
      },
    );
  }

  Widget _buildPieChart(
      Map<String, double> categoryTotals, ThemeData theme) {
    // 按金额降序排列
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return PieChart(
      PieChartData(
        sections: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final catEntry = entry.value;
          final color = _chartColors[index % _chartColors.length];
          return PieChartSectionData(
            value: catEntry.value,
            title: '${(catEntry.value / entries.fold(0.0, (s, e) => s + e.value) * 100).toStringAsFixed(0)}%',
            color: color,
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            radius: 70,
          );
        }).toList(),
        centerSpaceRadius: 35,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildCategoryRanking(
      Map<String, double> categoryTotals, double total, ThemeData theme) {
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final catEntry = entry.value;
        final color = _chartColors[index % _chartColors.length];
        final percentage = (catEntry.value / total * 100);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(catEntry.key, style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                NumberFormat.currency(symbol: '¥', decimalDigits: 2)
                    .format(catEntry.value),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(
      Map<DateTime, double> dailyTotals, ThemeData theme) {
    final entries = dailyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // 如果天数太多，只显示最近31天
    final displayEntries = entries.length > 31
        ? entries.sublist(entries.length - 31)
        : entries;

    final maxY = displayEntries
        .map((e) => e.value)
        .fold(0.0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = displayEntries[groupIndex];
              return BarTooltipItem(
                '${DateFormat('MM/dd').format(entry.key)}\n¥${entry.value.toStringAsFixed(2)}',
                TextStyle(
                  color: theme.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= displayEntries.length) {
                  return const SizedBox.shrink();
                }
                // 每5天显示一个日期标签
                if (displayEntries.length > 14) {
                  if (index % 5 != 0 &&
                      index != displayEntries.length - 1) {
                    return const SizedBox.shrink();
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MM/dd').format(displayEntries[index].key),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  '¥${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
        ),
        borderData: FlBorderData(show: false),
        barGroups: displayEntries.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: theme.colorScheme.primary,
                width: displayEntries.length > 20 ? 6 : 12,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
