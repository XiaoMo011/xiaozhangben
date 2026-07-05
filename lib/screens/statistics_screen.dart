import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/app_state.dart';
import '../data/categories.dart';

/// 统计页面 - 支持支出/收入切换、饼图/柱状图/趋势图、背景自定义
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedPeriod = 0; // 0=本月 1=上月 2=本年
  int _selectedChart = 0; // 0=饼图 1=柱状图 2=趋势
  String _selectedType = 'expense'; // 'expense' 或 'income'
  Color _bgColor = const Color(0xFF1E293B);
  double _bgOpacity = 0.08;

  static const List<Color> _chartColors = [
    Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800),
    Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF00BCD4),
    Color(0xFFFF5722), Color(0xFF607D8B), Color(0xFF795548),
    Color(0xFFCDDC39), Color(0xFF03A9F4), Color(0xFFFFEB3B),
  ];

  static const List<Color> _presetColors = [
    Color(0xFF1E293B), Color(0xFF1A1A2E), Color(0xFF16213E),
    Color(0xFF0F3460), Color(0xFF2D3436), Color(0xFF533483),
    Color(0xFF2C3E50), Color(0xFF1B4332), Color(0xFF3C1642),
    Color(0xFF212529), Color(0xFF4A0E4E), Color(0xFF0D1B2A),
  ];

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: return DateTime(now.year, now.month, 1);
      case 1:
        final m = now.month == 1 ? 12 : now.month - 1;
        return DateTime(now.month == 1 ? now.year - 1 : now.year, m, 1);
      case 2: return DateTime(now.year, 1, 1);
      default: return DateTime(now.year, now.month, 1);
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: return _endOfMonth(now.year, now.month);
      case 1:
        final m = now.month == 1 ? 12 : now.month - 1;
        final y = now.month == 1 ? now.year - 1 : now.year;
        return _endOfMonth(y, m);
      case 2: return DateTime(now.year, 12, 31);
      default: return now;
    }
  }

  /// 安全获取月末日期（month 不溢出）
  DateTime _endOfMonth(int year, int month) {
    if (month == 12) return DateTime(year, 12, 31);
    return DateTime(year, month + 1, 0);
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case 0: return '本月';
      case 1: return '上月';
      case 2: return '本年';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('统计'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: '图表背景',
            onPressed: () => _showBgSettings(theme),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final catTotals = appState.getCategoryTotalsInRange(
              type: _selectedType, start: _startDate, end: _endDate);
          final dailyTotals = appState.getDailyTotalsInRange(
              type: _selectedType, start: _startDate, end: _endDate);
          final total = catTotals.values.fold(0.0, (s, v) => s + v);
          final hasData = total > 0;

          return Column(
            children: [
              // 选择器始终可见
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(children: [
                  _buildTypeToggle(theme),
                  const SizedBox(height: 10),
                  _buildPeriodSelector(theme),
                ]),
              ),
              const SizedBox(height: 12),
              // 内容区
              Expanded(
                child: !hasData
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pie_chart, size: 64,
                                color: theme.colorScheme.outlineVariant),
                            const SizedBox(height: 16),
                            Text(
                                '${_periodLabel}暂无${_selectedType == "expense" ? "支出" : "收入"}记录',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(color: theme.colorScheme.outline)),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(children: [
                          _buildTotalCard(theme, total),
                          const SizedBox(height: 12),
                          _buildChartSelector(theme),
                          const SizedBox(height: 12),
                          _buildChartContainer(catTotals, dailyTotals, theme),
                          const SizedBox(height: 16),
                          _buildRanking(catTotals, total, theme),
                        ]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeToggle(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: FilterChip(
            label: const Text('支出'),
            selected: _selectedType == 'expense',
            selectedColor: theme.colorScheme.error.withOpacity(0.2),
            checkmarkColor: theme.colorScheme.error,
            onSelected: (_) => setState(() => _selectedType = 'expense'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilterChip(
            label: const Text('收入'),
            selected: _selectedType == 'income',
            selectedColor: Colors.green.withOpacity(0.2),
            checkmarkColor: Colors.green,
            onSelected: (_) => setState(() => _selectedType = 'income'),
          ),
        ),
      ],
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
      onSelectionChanged: (v) => setState(() => _selectedPeriod = v.first),
    );
  }

  Widget _buildTotalCard(ThemeData theme, double total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${_periodLabel}合计  ', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline)),
            Text(NumberFormat.currency(symbol: '¥', decimalDigits: 2).format(total),
                style: theme.textTheme.headlineMedium?.copyWith(
                    color: _selectedType == 'expense' ? theme.colorScheme.error : Colors.green,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSelector(ThemeData theme) {
    return Row(
      children: [
        _chartChip('饼图', 0, Icons.pie_chart, theme),
        const SizedBox(width: 8),
        _chartChip('柱状图', 1, Icons.bar_chart, theme),
        const SizedBox(width: 8),
        _chartChip('趋势', 2, Icons.show_chart, theme),
      ],
    );
  }

  Widget _chartChip(String label, int idx, IconData icon, ThemeData theme) {
    final sel = _selectedChart == idx;
    return Expanded(
      child: FilterChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: sel ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4), Text(label),
        ]),
        selected: sel,
        onSelected: (_) => setState(() => _selectedChart = idx),
        selectedColor: theme.colorScheme.secondaryContainer,
      ),
    );
  }

  Widget _buildChartContainer(Map<String, double> cat, Map<DateTime, double> daily, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgColor.withOpacity(_bgOpacity),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bgColor.withOpacity(_bgOpacity * 1.5), width: 0.5),
      ),
      child: _buildChart(cat, daily, theme),
    );
  }

  Widget _buildChart(Map<String, double> cat, Map<DateTime, double> daily, ThemeData theme) {
    switch (_selectedChart) {
      case 0: return _pieChart(cat, theme);
      case 1: return _barChart(daily, theme);
      case 2: return _lineChart(daily, theme);
      default: return _pieChart(cat, theme);
    }
  }

  // ---- 饼图 ----
  Widget _pieChart(Map<String, double> cat, ThemeData theme) {
    final entries = cat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const SizedBox.shrink();
    final total = entries.fold(0.0, (s, e) => s + e.value);
    return SizedBox(height: 240, child: Stack(alignment: Alignment.center, children: [
      PieChart(PieChartData(
        sections: entries.asMap().entries.map((e) => PieChartSectionData(
          value: e.value.value,
          color: _chartColors[e.key % _chartColors.length],
          title: e.value.value > 0 ? '${(e.value.value / total * 100).toStringAsFixed(0)}%' : '',
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 75, titlePositionPercentageOffset: 0.6,
        )).toList(),
        sectionsSpace: 3, borderData: FlBorderData(show: false),
      )),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_selectedType == 'expense' ? '总支出' : '总收入', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        Text(NumberFormat.currency(symbol: '¥', decimalDigits: 0).format(total),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ]),
    ]));
  }

  // ---- 柱状图 ----
  Widget _barChart(Map<DateTime, double> daily, ThemeData theme) {
    final entries = daily.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) return const Center(child: Text('暂无每日数据'));
    final display = entries.length > 31 ? entries.sublist(entries.length - 31) : entries;
    final maxY = display.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
    return SizedBox(height: 220, child: BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround, maxY: maxY * 1.3,
      barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (g, gi, r, ri) => BarTooltipItem(
          '${DateFormat('MM/dd').format(display[gi].key)}\n¥${display[gi].value.toStringAsFixed(2)}',
          TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.bold, fontSize: 12)),
      )),
      titlesData: FlTitlesData(show: true,
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 26,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= display.length) return const SizedBox.shrink();
            if (display.length > 14 && i % 5 != 0 && i != display.length - 1) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 6), child: Text(DateFormat('MM/dd').format(display[i].key), style: const TextStyle(fontSize: 10)));
          })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 38,
          getTitlesWidget: (v, _) => Text('¥${v.toInt()}', style: const TextStyle(fontSize: 10)))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY > 0 ? maxY / 4 : 1),
      borderData: FlBorderData(show: false),
      barGroups: display.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(toY: e.value.value,
          color: Color.lerp(theme.colorScheme.primary, theme.colorScheme.error, maxY > 0 ? e.value.value / maxY : 0)!,
          width: display.length > 20 ? 6 : 11,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
      ])).toList(),
    )));
  }

  // ---- 趋势线 ----
  Widget _lineChart(Map<DateTime, double> daily, ThemeData theme) {
    final entries = daily.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) return const Center(child: Text('暂无每日数据'));
    final display = entries.length > 31 ? entries.sublist(entries.length - 31) : entries;
    final dailyMax = display.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);

    double cum = 0;
    final cumSpots = <FlSpot>[];
    for (var i = 0; i < display.length; i++) {
      cum += display[i].value;
      cumSpots.add(FlSpot(i.toDouble(), cum));
    }
    final maxY = dailyMax > cumSpots.last.y ? dailyMax : cumSpots.last.y;
    final spots = display.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList();

    return Column(children: [
      SizedBox(height: 220, child: LineChart(LineChartData(lineBarsData: [
        LineChartBarData(spots: spots, isCurved: true, curveSmoothness: 0.3,
          color: theme.colorScheme.primary, barWidth: 2.5,
          dotData: FlDotData(show: display.length <= 31, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 3, color: theme.colorScheme.primary, strokeWidth: 1, strokeColor: Colors.white)),
          belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withOpacity(0.08))),
        LineChartBarData(spots: cumSpots, isCurved: true, curveSmoothness: 0.3,
          color: theme.colorScheme.error.withOpacity(0.6), barWidth: 2, dashArray: [8, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: theme.colorScheme.error.withOpacity(0.03))),
      ],
        lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touched) => touched.map((s) => s.barIndex == 0
              ? LineTooltipItem('${DateFormat('MM/dd').format(display[s.spotIndex].key)}\n¥${display[s.spotIndex].value.toStringAsFixed(2)}',
                  TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.bold, fontSize: 12))
              : LineTooltipItem('累计 ¥${cumSpots[s.spotIndex].y.toStringAsFixed(2)}',
                  TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.bold, fontSize: 12))).toList(),
        )),
        titlesData: FlTitlesData(show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 26,
            getTitlesWidget: (v, _) {
              final i = v.toInt(); if (i < 0 || i >= display.length) return const SizedBox.shrink();
              if (display.length > 14 && i % 5 != 0 && i != display.length - 1) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(top: 6), child: Text(DateFormat('MM/dd').format(display[i].key), style: const TextStyle(fontSize: 10)));
            })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 38,
            getTitlesWidget: (v, _) => Text('¥${v.toInt()}', style: const TextStyle(fontSize: 10)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY > 0 ? maxY / 4 : 1),
        borderData: FlBorderData(show: false), minY: 0,
      ))),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legend(theme.colorScheme.primary, '每日${_selectedType == "expense" ? "支出" : "收入"}'),
        const SizedBox(width: 20),
        _legend(theme.colorScheme.error, '累计'),
      ]),
    ]);
  }

  Widget _legend(Color c, String l) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 3, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4), Text(l, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  ]);

  Widget _buildRanking(Map<String, double> cat, double total, ThemeData theme) {
    final entries = cat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('分类排行', style: theme.textTheme.titleMedium), const SizedBox(height: 6),
      ...entries.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: _chartColors[e.key % _chartColors.length], borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(child: Text(e.value.key, style: theme.textTheme.bodyMedium)),
        Text(NumberFormat.currency(symbol: '¥', decimalDigits: 2).format(e.value.value),
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        SizedBox(width: 44, child: Text('${total > 0 ? (e.value.value / total * 100).toStringAsFixed(1) : 0}%',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), textAlign: TextAlign.right)),
      ]))),
    ]);
  }

  void _showBgSettings(ThemeData theme) {
    Color tc = _bgColor; double to = _bgOpacity;
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.palette_outlined, color: theme.colorScheme.primary), const SizedBox(width: 8),
            Text('图表背景', style: theme.textTheme.titleLarge), const Spacer(),
            TextButton.icon(onPressed: () => setS(() { tc = const Color(0xFF1E293B); to = 0.08; }),
                icon: const Icon(Icons.restore, size: 16), label: const Text('重置'))]),
          const SizedBox(height: 16),
          Container(height: 60, width: double.infinity, decoration: BoxDecoration(color: tc.withOpacity(to), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('预览'))),
          const SizedBox(height: 16),
          Text('颜色', style: theme.textTheme.titleSmall), const SizedBox(height: 8),
          GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1),
            itemCount: _presetColors.length,
            itemBuilder: (_, i) {
              final sel = tc == _presetColors[i];
              return GestureDetector(onTap: () => setS(() => tc = _presetColors[i]),
                child: Container(decoration: BoxDecoration(color: _presetColors[i], borderRadius: BorderRadius.circular(8),
                  border: sel ? Border.all(color: theme.colorScheme.primary, width: 2.5) : null,
                  boxShadow: sel ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.4), blurRadius: 5)] : null),
                  child: sel ? const Icon(Icons.check, color: Colors.white, size: 20) : null));
            }),
          const SizedBox(height: 14),
          Row(children: [Text('透明度', style: theme.textTheme.titleSmall), const Spacer(),
            Text('${(to * 100).toInt()}%', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))]),
          Slider(value: to, min: 0, max: 0.5, divisions: 50, onChanged: (v) => setS(() => to = v)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: () { setState(() { _bgColor = tc; _bgOpacity = to; }); Navigator.pop(ctx); },
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text('应用', style: TextStyle(fontSize: 16)))),
        ]))));
  }
}
