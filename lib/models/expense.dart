/// 支出记录数据模型
class Expense {
  final int? id; // 数据库自增主键
  final double amount; // 金额（人民币元）
  final DateTime date; // 消费日期时间
  final String majorCategory; // 大级分类，如"餐饮饮食"
  final String minorCategory; // 小级分类，如"午餐"
  final String? note; // 可选备注，最多200字

  Expense({
    this.id,
    required this.amount,
    required this.date,
    required this.majorCategory,
    required this.minorCategory,
    this.note,
  });

  /// 从数据库Map创建Expense对象
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      majorCategory: map['majorCategory'] as String,
      minorCategory: map['minorCategory'] as String,
      note: map['note'] as String?,
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'majorCategory': majorCategory,
      'minorCategory': minorCategory,
      'note': note,
    };
  }

  /// 复制并修改部分字段
  Expense copyWith({
    int? id,
    double? amount,
    DateTime? date,
    String? majorCategory,
    String? minorCategory,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      majorCategory: majorCategory ?? this.majorCategory,
      minorCategory: minorCategory ?? this.minorCategory,
      note: note ?? this.note,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, category: $majorCategory/$minorCategory, date: $date)';
  }
}
