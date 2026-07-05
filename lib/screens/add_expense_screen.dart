import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/categories.dart';
import '../data/preferences.dart';
import '../data/note_history.dart';
import '../models/expense.dart';

/// 记一笔 —— 收支记录页面，含智能备注建议
class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;
  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _type = 'expense';
  String _amountText = '';
  double _amount = 0;
  String _selectedMajor = '';
  String _selectedMinor = '';
  String _selectedPayment = '微信';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  bool _showKeypad = true;

  // 备注建议
  List<String> _noteSuggestions = [];
  bool _showSuggestions = false;

  static const List<List<String>> _keypadKeys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  List<MajorCategory> get _cats => getCategoriesForType(_type);

  @override
  void initState() {
    super.initState();
    final cats = _cats;
    _selectedMajor = cats.first.name;
    _selectedMinor = cats.first.subCategories.first.name;

    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _type = e.type;
      _amount = e.amount;
      _amountText = _formatAmount(e.amount);
      _selectedMajor = e.majorCategory;
      _selectedMinor = e.minorCategory;
      _selectedPayment = e.paymentMethod;
      _selectedDate = e.date;
      _noteController.text = e.note ?? '';
    }

    _noteFocusNode.addListener(() {
      setState(() {
        _showKeypad = !_noteFocusNode.hasFocus;
        _showSuggestions = _noteFocusNode.hasFocus && _noteController.text.isEmpty;
      });
      if (_noteFocusNode.hasFocus) _loadSuggestions();
    });

    // 初始加载建议
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final suggestions = await NoteHistory.getRecent(count: appPrefs.noteHistoryCount);
    if (mounted) setState(() => _noteSuggestions = suggestions);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  String _formatAmount(double v) {
    if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountText.isNotEmpty) _amountText = _amountText.substring(0, _amountText.length - 1);
      } else if (key == '.') {
        if (!_amountText.contains('.')) _amountText += _amountText.isEmpty ? '0.' : '.';
      } else {
        if (_amountText.contains('.')) {
          final p = _amountText.split('.');
          if (p.length == 2 && p[1].length >= 2) return;
        } else if (_amountText.length >= 9) return;
        _amountText = _amountText == '0' && key != '.' ? key : _amountText + key;
      }
      _amount = double.tryParse(_amountText) ?? 0;
    });
  }

  void _saveExpense() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入金额'), duration: Duration(seconds: 2)));
      return;
    }

    final note = _noteController.text.trim();
    final expense = Expense(
      id: widget.existingExpense?.id,
      type: _type, amount: _amount, date: _selectedDate,
      majorCategory: _selectedMajor, minorCategory: _selectedMinor,
      paymentMethod: _selectedPayment,
      note: note.isEmpty ? null : note,
    );

    // 保存备注到历史
    if (note.isNotEmpty) await NoteHistory.save(note);

    if (mounted) Navigator.pop(context, {'expense': expense});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingExpense != null;
    final subs = getSubCategories(_selectedMajor);
    final amountColor = _type == 'expense' ? theme.colorScheme.error : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑记录' : '记一笔'),
        surfaceTintColor: Colors.transparent,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilledButton.tonal(
              onPressed: _saveExpense,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('保存', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          _buildTypeToggle(theme),
          _buildAmountDisplay(theme, amountColor),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildCategorySection(theme, subs),
              const SizedBox(height: 18),
              _buildPaymentSection(theme),
              const SizedBox(height: 18),
              _buildDateTimePicker(theme),
              const SizedBox(height: 18),
              _buildNoteSection(theme),
            ]),
          )),
          if (_showKeypad) _buildKeypad(theme),
        ]),
      ),
    );
  }

  // ---- 收支切换 ----
  Widget _buildTypeToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(child: GestureDetector(
          onTap: () => setState(() {
            _type = 'expense';
            _selectedMajor = _cats.first.name;
            _selectedMinor = _cats.first.subCategories.first.name;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _type == 'expense' ? theme.colorScheme.error.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _type == 'expense' ? theme.colorScheme.error.withOpacity(0.4) : Colors.grey.shade200,
                width: _type == 'expense' ? 1.5 : 1,
              ),
            ),
            child: Column(children: [
              Icon(Icons.trending_down, color: _type == 'expense' ? theme.colorScheme.error : Colors.grey, size: 24),
              const SizedBox(height: 4),
              Text('支出', style: TextStyle(fontSize: 15, fontWeight: _type == 'expense' ? FontWeight.w700 : FontWeight.w500,
                  color: _type == 'expense' ? theme.colorScheme.error : Colors.grey)),
            ]),
          ),
        )),
        const SizedBox(width: 12),
        Expanded(child: GestureDetector(
          onTap: () => setState(() {
            _type = 'income';
            final inc = getCategoriesForType('income');
            _selectedMajor = inc.first.name;
            _selectedMinor = inc.first.subCategories.first.name;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _type == 'income' ? Colors.green.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _type == 'income' ? Colors.green.withOpacity(0.4) : Colors.grey.shade200,
                width: _type == 'income' ? 1.5 : 1,
              ),
            ),
            child: Column(children: [
              Icon(Icons.trending_up, color: _type == 'income' ? Colors.green : Colors.grey, size: 24),
              const SizedBox(height: 4),
              Text('收入', style: TextStyle(fontSize: 15, fontWeight: _type == 'income' ? FontWeight.w700 : FontWeight.w500,
                  color: _type == 'income' ? Colors.green : Colors.grey)),
            ]),
          ),
        )),
      ]),
    );
  }

  // ---- 金额显示 ----
  Widget _buildAmountDisplay(ThemeData theme, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(_type == 'expense' ? '-' : '+', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 2),
        Text('¥', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(_amountText.isEmpty ? '0' : _amountText,
              style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: color, height: 1.1)),
        ),
      ]),
    );
  }

  // ---- 分类 ----
  Widget _buildCategorySection(ThemeData theme, List<Category> subs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel(theme, '分类'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 6, children: _cats.map((m) {
        final sel = m.name == _selectedMajor;
        return FilterChip(
          label: Text(m.name, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
          selected: sel,
          selectedColor: theme.colorScheme.primaryContainer,
          checkmarkColor: theme.colorScheme.primary,
          side: BorderSide(color: sel ? Colors.transparent : Colors.grey.shade200),
          onSelected: (_) => setState(() { _selectedMajor = m.name; _selectedMinor = m.subCategories.first.name; }),
        );
      }).toList()),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 6, children: subs.map((s) {
        final sel = s.name == _selectedMinor;
        return ChoiceChip(
          label: Text(s.name, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
          selected: sel,
          selectedColor: theme.colorScheme.secondaryContainer,
          side: BorderSide(color: sel ? Colors.transparent : Colors.grey.shade200),
          onSelected: (_) => setState(() => _selectedMinor = s.name),
        );
      }).toList()),
    ]);
  }

  // ---- 支付方式 ----
  Widget _buildPaymentSection(ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel(theme, '支付方式'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 6, children: paymentMethods.map((p) {
        final sel = p == _selectedPayment;
        return ChoiceChip(
          label: Text(p, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
          selected: sel,
          selectedColor: theme.colorScheme.secondaryContainer,
          side: BorderSide(color: sel ? Colors.transparent : Colors.grey.shade200),
          onSelected: (_) => setState(() => _selectedPayment = p),
        );
      }).toList()),
    ]);
  }

  // ---- 日期时间 ----
  Widget _buildDateTimePicker(ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel(theme, '日期时间'),
      const SizedBox(height: 10),
      InkWell(
        onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _selectedDate,
              firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
          if (d != null && mounted) {
            final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedDate));
            if (t != null) setState(() => _selectedDate = DateTime(d.year, d.month, d.day, t.hour, t.minute));
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(DateFormat('yyyy年MM月dd日 HH:mm').format(_selectedDate), style: theme.textTheme.bodyLarge),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ]),
        ),
      ),
    ]);
  }

  // ---- 备注 + 建议区 ----
  Widget _buildNoteSection(ThemeData theme) {
    final presets = appPrefs.presetNotes.where((n) => n.isNotEmpty).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel(theme, '备注'),
      const SizedBox(height: 10),
      GestureDetector(
        onLongPress: presets.isNotEmpty
            ? () => _showPresetPicker(context, presets, theme)
            : null,
        child: TextField(
          controller: _noteController,
          focusNode: _noteFocusNode,
          keyboardType: TextInputType.text,
          maxLength: 200,
          onChanged: (_) => setState(() => _showSuggestions = false),
          decoration: InputDecoration(
            hintText: presets.isNotEmpty ? '添加备注...（长按选固化备注）' : '添加备注...',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: TextStyle(color: Colors.grey.shade400),
          ),
        ),
      ),
      // ---- 固化备注（始终显示） ----
      if (presets.isNotEmpty) ...[
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.push_pin, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text('固化备注', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: presets.map((n) => ActionChip(
          label: Text(n, style: const TextStyle(fontSize: 13)),
          avatar: Icon(Icons.push_pin, size: 14, color: theme.colorScheme.primary.withOpacity(0.5)),
          onPressed: () {
            _noteController.text = n;
            _noteFocusNode.unfocus();
          },
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
          backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.15),
        )).toList()),
      ],
      // ---- 历史备注（聚焦时显示） ----
      if (_showSuggestions && _noteSuggestions.isNotEmpty) ...[
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.history, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text('常用备注', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const Spacer(),
          GestureDetector(
            onTap: () async { await NoteHistory.clear(); _loadSuggestions(); },
            child: Text('清空', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
          ),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: _noteSuggestions
            .where((n) => !presets.contains(n)) // 避免与固化备注重复
            .map((n) => ActionChip(
          label: Text(n, style: const TextStyle(fontSize: 13)),
          onPressed: () {
            _noteController.text = n;
            setState(() => _showSuggestions = false);
            _noteFocusNode.unfocus();
          },
          side: BorderSide(color: Colors.grey.shade200),
          backgroundColor: theme.colorScheme.surface,
        )).toList()),
      ],
    ]);
  }

  /// 长按备注输入框时弹出固化备注选择器
  void _showPresetPicker(BuildContext context, List<String> presets, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.push_pin, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text('固化备注', style: theme.textTheme.titleLarge),
              ]),
              const SizedBox(height: 6),
              Text('点击直接填入备注', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(height: 16),
              ...presets.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _noteController.text = n;
                      Navigator.pop(ctx);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.push_pin, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(n, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                            textAlign: TextAlign.left),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                    ]),
                  ),
                ),
              )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Text(text, style: theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
      fontWeight: FontWeight.w600,
    ));
  }

  // ---- 数字键盘 ----
  Widget _buildKeypad(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: _keypadKeys.map((row) => Row(
          children: row.map((k) => Expanded(child: _KeyBtn(label: k, onTap: () => _onKeyPress(k)))).toList(),
        )).toList(),
      ),
    );
  }
}

class _KeyBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _KeyBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final del = label == '⌫';
    return SizedBox(
      height: 56,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          foregroundColor: del ? theme.colorScheme.error : theme.colorScheme.onSurface,
        ),
        child: del ? Icon(Icons.backspace_outlined, size: 24, color: theme.colorScheme.error)
            : Text(label, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface)),
      ),
    );
  }
}
