/// 月度预算数据模型
class Budget {
  final int? id;
  final String month; // 格式：'2026-07'
  final double amount;
  final String? createdAt;

  Budget({
    this.id,
    required this.month,
    required this.amount,
    this.createdAt,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      month: map['month'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'month': month,
      'amount': amount,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}
