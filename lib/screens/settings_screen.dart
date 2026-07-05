import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import "package:excel/excel.dart" as excel;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/categories.dart';
import '../data/app_state.dart';
import '../data/preferences.dart';
import '../data/note_history.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/recurring_template.dart';

/// 我的 - 设置页面
/// 所有自定义项统一在"自定义"下，只显示一级标题，其余折叠
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: appPrefs,
        builder: (context, _) => ListenableBuilder(
          listenable: appState,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 32),
            children: [
              // ===== 自定义 =====
              _section(context, theme, '自定义', Icons.tune, [
                _bgImageTile(context, theme),
                _bgOpacityTile(context, theme),
                _defaultDateTile(context, theme),
                _noteHistoryTile(context, theme),
                _presetNotesTile(context, theme),
              ]),
              // ===== 记账管理 =====
              _section(context, theme, '记账管理', Icons.account_balance_wallet_outlined, [
                _budgetTile(context, theme),
                _recurringTile(context, theme),
              ]),
              // ===== 分类管理 =====
              _section(context, theme, '分类管理', Icons.category_outlined, [
                ListTile(
                  leading: _icon(Icons.folder_outlined, theme),
                  title: const Text('管理支出分类'),
                  subtitle: Text('共 ${expenseCategories.length} 个大类 · ${incomeCategories.length} 个收入类',
                      style: _sub(theme)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  shape: _shape(),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CategoryManageScreen())),
                ),
              ]),
              // ===== 数据 =====
              _section(context, theme, '数据', Icons.folder_outlined, [
                _exportTile(context, theme),
                _importTile(context, theme),
                _dataMgmtTile(context, theme),
              ]),
              // ===== 关于 =====
              _section(context, theme, '关于', Icons.info_outline, [
                ListTile(
                  leading: _icon(Icons.info_outline, theme),
                  title: const Text('关于小账本'),
                  subtitle: Text('版本 1.3.0', style: _sub(theme)),
                  shape: _shape(),
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('关于小账本'),
                      content: const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('版本 1.3.0', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),
                          Text('支持收支记录、预算管理、周期账单。\n多格式导入导出，轻松迁移数据。\n自定义背景，智能备注建议。'),
                          SizedBox(height: 8),
                          Text('数据完全保存在您的设备上，无需联网。', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 通用组件 ====================
  Widget _section(BuildContext context, ThemeData theme, String title, IconData icon, List<Widget> children) {
    // 使用ExpansionTile实现折叠，默认展开"自定义"，其余折叠
    final isCustom = title == '自定义';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: isCustom,
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: children,
      ),
    );
  }

  Widget _icon(IconData icon, ThemeData theme) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
    child: Icon(icon, size: 20, color: theme.colorScheme.primary),
  );

  ShapeBorder _shape() => RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  TextStyle? _sub(ThemeData t) => t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline);

  // ==================== 背景图片 ====================
  Widget _bgImageTile(BuildContext context, ThemeData theme) {
    final hasBg = appPrefs.bgImagePath != null;
    return ListTile(
      leading: _icon(Icons.wallpaper_outlined, theme),
      title: const Text('背景图片'),
      subtitle: Text(hasBg ? '已设置（点击更换）' : '点击选择图片', style: _sub(theme)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (hasBg)
          IconButton(
            icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
            onPressed: () async {
              await appPrefs.removeBackgroundImage();
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已恢复默认背景')));
            },
          ),
        const Icon(Icons.chevron_right, size: 20),
      ]),
      shape: _shape(),
      onTap: () async {
        await appPrefs.pickBackgroundImage();
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appPrefs.bgImagePath != null ? '背景已更新' : '未选择图片')));
      },
    );
  }

  // ==================== 背景透明度 ====================
  Widget _bgOpacityTile(BuildContext context, ThemeData theme) {
    final opacityPercent = (appPrefs.bgOpacity * 100).round();
    return ListTile(
      leading: _icon(Icons.opacity, theme),
      title: const Text('背景透明度'),
      subtitle: Text('$opacityPercent%', style: _sub(theme)),
      shape: _shape(),
      onTap: () {
        double val = appPrefs.bgOpacity;
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(builder: (ctx, sS) => AlertDialog(
            title: const Text('背景透明度'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('当前: ${(val * 100).round()}%'),
              Slider(value: val, min: 0.03, max: 0.40, divisions: 37,
                onChanged: (v) => sS(() => val = v)),
              Row(children: [
                const Text('淡'), Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: theme.colorScheme.primary), child: Slider(value: val, min: 0.03, max: 0.40, divisions: 37, onChanged: (v) => sS(() => val = v)))), const Text('浓'),
              ]),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              FilledButton(onPressed: () { appPrefs.setBgOpacity(val); Navigator.pop(ctx); }, child: const Text('确定')),
            ],
          )),
        );
      },
    );
  }

  // ==================== 默认日期范围 ====================
  Widget _defaultDateTile(BuildContext context, ThemeData theme) {
    const labels = ['近7天', '本周', '本月', '本年'];
    final current = labels[appPrefs.defaultDateRange];
    return ListTile(
      leading: _icon(Icons.date_range, theme),
      title: const Text('默认日期范围'),
      subtitle: Text('打开明细时默认显示 $current', style: _sub(theme)),
      shape: _shape(),
      onTap: () {
        int sel = appPrefs.defaultDateRange;
        showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(builder: (ctx, sS) => SimpleDialog(
            title: const Text('默认日期范围'),
            children: List.generate(4, (i) => SimpleDialogOption(
              onPressed: () { sel = i; sS(() {}); appPrefs.setDefaultDateRange(sel); Navigator.pop(ctx); },
              child: Row(children: [
                Text(labels[i], style: TextStyle(fontWeight: sel == i ? FontWeight.bold : FontWeight.normal, color: sel == i ? theme.colorScheme.primary : null)),
                if (sel == i) ...[const Spacer(), Icon(Icons.check, color: theme.colorScheme.primary, size: 18)],
              ]),
            )),
          )),
        );
      },
    );
  }

  // ==================== 备注历史数量 ====================
  Widget _noteHistoryTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: _icon(Icons.history_edu_outlined, theme),
      title: const Text('常用备注数量'),
      subtitle: Text('记账时显示最近 ${appPrefs.noteHistoryCount} 条', style: _sub(theme)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: appPrefs.noteHistoryCount > 0 ? () => appPrefs.setNoteHistoryCount(appPrefs.noteHistoryCount - 1) : null),
        Text('${appPrefs.noteHistoryCount}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        IconButton(icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: appPrefs.noteHistoryCount < 10 ? () => appPrefs.setNoteHistoryCount(appPrefs.noteHistoryCount + 1) : null),
        IconButton(icon: Icon(Icons.delete_sweep_outlined, size: 18, color: theme.colorScheme.outline),
          onPressed: () async { await NoteHistory.clear(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清空备注历史'))); }),
      ]),
      shape: _shape(),
    );
  }

  // ==================== 固化备注 ====================
  Widget _presetNotesTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: _icon(Icons.push_pin_outlined, theme),
      title: const Text('固化备注数量'),
      subtitle: Text('长按备注可快速选择 ${appPrefs.presetNoteCount} 个', style: _sub(theme)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: appPrefs.presetNoteCount > 0 ? () => appPrefs.setPresetNoteCount(appPrefs.presetNoteCount - 1) : null),
        Text('${appPrefs.presetNoteCount}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        IconButton(icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: appPrefs.presetNoteCount < 10 ? () => appPrefs.setPresetNoteCount(appPrefs.presetNoteCount + 1) : null),
      ]),
      shape: _shape(),
    );
  }

  // ==================== 预算 ====================
  Widget _budgetTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: _icon(Icons.savings_outlined, theme),
      title: const Text('月度预算'),
      subtitle: Text(appState.budget != null ? '${appState.budget!.categoryName}: ¥${appState.budget!.monthlyLimit.toStringAsFixed(0)}' : '未设置', style: _sub(theme)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      shape: _shape(),
      onTap: () => _showBudgetDialog(context, theme),
    );
  }

  void _showBudgetDialog(BuildContext context, ThemeData theme) {
    final cats = [const Category(name: '全部支出', icon: ''), ...expenseCategories.map((c) => Category(name: c.name, icon: c.icon))];
    String selCat = appState.budget?.categoryName ?? cats.first.name;
    final ctrl = TextEditingController(text: appState.budget?.monthlyLimit.toStringAsFixed(0) ?? '');
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, sS) => AlertDialog(
      title: const Text('月度预算'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          value: selCat,
          items: cats.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
          onChanged: (v) => sS(() => selCat = v!),
          decoration: const InputDecoration(labelText: '分类'),
        ),
        const SizedBox(height: 12),
        TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '月度预算 (¥)', prefixText: '¥ ')),
      ]),
      actions: [
        if (appState.budget != null) TextButton(onPressed: () { appState.clearBudget(); Navigator.pop(ctx); }, child: const Text('删除预算', style: TextStyle(color: Colors.red))),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () {
          final amt = double.tryParse(ctrl.text) ?? 0;
          if (amt > 0) { appState.setBudget(selCat, amt); Navigator.pop(ctx); }
        }, child: const Text('保存')),
      ],
    )));
  }

  // ==================== 周期 ====================
  Widget _recurringTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: _icon(Icons.repeat, theme),
      title: const Text('周期账单'),
      subtitle: Text('${appState.recurringTemplates.length} 个模板', style: _sub(theme)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      shape: _shape(),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringManageScreen())),
    );
  }

  // ==================== 导出 ====================
  Widget _exportTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: _icon(Icons.file_upload_outlined, theme),
      title: const Text('导出数据'),
      subtitle: Text('CSV 或 Excel 格式', style: _sub(theme)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      shape: _shape(),
      onTap: () => _showExportDialog(context, theme),
    );
  }

  void _showExportDialog(BuildContext context, ThemeData theme) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('导出数据'),
      content: const Text('选择导出格式：'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton.tonal(onPressed: () { Navigator.pop(ctx); _exportCSV(context, theme); }, child: const Text('导出 CSV')),
        const SizedBox(width: 8),
        FilledButton(onPressed: () { Navigator.pop(ctx); _exportExcel(context, theme); }, child: const Text('导出 Excel')),
      ],
    ));
  }

  Future<void> _exportCSV(BuildContext context, ThemeData theme) async {
    try {
      final list = appState.expenses;
      final rows = <List<String>>[['类型', '金额', '大分类', '小分类', '支付方式', '日期', '备注']];
      for (final e in list) {
        rows.add([e.type, e.amount.toStringAsFixed(2), e.majorCategory, e.minorCategory, e.paymentMethod, DateFormat('yyyy-MM-dd HH:mm').format(e.date), e.note ?? '']);
      }
      final csvStr = const ListToCsvConverter().convert(rows);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/小账本_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
      await file.writeAsString(csvStr);
      if (context.mounted) {
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }

  Future<void> _exportExcel(BuildContext context, ThemeData theme) async {
    try {
      final list = appState.expenses;
      final xls = excel.Excel.createExcel();
      final sheet = xls[xls.getDefaultSheet() ?? 'Sheet1'];
      sheet.appendRow(['类型', '金额', '大分类', '小分类', '支付方式', '日期', '备注'].map((h) => excel.TextCellValue(h)).toList());
      for (final e in list) {
        sheet.appendRow([e.type, e.amount, e.majorCategory, e.minorCategory, e.paymentMethod, DateFormat('yyyy-MM-dd HH:mm').format(e.date), e.note ?? ''].map((v) => v is double ? excel.DoubleCellValue(v) : excel.TextCellValue(v.toString())).toList());
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/小账本_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx');
      await file.writeAsBytes(xls.encode()!);
      if (context.mounted) {
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }

  // ==================== 导入 ====================
  Widget _importTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: _icon(Icons.file_download_outlined, theme),
      title: const Text('导入数据'),
      subtitle: Text('CSV 或 Excel', style: _sub(theme)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      shape: _shape(),
      onTap: () => _showImportDialog(context, theme),
    );
  }

  void _showImportDialog(BuildContext context, ThemeData theme) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('导入数据'),
      content: const Text('选择导入格式：'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton.tonal(onPressed: () { Navigator.pop(ctx); _importCSV(context, theme); }, child: const Text('导入 CSV')),
        const SizedBox(width: 8),
        FilledButton(onPressed: () { Navigator.pop(ctx); _importExcel(context, theme); }, child: const Text('导入 Excel')),
      ],
    ));
  }

  Future<void> _importCSV(BuildContext context, ThemeData theme) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.isEmpty) return;
      final content = await File(result.files.first.path!).readAsString();
      final rows = const CsvToListConverter().convert(content);
      if (rows.length < 2) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV 文件为空'))); return; }
      int imported = 0;
      for (var i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          if (row.length < 6) continue;
          final expense = Expense(
            type: row[0].toString().trim() == 'income' ? 'income' : 'expense',
            amount: double.parse(row[1].toString()),
            majorCategory: row[2].toString().trim(),
            minorCategory: row[3].toString().trim(),
            paymentMethod: row[4].toString().trim(),
            date: DateTime.parse(row[5].toString().trim()),
            note: row.length > 6 && row[6].toString().trim().isNotEmpty ? row[6].toString().trim() : null,
          );
          appState.addExpense(expense);
          imported++;
        } catch (_) {}
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功导入 $imported 条记录')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
  }

  Future<void> _importExcel(BuildContext context, ThemeData theme) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (result == null || result.files.isEmpty) return;
      final bytes = await File(result.files.first.path!).readAsBytes();
      final xls = excel.Excel.decodeBytes(bytes);
      final sheet = xls[xls.getDefaultSheet() ?? 'Sheet1'];
      int imported = 0;
      for (var i = 1; i < sheet.maxRows; i++) {
        try {
          final row = sheet.row(i);
          if (row.isEmpty) continue;
          final type = row[0]?.value.toString().trim() == 'income' ? 'income' : 'expense';
          final amount = double.parse(row[1]?.value.toString() ?? '0');
          final major = row[2]?.value.toString().trim() ?? '';
          final minor = row[3]?.value.toString().trim() ?? '';
          final payment = row[4]?.value.toString().trim() ?? '';
          final date = DateTime.parse(row[5]?.value.toString().trim() ?? DateTime.now().toIso8601String());
          final note = row.length > 6 && row[6]?.value.toString().trim().isNotEmpty == true ? row[6]!.value.toString().trim() : null;
          if (major.isEmpty) continue;
          appState.addExpense(Expense(type: type, amount: amount, majorCategory: major, minorCategory: minor, paymentMethod: payment, date: date, note: note));
          imported++;
        } catch (_) {}
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功导入 $imported 条记录')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
  }

  // ==================== 数据管理 ====================
  Widget _dataMgmtTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: _icon(Icons.delete_outline, theme),
      title: const Text('清空数据'),
      subtitle: Text('共 ${appState.expenses.length} 条记录', style: _sub(theme)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      shape: _shape(),
      onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text('清空数据'),
        content: const Text('确定要清空所有数据吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () { appState.clearAll(); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清空所有数据'))); },
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error), child: const Text('确认清空')),
        ],
      )),
    );
  }
}

// ==================== 占位页面引用（保持兼容） ====================
class CategoryManageScreen extends StatelessWidget {
  const CategoryManageScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('管理支出分类')), body: const Center(child: Text('分类管理')));
}

class RecurringManageScreen extends StatelessWidget {
  const RecurringManageScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('周期账单')), body: const Center(child: Text('周期账单')));
}
