/// 周期账单模板
class RecurringTemplate {
  final int? id;
  final String name; // 模板名称，如"每月房租"
  final String type; // 'expense' 或 'income'
  final double amount;
  final String majorCategory;
  final String minorCategory;
  final String paymentMethod;
  final String cycle; // 'daily' / 'weekly' / 'monthly' / 'yearly'
  final int cycleDay; // 对于 monthly: 几号；对于 weekly: 周几(1-7)
  final String? note;
  final bool isActive;
  final String? lastGenerated; // 上次生成日期
  final String? createdAt;

  RecurringTemplate({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.majorCategory,
    required this.minorCategory,
    this.paymentMethod = '现金',
    required this.cycle,
    required this.cycleDay,
    this.note,
    this.isActive = true,
    this.lastGenerated,
    this.createdAt,
  });

  factory RecurringTemplate.fromMap(Map<String, dynamic> map) {
    return RecurringTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      majorCategory: map['major_category'] as String,
      minorCategory: map['minor_category'] as String,
      paymentMethod: (map['payment_method'] as String?) ?? '现金',
      cycle: map['cycle'] as String,
      cycleDay: (map['cycle_day'] as num).toInt(),
      note: map['note'] as String?,
      isActive: (map['is_active'] as int?) != 0,
      lastGenerated: map['last_generated'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      'major_category': majorCategory,
      'minor_category': minorCategory,
      'payment_method': paymentMethod,
      'cycle': cycle,
      'cycle_day': cycleDay,
      'note': note ?? '',
      'is_active': isActive ? 1 : 0,
      'last_generated': lastGenerated,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  /// 获取周期描述文字
  String get cycleDescription {
    switch (cycle) {
      case 'daily':
        return '每天';
      case 'weekly':
        final days = ['一', '二', '三', '四', '五', '六', '日'];
        return '每周${days[cycleDay - 1]}';
      case 'monthly':
        return '每月${cycleDay}号';
      case 'yearly':
        return '每年${cycleDay > 0 ? "${cycleDay}月" : ""}';
      default:
        return cycle;
    }
  }
}
