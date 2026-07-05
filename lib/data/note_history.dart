import 'package:shared_preferences/shared_preferences.dart';

/// 备注历史管理器
/// 持久化保存用户最近的备注文本，支持按频次排序推荐
class NoteHistory {
  static const _maxStore = 50; // 最多保存50条历史
  static const _key = 'note_history';

  /// 获取最近使用的备注（按最近使用排序）
  static Future<List<String>> getRecent({int count = 3}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.take(count).toList();
  }

  /// 保存一条新备注（去重，最新的排前面）
  static Future<void> save(String note) async {
    if (note.trim().isEmpty) return;
    final trimmed = note.trim();
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    // 去重：移除相同的
    list.remove(trimmed);
    // 插入到最前面
    list.insert(0, trimmed);
    // 限制数量
    if (list.length > _maxStore) {
      list.removeRange(_maxStore, list.length);
    }

    await prefs.setStringList(_key, list);
  }

  /// 清空历史
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
