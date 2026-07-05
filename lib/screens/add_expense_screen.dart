import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/categories.dart';
import '../models/expense.dart';

/// 记一笔 - 添加支出记录页面
///
/// 设计目标：用户能在10秒内完成一笔记录
/// 布局：金额输入区 → 分类选择 → 日期时间 → 备注 → 保存
class AddExpenseScreen extends StatefulWidget {
  /// 编辑已有记录时传入
  final Expense? existingExpense;

  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // ---- 表单状态 ----
  String _amountText = ''; // 显示在屏幕上的金额字符串
  double _amount = 0; // 实际金额数值
  String _selectedMajor = defaultCategories[0].name; // 选中的大级分类
  String _selectedMinor = defaultCategories[0].subCategories[0].name; // 选中的小级分类
  DateTime _selectedDate = DateTime.now(); // 选择的日期时间
  final TextEditingController _noteController = TextEditingController();

  // ---- 数字键盘布局 ----
  static const List<List<String>> _keypadKeys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  void initState() {
    super.initState();
    // 如果是编辑模式，填充已有数据
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _amount = e.amount;
      _amountText = _formatAmount(e.amount);
      _selectedMajor = e.majorCategory;
      _selectedMinor = e.minorCategory;
      _selectedDate = e.date;
      _noteController.text = e.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// 格式化金额显示（最多2位小数）
  String _formatAmount(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  /// 处理数字键盘输入
  void _onKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        // 退格
        if (_amountText.isNotEmpty) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        }
      } else if (key == '.') {
        // 小数点：只能有一个
        if (!_amountText.contains('.')) {
          _amountText += _amountText.isEmpty ? '0.' : '.';
        }
      } else {
        // 数字键
        // 限制整数部分最多9位，小数部分最多2位
        if (_amountText.contains('.')) {
          final parts = _amountText.split('.');
          if (parts.length == 2 && parts[1].length >= 2) return;
        } else if (_amountText.length >= 9) {
          return;
        }
        // 不允许以0开头（除非是0.xx）
        if (_amountText == '0' && key != '.') {
          _amountText = key;
        } else {
          _amountText += key;
        }
      }
      // 更新实际金额
      _amount = double.tryParse(_amountText) ?? 0;
    });
  }

  /// 保存支出记录
  void _saveExpense() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入金额'), duration: Duration(seconds: 2)),
      );
      return;
    }

    final expense = Expense(
      id: widget.existingExpense?.id,
      amount: _amount,
      date: _selectedDate,
      majorCategory: _selectedMajor,
      minorCategory: _selectedMinor,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    Navigator.pop(context, {'expense': expense});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingExpense != null;
    final subCategories = getSubCategories(_selectedMajor);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑记录' : '记一笔'),
        actions: [
          TextButton(
            onPressed: _saveExpense,
            child: const Text('保存', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 金额显示区
            _buildAmountDisplay(theme),
            const Divider(height: 1),
            // 表单区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 分类选择
                    _buildCategorySection(theme, subCategories),
                    const SizedBox(height: 20),
                    // 日期时间选择
                    _buildDateTimePicker(theme),
                    const SizedBox(height: 20),
                    // 备注输入
                    _buildNoteField(theme),
                  ],
                ),
              ),
            ),
            // 数字键盘
            _buildKeypad(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDisplay(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Text('¥', style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _amountText.isEmpty ? '0' : _amountText,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(ThemeData theme, List<Category> subCategories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('分类', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        // 大级分类 - 横向滚动标签
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: defaultCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final major = defaultCategories[index];
              final isSelected = major.name == _selectedMajor;
              return FilterChip(
                label: Text(major.name),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedMajor = major.name;
                    // 切换大类时，默认选择第一个小类
                    _selectedMinor = major.subCategories[0].name;
                  });
                },
                avatar: Icon(
                  IconData(0, fontFamily: 'MaterialIcons'),
                  size: 18,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // 小级分类 - 自动换行标签
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subCategories.map((sub) {
            final isSelected = sub.name == _selectedMinor;
            return ChoiceChip(
              label: Text(sub.name),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedMinor = sub.name;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(ThemeData theme) {
    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(_selectedDate);
    return InkWell(
      onTap: () async {
        // 选择日期
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (date != null && mounted) {
          // 选择时间
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_selectedDate),
          );
          if (time != null) {
            setState(() {
              _selectedDate = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            });
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: theme.colorScheme.outline),
            const SizedBox(width: 12),
            Text(dateStr, style: theme.textTheme.bodyLarge),
            const Spacer(),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('备注（选填）', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: '添加备注...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: _keypadKeys.map((row) {
          return Row(
            children: row.map((key) {
              return Expanded(
                child: _KeypadButton(
                  keyLabel: key,
                  onTap: () => _onKeyPress(key),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

/// 数字键盘单个按键
class _KeypadButton extends StatelessWidget {
  final String keyLabel;
  final VoidCallback onTap;

  const _KeypadButton({
    required this.keyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelete = keyLabel == '⌫';

    return SizedBox(
      height: 56,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          foregroundColor: isDelete
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
        ),
        child: Text(
          keyLabel,
          style: TextStyle(
            fontSize: isDelete ? 20 : 24,
            fontWeight: isDelete ? FontWeight.normal : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
