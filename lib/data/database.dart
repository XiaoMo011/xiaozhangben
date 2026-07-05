import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/recurring_template.dart';

/// 数据库管理器 —— 单例模式，全局只有一个数据库连接
/// 负责建表、迁移、所有 CRUD 操作，以及连接生命周期管理
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;
  bool _isInitialized = false;

  /// 当前数据库版本
  static const int _dbVersion = 1;

  // ==================== 生命周期 ====================

  /// 初始化数据库（应用启动时调用一次）
  Future<void> init() async {
    if (_isInitialized) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'xiaozhangben.db');

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _isInitialized = true;
  }

  /// 获取数据库实例
  Database get db {
    if (_db == null || !_isInitialized) {
      throw StateError('数据库未初始化，请先调用 AppDatabase().init()');
    }
    return _db!;
  }

  /// 关闭数据库（应用退出时调用）
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
      _isInitialized = false;
    }
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;

  // ==================== 建表 ====================

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('expense', 'income')),
        amount REAL NOT NULL CHECK(amount > 0),
        major_category TEXT NOT NULL,
        minor_category TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT '现金',
        date TEXT NOT NULL,
        note TEXT DEFAULT '',
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurring_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 索引：加速按日期、类型、分类查询
    await db.execute('CREATE INDEX idx_tx_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_tx_type ON transactions(type)');
    await db.execute('CREATE INDEX idx_tx_major ON transactions(major_category)');
    await db.execute('CREATE INDEX idx_tx_type_date ON transactions(type, date)');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL UNIQUE,
        amount REAL NOT NULL CHECK(amount > 0),
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('expense', 'income')),
        amount REAL NOT NULL CHECK(amount > 0),
        major_category TEXT NOT NULL,
        minor_category TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT '现金',
        cycle TEXT NOT NULL CHECK(cycle IN ('daily', 'weekly', 'monthly', 'yearly')),
        cycle_day INTEGER NOT NULL DEFAULT 1,
        note TEXT DEFAULT '',
        is_active INTEGER NOT NULL DEFAULT 1,
        last_generated TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 版本升级时在此处理迁移逻辑
  }

  // ==================== 交易 CRUD ====================

  /// 插入一条交易记录
  Future<int> insertExpense(Expense expense) async {
    return await db.insert('transactions', expense.toMap());
  }

  /// 批量插入（导入时使用）
  Future<void> insertExpenses(List<Expense> expenses) async {
    final batch = db.batch();
    for (final e in expenses) {
      batch.insert('transactions', e.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// 更新一条交易记录
  Future<int> updateExpense(Expense expense) async {
    return await db.update(
      'transactions',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  /// 删除一条交易记录
  Future<int> deleteExpense(int id) async {
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// 查询所有交易（按日期倒序）
  Future<List<Expense>> getAllExpenses() async {
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  /// 按类型查询（支出/收入）
  Future<List<Expense>> getExpensesByType(String type) async {
    final maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  /// 搜索交易（按备注、分类名模糊匹配）
  Future<List<Expense>> searchExpenses(String keyword) async {
    final pattern = '%$keyword%';
    final maps = await db.query(
      'transactions',
      where: 'note LIKE ? OR major_category LIKE ? OR minor_category LIKE ?',
      whereArgs: [pattern, pattern, pattern],
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  /// 按日期范围和分类筛选
  Future<List<Expense>> filterExpenses({
    String? type,
    String? startDate,
    String? endDate,
    String? majorCategory,
    String? paymentMethod,
    int? limit,
    int? offset,
  }) async {
    final where = <String>[];
    final args = <dynamic>[];

    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (startDate != null) {
      where.add('date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      where.add('date <= ?');
      args.add(endDate);
    }
    if (majorCategory != null) {
      where.add('major_category = ?');
      args.add(majorCategory);
    }
    if (paymentMethod != null) {
      where.add('payment_method = ?');
      args.add(paymentMethod);
    }

    final maps = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  /// 按月份统计总金额
  Future<double> getMonthTotal({
    required String type,
    required String yearMonth, // '2026-07'
  }) async {
    final result = await db.rawQuery(
      '''SELECT COALESCE(SUM(amount), 0) as total
         FROM transactions
         WHERE type = ? AND strftime('%Y-%m', date) = ?''',
      [type, yearMonth],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// 按月份+分类统计
  Future<Map<String, double>> getMonthCategoryTotals({
    required String type,
    required String yearMonth,
  }) async {
    final results = await db.rawQuery(
      '''SELECT major_category, SUM(amount) as total
         FROM transactions
         WHERE type = ? AND strftime('%Y-%m', date) = ?
         GROUP BY major_category
         ORDER BY total DESC''',
      [type, yearMonth],
    );
    final map = <String, double>{};
    for (final r in results) {
      map[r['major_category'] as String] = (r['total'] as num).toDouble();
    }
    return map;
  }

  /// 获取某月所有类目名（用于筛选下拉）
  Future<List<String>> getDistinctMajorCategories({String? type}) async {
    String sql = 'SELECT DISTINCT major_category FROM transactions';
    List<dynamic>? args;
    if (type != null) {
      sql += ' WHERE type = ?';
      args = [type];
    }
    sql += ' ORDER BY major_category';
    final results = await db.rawQuery(sql, args);
    return results.map((r) => r['major_category'] as String).toList();
  }

  // ==================== 预算 CRUD ====================

  /// 设置/更新月度预算
  Future<void> setBudget(Budget budget) async {
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取某月预算
  Future<Budget?> getBudget(String yearMonth) async {
    final maps = await db.query(
      'budgets',
      where: 'month = ?',
      whereArgs: [yearMonth],
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  // ==================== 周期模板 CRUD ====================

  /// 新增周期模板
  Future<int> insertTemplate(RecurringTemplate template) async {
    return await db.insert('recurring_templates', template.toMap());
  }

  /// 更新周期模板
  Future<int> updateTemplate(RecurringTemplate template) async {
    return await db.update(
      'recurring_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  /// 删除周期模板
  Future<int> deleteTemplate(int id) async {
    return await db.delete('recurring_templates', where: 'id = ?', whereArgs: [id]);
  }

  /// 获取所有启用的周期模板
  Future<List<RecurringTemplate>> getActiveTemplates() async {
    final maps = await db.query(
      'recurring_templates',
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => RecurringTemplate.fromMap(m)).toList();
  }

  /// 获取所有周期模板
  Future<List<RecurringTemplate>> getAllTemplates() async {
    final maps = await db.query(
      'recurring_templates',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => RecurringTemplate.fromMap(m)).toList();
  }

  /// 更新模板最后生成日期
  Future<void> updateTemplateLastGenerated(int id, String dateStr) async {
    await db.update(
      'recurring_templates',
      {'last_generated': dateStr},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 统计查询 ====================

  /// 按日期统计每日金额
  Future<Map<String, double>> getDailyTotals({
    required String type,
    required String startDate,
    required String endDate,
  }) async {
    final results = await db.rawQuery(
      '''SELECT date, SUM(amount) as total
         FROM transactions
         WHERE type = ? AND date >= ? AND date <= ?
         GROUP BY date
         ORDER BY date''',
      [type, startDate, endDate],
    );
    final map = <String, double>{};
    for (final r in results) {
      map[r['date'] as String] = (r['total'] as num).toDouble();
    }
    return map;
  }

  /// 按大分类统计（指定日期范围）
  Future<Map<String, double>> getCategoryTotalsInRange({
    required String type,
    required String startDate,
    required String endDate,
  }) async {
    final results = await db.rawQuery(
      '''SELECT major_category, SUM(amount) as total
         FROM transactions
         WHERE type = ? AND date >= ? AND date <= ?
         GROUP BY major_category
         ORDER BY total DESC''',
      [type, startDate, endDate],
    );
    final map = <String, double>{};
    for (final r in results) {
      map[r['major_category'] as String] = (r['total'] as num).toDouble();
    }
    return map;
  }

  // ==================== 内存管理 ====================

  /// 清理旧数据（保留最近N条记录）
  Future<int> cleanOldTransactions({int keepCount = 1000}) async {
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM transactions');
    final total = result.first['cnt'] as int;
    if (total <= keepCount) return 0;

    // 保留最新的 keepCount 条
    final idsToKeep = await db.rawQuery(
      'SELECT id FROM transactions ORDER BY date DESC, id DESC LIMIT ?',
      [keepCount],
    );
    final keepSet = idsToKeep.map((r) => r['id']).toSet();

    if (keepSet.isEmpty) return 0;

    // 删除不在保留列表中的记录
    final placeholders = keepSet.map((_) => '?').join(',');
    final deleted = await db.rawDelete(
      'DELETE FROM transactions WHERE id NOT IN ($placeholders)',
      keepSet.toList(),
    );
    return deleted;
  }

  /// 获取数据库文件大小（字节）
  Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'xiaozhangben.db');
    try {
      final file = await _readFileSize(path);
      return file;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _readFileSize(String path) async {
    // sqflite 不直接暴露文件大小，使用 PRAGMA
    final results = await db.rawQuery('PRAGMA page_count');
    final pageCount = results.first.values.first as int;
    final pageSizeResults = await db.rawQuery('PRAGMA page_size');
    final pageSize = pageSizeResults.first.values.first as int;
    return pageCount * pageSize;
  }

  /// VACUUM 压缩数据库（回收空间）
  Future<void> vacuum() async {
    await db.execute('VACUUM');
  }
}
