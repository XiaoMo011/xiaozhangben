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
/// 所有自定义项统一在此管理
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: appPrefs,
        builder: (context, _) {
          return ListenableBuilder(
            listenable: appState,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 32),
                children: [
                  // ===== 外观 =====
                  _groupHeader(theme, '外观', Icons.palette_outlined),
                  _buildBgImageTile(context, theme),
                  _buildNoteHistoryTile(context, theme),
                  _buildPresetNotesTile(context, theme),
                  const SizedBox(height: 8),

                  // ===== 预算 & 周期 =====
                  _groupHeader(theme, '记账管理', Icons.account_balance_wallet_outlined),
                  _buildBudgetTile(context, theme),
                  _buildRecurringTile(context, theme),
                  const SizedBox(height: 8),

                  // ===== 分类 =====
                  _groupHeader(theme, '分类', Icons.category_outlined),
                  ListTile(
                    leading: _tileIcon(Icons.folder_outlined, theme),
                    title: const Text('管理支出分类'),
                    subtitle: Text('共 ${expenseCategories.length} 个大类 · ${incomeCategories.length} 个收入类',
                        style: _subStyle(theme)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    shape: _tileShape(),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CategoryManageScreen())),
                  ),
                  const SizedBox(height: 8),

                  // ===== 数据 =====
                  _groupHeader(theme, '数据', Icons.folder_outlined),
                  _buildExportTile(context, theme),
                  _buildImportTile(context, theme),
                  _buildDataMgmtTile(context, theme),
                  const SizedBox(height: 8),

                  // ===== 关于 =====
                  _groupHeader(theme, '关于', Icons.info_outline),
                  ListTile(
                    leading: _tileIcon(Icons.info_outline, theme),
                    title: const Text('关于小账本'),
                    subtitle: Text('版本 1.3.0', style: _subStyle(theme)),
                    shape: _tileShape(),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: '小账本',
                      applicationVersion: '1.3.0',
                      applicationLegalese: '数据完全保存在您的设备上',
                      children: [const Text('支持收支记录、预算管理、周期账单。\n多格式导入导出，轻松迁移数据。\n自定义背景，智能备注建议。')],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ---- 小组件 ----
  Widget _groupHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _tileIcon(IconData icon, ThemeData theme) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: theme.colorScheme.primary),
    );
  }

  ShapeBorder _tileShape() => RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

  TextStyle? _subStyle(ThemeData theme) => theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline);

  // ==================== 背景图片 ====================
  Widget _buildBgImageTile(BuildContext context, ThemeData theme) {
    final hasBg = appPrefs.bgImagePath != null;
    return ListTile(
      leading: _tileIcon(Icons.wallpaper_outlined, theme),
      title: const Text('背景图片'),
      subtitle: Text(hasBg ? '已设置自定义背景' : '使用默认背景',
          style: _subStyle(theme)),
      trailing: hasBg
          ? IconButton(
              icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
              onPressed: () async {
                await appPrefs.removeBackgroundImage();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已恢复默认背景')));
                }
              },
            )
          : const Icon(Icons.chevron_right, size: 20),
      shape: _tileShape(),
      onTap: hasBg ? null : () async {
        await appPrefs.pickBackgroundImage();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appPrefs.bgImagePath != null ? '背景已更新' : '未选择图片')));
        }
      },
    );
  }

  // ==================== 备注历史数量 ====================
  Widget _buildNoteHistoryTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: _tileIcon(Icons.history_edu_outlined, theme),
      title: const Text('常用备注数量'),
      subtitle: Text('记账时显示最近 ${appPrefs.noteHistoryCount} 条备注',
          style: _subStyle(theme)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: appPrefs.noteHistoryCount > 0
              ? () => appPrefs.setNoteHistoryCount(appPrefs.noteHistoryCount - 1)
              : null,
        ),
        Text('${appPrefs.noteHistoryCount}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: appPrefs.noteHistoryCount < 10
              ? () => appPrefs.setNoteHistoryCount(appPrefs.noteHistoryCount + 1)
              : null,
        ),
        // 清空历史
        IconButton(
          icon: Icon(Icons.delete_sweep_outlined, size: 18, color: theme.colorScheme.outline),
          onPressed: () async {
            await NoteHistory.clear();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已清空备注历史')));
            }
          },
        ),
      ]),
      shape: _tileShape(),
    );
  }

  // ==================== 固化备注 ====================
  Widget _buildPresetNotesTile(BuildContext context, ThemeData theme) {
    final presets = appPrefs.presetNotes.where((n) => n.isNotEmpty).toList();
    return ListTile(
      leading: _tileIcon(Icons.push_pin_outlined, theme),
      title: const Text('固化备注'),
      subtitle: Text(presets.isEmpty
          ? '设置常用备注词条，记账时一键填入'
          : '${presets.length} 条：${presets.take(3).join("、")}${presets.length > 3 ? "…" : ""}',
          style: _subStyle(theme),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('${appPrefs.presetNoteCount}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: () => _showPresetNoteEditor(context, theme),
        ),
      ]),
      shape: _tileShape(),
      onTap: () => _showPresetNoteEditor(context, theme),
    );
  }

  void _showPresetNoteEditor(BuildContext context, ThemeData theme) {
    final controllers = <TextEditingController>[];
    for (var i = 0; i < appPrefs.presetNoteCount; i++) {
      final note = i < appPrefs.presetNotes.length ? appPrefs.presetNotes[i] : '';
      controllers.add(TextEditingController(text: note));
    }
    int tempCount = appPrefs.presetNoteCount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(children: [
                Icon(Icons.push_pin, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('固化备注', style: theme.textTheme.titleLarge),
                const Spacer(),
                // 数量调节
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 22),
                  onPressed: tempCount > 0
                      ? () {
                          setS(() {
                            tempCount--;
                            if (controllers.length > tempCount) {
                              controllers.removeLast();
                            }
                          });
                        }
                      : null,
                ),
                Text('$tempCount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  onPressed: tempCount < 10
                      ? () {
                          setS(() {
                            tempCount++;
                            controllers.add(TextEditingController());
                          });
                        }
                      : null,
                ),
              ]),
              const SizedBox(height: 4),
              Text('设置常用备注词条，记账时固定显示在输入框下方，点击即可填入',
                  style: _subStyle(theme)),
              const SizedBox(height: 16),

              // 编辑区域
              ...List.generate(tempCount, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controllers[i],
                        decoration: InputDecoration(
                          hintText: '输入固化备注词条...',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerLow,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ]),
                );
              }),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    // 保存数量
                    await appPrefs.setPresetNoteCount(tempCount);
                    // 逐条保存备注
                    for (var i = 0; i < controllers.length; i++) {
                      await appPrefs.updatePresetNote(i, controllers[i].text);
                    }
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('固化备注已更新'), duration: Duration(seconds: 1)));
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('保存', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 预算 ====================
  Widget _buildBudgetTile(BuildContext context, ThemeData theme) {
    final fmt = (double v) => NumberFormat.currency(symbol: '¥', decimalDigits: 0).format(v);
    return FutureBuilder<Budget?>(
      future: appState.getCurrentMonthBudget(),
      builder: (context, snap) {
        final budget = snap.data;
        final spent = appState.thisMonthExpenseTotal;
        final hasBudget = budget != null && budget.amount > 0;
        final ratio = hasBudget ? spent / budget!.amount : 0.0;
        final isOver = ratio > 1;

        return ListTile(
          leading: _tileIcon(isOver ? Icons.warning_amber_outlined : Icons.savings_outlined, theme),
          title: Text(hasBudget ? '月度预算 ${fmt(budget!.amount)}' : '设置月度预算'),
          subtitle: hasBudget
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0), minHeight: 5,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: isOver ? theme.colorScheme.error
                          : ratio > 0.8 ? Colors.orange : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('已用 ${fmt(spent)} · ${(ratio * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 11,
                          color: isOver ? theme.colorScheme.error : theme.colorScheme.outline)),
                ])
              : Text('本月已花 ${fmt(spent)}', style: _subStyle(theme)),
          trailing: const Icon(Icons.chevron_right, size: 20),
          shape: _tileShape(),
          onTap: () => _showBudgetDialog(context, theme, budget),
        );
      },
    );
  }

  void _showBudgetDialog(BuildContext context, ThemeData theme, Budget? current) {
    final ctrl = TextEditingController(text: current != null ? current.amount.toStringAsFixed(0) : '');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('设置月度预算'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true,
        decoration: const InputDecoration(prefixText: '¥ ', labelText: '预算金额', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () {
          final a = double.tryParse(ctrl.text);
          if (a != null && a > 0) { appState.setCurrentMonthBudget(a); Navigator.pop(ctx); }
        }, child: const Text('保存')),
      ],
    ));
  }

  // ==================== 周期账单 ====================
  Widget _buildRecurringTile(BuildContext context, ThemeData theme) {
    final cnt = appState.templates.where((t) => t.isActive).length;
    return ListTile(
      leading: _tileIcon(Icons.repeat_outlined, theme),
      title: const Text('管理周期账单'),
      subtitle: Text(appState.templates.isEmpty ? '暂无模板' : '$cnt 个启用的模板',
          style: _subStyle(theme)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      shape: _tileShape(),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringManageScreen())),
    );
  }

  // ==================== 导出 ====================
  Widget _buildExportTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: _tileIcon(Icons.file_upload_outlined, theme),
      title: const Text('导出数据'),
      subtitle: Text('XLSX · CSV · JSON', style: _subStyle(theme)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      shape: _tileShape(),
      onTap: () => _showExportSheet(context, theme),
    );
  }

  void _showExportSheet(BuildContext context, ThemeData theme) {
    if (appState.expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('暂无数据可导出')));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('选择导出格式', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('共 ${appState.expenses.length} 条记录', style: _subStyle(theme)),
            const SizedBox(height: 16),
            _fmtOption(ctx, Icons.table_chart_outlined, 'Excel (.xlsx)', '带格式美化，适合打印或电脑查看', Colors.green,
                () { Navigator.pop(ctx); _exportXlsx(context); }),
            const SizedBox(height: 8),
            _fmtOption(ctx, Icons.description_outlined, 'CSV 通用格式 (.csv)', '兼容随手记、挖财、支付宝等软件导入', Colors.blue,
                () { Navigator.pop(ctx); _exportCsv(context); }),
            const SizedBox(height: 8),
            _fmtOption(ctx, Icons.code, 'JSON 完整备份 (.json)', '包含全部账单+预算+周期模板，可完整还原', Colors.orange,
                () { Navigator.pop(ctx); _exportJson(context); }),
          ]),
        ),
      ),
    );
  }

  Widget _fmtOption(BuildContext ctx, IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(ctx).textTheme.titleSmall),
            const SizedBox(height: 2), Text(sub, style: _subStyle(Theme.of(ctx))),
          ])),
          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  // --- 导出实现 ---
  Future<void> _exportXlsx(BuildContext context) async {
    try { _loading(context, '生成 Excel...');
      final ex = excel.Excel.createExcel(); final s = ex['小账本'];
      final hdr = excel.CellStyle(bold: true, fontSize: 12,
          horizontalAlign: excel.HorizontalAlign.Center, verticalAlign: excel.VerticalAlign.Center,
          topBorder: excel.Border(borderStyle: excel.BorderStyle.Thin), bottomBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
          leftBorder: excel.Border(borderStyle: excel.BorderStyle.Thin), rightBorder: excel.Border(borderStyle: excel.BorderStyle.Thin));
      final cs = excel.CellStyle(fontSize: 11, horizontalAlign: excel.HorizontalAlign.Center, verticalAlign: excel.VerticalAlign.Center,
          topBorder: excel.Border(borderStyle: excel.BorderStyle.Thin), bottomBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
          leftBorder: excel.Border(borderStyle: excel.BorderStyle.Thin), rightBorder: excel.Border(borderStyle: excel.BorderStyle.Thin));
      final amt = excel.CellStyle(fontSize: 11, horizontalAlign: excel.HorizontalAlign.Right, verticalAlign: excel.VerticalAlign.Center,
          topBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
          bottomBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
          leftBorder: excel.Border(borderStyle: excel.BorderStyle.Thin), rightBorder: excel.Border(borderStyle: excel.BorderStyle.Thin));
      const hh = ['序号', '类型', '日期', '大类', '小类', '支付方式', '金额(¥)', '备注'];
      for (var i = 0; i < hh.length; i++) { final c = s.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)); c.value = excel.TextCellValue(hh[i]); c.cellStyle = hdr; }
      final exps = appState.expenses;
      for (var i = 0; i < exps.length; i++) { final e = exps[i]; final r = i + 1;
        void w(int col, dynamic v, excel.CellStyle st) { final c = s.cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: r)); if (v is int) c.value = excel.IntCellValue(v); else if (v is double) c.value = excel.DoubleCellValue(v); else c.value = excel.TextCellValue(v.toString()); c.cellStyle = st; }
        w(0, i + 1, cs); w(1, e.type == 'expense' ? '支出' : '收入', cs); w(2, DateFormat('yyyy-MM-dd HH:mm').format(e.date), cs); w(3, e.majorCategory, cs); w(4, e.minorCategory, cs); w(5, e.paymentMethod, cs); w(6, e.amount, amt); w(7, e.note ?? '', cs);
      }
      s.setColumnWidth(0, 6); s.setColumnWidth(1, 8); s.setColumnWidth(2, 20); s.setColumnWidth(3, 14); s.setColumnWidth(4, 14); s.setColumnWidth(5, 10); s.setColumnWidth(6, 14); s.setColumnWidth(7, 28);
      final bytes = ex.encode();
      if (bytes == null) { _hideLoading(context); _err(context, 'Excel生成失败'); return; }
      final fp = await _tmp('xlsx'); await File(fp).writeAsBytes(bytes);
      _hideLoading(context); await Share.shareXFiles([XFile(fp)], subject: '小账本 - Excel');
    } catch (e) { _hideLoading(context); _err(context, '导出失败：$e'); }
  }

  Future<void> _exportCsv(BuildContext context) async {
    try { _loading(context, '生成 CSV...');
      const hh = ['日期', '类型', '金额', '一级分类', '二级分类', '支付方式', '备注'];
      final rows = <List<String>>[hh.toList()];
      for (final e in appState.expenses) rows.add([DateFormat('yyyy-MM-dd HH:mm').format(e.date), e.type == 'expense' ? '支出' : '收入', e.amount.toStringAsFixed(2), e.majorCategory, e.minorCategory, e.paymentMethod, e.note ?? '']);
      final csv = '﻿${const ListToCsvConverter().convert(rows)}';
      final fp = await _tmp('csv'); await File(fp).writeAsString(csv, encoding: utf8);
      _hideLoading(context); await Share.shareXFiles([XFile(fp)], subject: '小账本 - CSV');
    } catch (e) { _hideLoading(context); _err(context, '导出失败：$e'); }
  }

  Future<void> _exportJson(BuildContext context) async {
    try { _loading(context, '生成 JSON...');
      final now = DateTime.now().toIso8601String();
      final map = {'appName': '小账本', 'version': '1.3.0', 'exportedAt': now, 'data': {
        'transactions': appState.expenses.map((e) => {'type': e.type, 'amount': e.amount, 'date': e.date.toIso8601String(), 'majorCategory': e.majorCategory, 'minorCategory': e.minorCategory, 'paymentMethod': e.paymentMethod, 'note': e.note ?? '', 'createdAt': e.createdAt ?? now}).toList(),
        'recurringTemplates': appState.templates.map((t) => t.toMap()).toList(),
      }};
      final fp = await _tmp('json'); await File(fp).writeAsString(const JsonEncoder.withIndent('  ').convert(map), encoding: utf8);
      _hideLoading(context); await Share.shareXFiles([XFile(fp)], subject: '小账本 - JSON备份');
    } catch (e) { _hideLoading(context); _err(context, '导出失败：$e'); }
  }

  // ==================== 导入 ====================
  Widget _buildImportTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: _tileIcon(Icons.file_download_outlined, theme),
      title: const Text('导入数据'),
      subtitle: Text('从 JSON 备份还原', style: _subStyle(theme)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      shape: _tileShape(),
      onTap: () => _importJson(context, theme),
    );
  }

  Future<void> _importJson(BuildContext context, ThemeData theme) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.isEmpty) return;
      final content = await File(result.files.single.path!).readAsString(encoding: utf8);
      Map<String, dynamic> jsonMap;
      try { jsonMap = jsonDecode(content) as Map<String, dynamic>; } catch (_) { _err(context, '文件格式无效'); return; }
      final data = jsonMap['data'] as Map<String, dynamic>?;
      final txns = data?['transactions'] as List<dynamic>?;
      if (txns == null || txns.isEmpty) { _err(context, '未找到账单数据'); return; }
      final parsed = <Expense>[]; int errs = 0;
      for (final item in txns) { try { final m = item as Map<String, dynamic>; parsed.add(Expense(type: m['type'] as String? ?? 'expense', amount: (m['amount'] as num).toDouble(), date: DateTime.parse(m['date'] as String), majorCategory: m['majorCategory'] as String? ?? '其他杂项', minorCategory: m['minorCategory'] as String? ?? '其他', paymentMethod: m['paymentMethod'] as String? ?? '现金', note: m['note'] as String?)); } catch (_) { errs++; } }
      if (parsed.isEmpty) { _err(context, '未能解析有效记录'); return; }
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认导入'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('即将导入 ${parsed.length} 条记录（当前 ${appState.expenses.length} 条）', style: theme.textTheme.bodyMedium),
          if (errs > 0) Text('跳过 $errs 条无效数据', style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700), const SizedBox(width: 8), const Expanded(child: Text('新数据追加到现有记录，不会覆盖', style: TextStyle(fontSize: 12)))])),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('导入 ${parsed.length} 条'))],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));
      if (confirmed != true || !context.mounted) return;
      _loading(context, '导入中...');
      await appState.importExpenses(parsed);
      final tpls = data?['recurringTemplates'] as List<dynamic>?;
      if (tpls != null) { for (final t in tpls) { try { await appState.addTemplate(RecurringTemplate.fromMap(t as Map<String, dynamic>)); } catch (_) {} } }
      _hideLoading(context);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功导入 ${parsed.length} 条'), backgroundColor: Colors.green));
    } catch (e) { _hideLoading(context); _err(context, '导入失败：$e'); }
  }

  // ==================== 数据库维护 ====================
  Widget _buildDataMgmtTile(BuildContext context, ThemeData theme) {
    return FutureBuilder<String>(
      future: appState.getDatabaseSizeReadable(),
      builder: (context, snap) {
        return ExpansionTile(
          leading: _tileIcon(Icons.storage_outlined, theme),
          title: const Text('数据库维护'),
          subtitle: Text('大小: ${snap.data ?? "..."}', style: _subStyle(theme)),
          shape: _tileShape(),
          collapsedShape: _tileShape(),
          children: [
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined, size: 20),
              title: const Text('清理旧数据'),
              subtitle: Text('保留最近 1,000 条', style: _subStyle(theme)),
              onTap: () async {
                final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('确认清理'),
                  content: Text('保留最近 1,000 条，删除更早数据。\n当前 ${appState.expenses.length} 条。此操作不可撤销。'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.orange), child: const Text('确认清理'))],
                ));
                if (ok == true && context.mounted) {
                  final d = await appState.cleanOldData();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(d > 0 ? '已清理 $d 条' : '无需清理')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.compress, size: 20),
              title: const Text('压缩数据库'),
              subtitle: Text('回收空间', style: _subStyle(theme)),
              onTap: () async {
                await appState.vacuum();
                if (context.mounted) { final s = await appState.getDatabaseSizeReadable(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('压缩完成: $s'))); }
              },
            ),
          ],
        );
      },
    );
  }

  // ---- 工具 ----
  void _loading(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Row(children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 12), Text(m)]), duration: const Duration(minutes: 1)));
  void _hideLoading(BuildContext c) => ScaffoldMessenger.of(c).hideCurrentSnackBar();
  void _err(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  Future<String> _tmp(String ext) async { final d = await getTemporaryDirectory(); return '${d.path}/小账本_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.$ext'; }
}

// ==================== 分类管理 ====================
class CategoryManageScreen extends StatelessWidget {
  const CategoryManageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('管理支出分类'), backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      body: ListView.builder(padding: const EdgeInsets.all(16), itemCount: expenseCategories.length, itemBuilder: (_, i) {
        final m = expenseCategories[i];
        return Card(margin: const EdgeInsets.only(bottom: 8), child: ExpansionTile(
          leading: Icon(Icons.folder_outlined, color: theme.colorScheme.primary),
          title: Text(m.name, style: theme.textTheme.titleMedium),
          subtitle: Text('${m.subCategories.length}个子分类'),
          children: m.subCategories.map((s) => ListTile(title: Text(s.name), leading: const Icon(Icons.label_outline, size: 20), dense: true)).toList(),
        ));
      }),
    );
  }
}

// ==================== 周期账单管理 ====================
class RecurringManageScreen extends StatefulWidget {
  const RecurringManageScreen({super.key});
  @override
  State<RecurringManageScreen> createState() => _RecurringManageScreenState();
}

class _RecurringManageScreenState extends State<RecurringManageScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('周期账单'), backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      floatingActionButton: FloatingActionButton.small(onPressed: () => _edit(context, null), child: const Icon(Icons.add)),
      body: ListenableBuilder(listenable: appState, builder: (_, __) {
        final ts = appState.templates;
        if (ts.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.repeat, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16),
          Text('还没有周期账单', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 8), Text('房租、工资等固定收支可以设为周期账单', style: _sub(theme)),
        ]));
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: ts.length, itemBuilder: (_, i) {
          final t = ts[i];
          return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
            leading: CircleAvatar(radius: 20, backgroundColor: (t.type == 'expense' ? theme.colorScheme.error : Colors.green).withOpacity(0.1),
                child: Icon(t.type == 'expense' ? Icons.trending_down : Icons.trending_up, color: t.type == 'expense' ? theme.colorScheme.error : Colors.green, size: 18)),
            title: Text(t.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('¥${t.amount.toStringAsFixed(2)} · ${t.majorCategory}/${t.minorCategory} · ${t.cycleDescription}', style: _sub(theme)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (!t.isActive) Icon(Icons.pause_circle, color: Colors.grey.shade400, size: 20),
              PopupMenuButton<String>(onSelected: (v) {
                if (v == 'edit') { _edit(context, t); }
                else if (v == 'toggle') { final u = RecurringTemplate(id: t.id, name: t.name, type: t.type, amount: t.amount, majorCategory: t.majorCategory, minorCategory: t.minorCategory, paymentMethod: t.paymentMethod, cycle: t.cycle, cycleDay: t.cycleDay, note: t.note, isActive: !t.isActive, lastGenerated: t.lastGenerated, createdAt: t.createdAt); final idx = appState.templates.indexOf(t); if (idx >= 0) appState.updateTemplate(idx, u); }
                else if (v == 'delete') { _confirmDelete(i, t, theme); }
              }, itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('编辑')),
                PopupMenuItem(value: 'toggle', child: Text(t.isActive ? '暂停' : '启用')),
                const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
              ]),
            ]),
          ));
        });
      }),
    );
  }

  TextStyle? _sub(ThemeData t) => t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline);

  Future<void> _confirmDelete(int i, RecurringTemplate t, ThemeData theme) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 24), const SizedBox(width: 8), const Text('确认删除模板')]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('确定删除此周期账单模板？已生成的账单不受影响。', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _dr(theme, '名称', t.name), const SizedBox(height: 4),
          _dr(theme, '金额', '¥${t.amount.toStringAsFixed(2)} ${t.type == "expense" ? "支出" : "收入"}'), const SizedBox(height: 4),
          _dr(theme, '周期', t.cycleDescription),
        ])),
        const SizedBox(height: 8), Text('此操作不可撤销', style: TextStyle(fontSize: 12, color: theme.colorScheme.error)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error), child: const Text('确认删除'))],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ));
    if (ok == true && mounted) { appState.deleteTemplate(i); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除'))); }
  }

  Widget _dr(ThemeData t, String l, String v) => Row(children: [SizedBox(width: 36, child: Text(l, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline))), Expanded(child: Text(v, style: t.textTheme.bodyMedium))]);

  void _edit(BuildContext ctx, RecurringTemplate? existing) {
    final nc = TextEditingController(text: existing?.name ?? '');
    final ac = TextEditingController(text: existing?.amount.toStringAsFixed(2) ?? '');
    final mc = TextEditingController(text: existing?.note ?? '');
    String ty = existing?.type ?? 'expense';
    String mj = existing?.majorCategory ?? expenseCategories.first.name;
    String mn = existing?.minorCategory ?? expenseCategories.first.subCategories.first.name;
    String pm = existing?.paymentMethod ?? '微信';
    String cy = existing?.cycle ?? 'monthly';
    int cd = existing?.cycleDay ?? 1;

    Navigator.push(ctx, MaterialPageRoute(builder: (c) => Scaffold(
      appBar: AppBar(title: Text(existing != null ? '编辑周期账单' : '新增周期账单'), backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: nc, decoration: const InputDecoration(labelText: '模板名称', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
        const SizedBox(height: 14),
        StatefulBuilder(builder: (c, sS) => Row(children: [
          Expanded(child: ChoiceChip(label: const Text('支出'), selected: ty == 'expense', onSelected: (_) => sS(() => ty = 'expense'))),
          const SizedBox(width: 8), Expanded(child: ChoiceChip(label: const Text('收入'), selected: ty == 'income', onSelected: (_) => sS(() => ty = 'income'))),
        ])),
        const SizedBox(height: 14),
        TextField(controller: ac, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '金额', prefixText: '¥ ', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
        const SizedBox(height: 14),
        StatefulBuilder(builder: (c, sS) { final cats = getCategoriesForType(ty);
          if (!cats.any((x) => x.name == mj)) mj = cats.first.name;
          if (!getSubCategories(mj).any((x) => x.name == mn)) mn = getSubCategories(mj).first.name;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('分类', style: Theme.of(c).textTheme.titleSmall), const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: cats.map((x) => FilterChip(label: Text(x.name, style: const TextStyle(fontSize: 12)), selected: mj == x.name, onSelected: (_) => sS(() { mj = x.name; mn = x.subCategories.first.name; }))).toList()),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: getSubCategories(mj).map((x) => ChoiceChip(label: Text(x.name, style: const TextStyle(fontSize: 12)), selected: mn == x.name, onSelected: (_) => sS(() => mn = x.name))).toList()),
          ]); }),
        const SizedBox(height: 14),
        StatefulBuilder(builder: (c, sS) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('支付方式', style: Theme.of(c).textTheme.titleSmall), const SizedBox(height: 8),
          Wrap(spacing: 6, children: paymentMethods.map((p) => ChoiceChip(label: Text(p, style: const TextStyle(fontSize: 12)), selected: pm == p, onSelected: (_) => sS(() => pm = p))).toList()),
        ])),
        const SizedBox(height: 14),
        StatefulBuilder(builder: (c, sS) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('周期', style: Theme.of(c).textTheme.titleSmall), const SizedBox(height: 8),
          Wrap(spacing: 6, children: [
            ChoiceChip(label: const Text('每天'), selected: cy == 'daily', onSelected: (_) => sS(() => cy = 'daily')),
            ChoiceChip(label: const Text('每周'), selected: cy == 'weekly', onSelected: (_) => sS(() => cy = 'weekly')),
            ChoiceChip(label: const Text('每月'), selected: cy == 'monthly', onSelected: (_) => sS(() => cy = 'monthly')),
            ChoiceChip(label: const Text('每年'), selected: cy == 'yearly', onSelected: (_) => sS(() => cy = 'yearly')),
          ]),
          const SizedBox(height: 8),
          if (cy == 'weekly') DropdownButtonFormField<int>(value: cd.clamp(1, 7), decoration: const InputDecoration(labelText: '星期几', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 1, child: Text('星期一')), DropdownMenuItem(value: 2, child: Text('星期二')), DropdownMenuItem(value: 3, child: Text('星期三')), DropdownMenuItem(value: 4, child: Text('星期四')), DropdownMenuItem(value: 5, child: Text('星期五')), DropdownMenuItem(value: 6, child: Text('星期六')), DropdownMenuItem(value: 7, child: Text('星期日'))], onChanged: (v) => sS(() => cd = v ?? 1)),
          if (cy == 'monthly') DropdownButtonFormField<int>(value: cd.clamp(1, 28), decoration: const InputDecoration(labelText: '每月几号', border: OutlineInputBorder()), items: List.generate(28, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}号'))), onChanged: (v) => sS(() => cd = v ?? 1)),
        ])),
        const SizedBox(height: 14),
        TextField(controller: mc, decoration: const InputDecoration(labelText: '备注（选填）', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () {
          final name = nc.text.trim(); final amt = double.tryParse(ac.text);
          if (name.isEmpty || amt == null || amt <= 0) { ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('请填写名称和金额'))); return; }
          final tpl = RecurringTemplate(id: existing?.id, name: name, type: ty, amount: amt, majorCategory: mj, minorCategory: mn, paymentMethod: pm, cycle: cy, cycleDay: cd, note: mc.text.trim().isEmpty ? null : mc.text.trim(), isActive: existing?.isActive ?? true, lastGenerated: existing?.lastGenerated, createdAt: existing?.createdAt);
          if (existing != null) { final idx = appState.templates.indexOf(existing); if (idx >= 0) appState.updateTemplate(idx, tpl); } else { appState.addTemplate(tpl); }
          Navigator.pop(c);
        }, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('保存', style: TextStyle(fontSize: 16)))),
      ])),
    )));
  }
}
