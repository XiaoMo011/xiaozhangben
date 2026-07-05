import 'expense_provider.dart';

/// 全局应用状态
/// 使用单例模式，所有页面共享同一个ExpenseProvider实例
/// 后续可替换为 Provider / Riverpod 等正式状态管理方案
final ExpenseProvider appState = ExpenseProvider();
