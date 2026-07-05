/// 交易记录数据模型
/// 统一表示支出和收入
class Expense {
  final int? id;
  final String type; // 'expense' 或 'income'
  final double amount;
  final DateTime date;
  final String majorCategory;
  final String minorCategory;
  final String paymentMethod; // '微信' / '支付宝' / '银行卡' / '现金' / '其他'
  final String? note;
  final bool isRecurring;
  final int? recurringId; // 关联的周期模板ID
  final String? createdAt;
  final String? updatedAt;

  Expense({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.majorCategory,
    required this.minorCategory,
    this.paymentMethod = '现金',
    this.note,
    this.isRecurring = false,
    this.recurringId,
    this.createdAt,
    this.updatedAt,
  });

  /// 从数据库 Map 创建
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      majorCategory: map['major_category'] as String,
      minorCategory: map['minor_category'] as String,
      paymentMethod: (map['payment_method'] as String?) ?? '现金',
      note: map['note'] as String?,
      isRecurring: (map['is_recurring'] as int?) == 1,
      recurringId: map['recurring_id'] as int?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// 转为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'major_category': majorCategory,
      'minor_category': minorCategory,
      'payment_method': paymentMethod,
      'note': note ?? '',
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_id': recurringId,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Expense copyWith({
    int? id,
    String? type,
    double? amount,
    DateTime? date,
    String? majorCategory,
    String? minorCategory,
    String? paymentMethod,
    String? note,
    bool? isRecurring,
    int? recurringId,
  }) {
    return Expense(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      majorCategory: majorCategory ?? this.majorCategory,
      minorCategory: minorCategory ?? this.minorCategory,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      createdAt: createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  String toString() =>
      'Expense(id:$id, $type, ¥$amount, $majorCategory/$minorCategory, $paymentMethod)';
}
