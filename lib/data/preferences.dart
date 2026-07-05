import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用偏好设置管理器
class AppPreferences extends ChangeNotifier {
  static final AppPreferences _instance = AppPreferences._();
  factory AppPreferences() => _instance;
  AppPreferences._();

  SharedPreferences? _prefs;

  // ---- 状态 ----
  String? _bgImagePath;
  int _noteHistoryCount = 3;
  List<String> _presetNotes = [];
  int _presetNoteCount = 3;

  // ---- Getters ----
  String? get bgImagePath => _bgImagePath;
  int get noteHistoryCount => _noteHistoryCount;
  List<String> get presetNotes => _presetNotes;
  int get presetNoteCount => _presetNoteCount;

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _bgImagePath = _prefs!.getString('bg_image_path');
    _noteHistoryCount = _prefs!.getInt('note_history_count') ?? 3;
    _presetNotes = _prefs!.getStringList('preset_notes') ?? [];
    _presetNoteCount = _prefs!.getInt('preset_note_count') ?? 3;
  }

  // ---- 背景图片 ----
  Future<void> pickBackgroundImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery, maxWidth: 1080, maxHeight: 1920, imageQuality: 85);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final destPath = '${dir.path}/bg_image.jpg';
    await File(picked.path).copy(destPath);
    _bgImagePath = destPath;
    await _prefs!.setString('bg_image_path', destPath);
    notifyListeners();
  }

  Future<void> removeBackgroundImage() async {
    if (_bgImagePath != null) {
      try { await File(_bgImagePath!).delete(); } catch (_) {}
    }
    _bgImagePath = null;
    await _prefs!.remove('bg_image_path');
    notifyListeners();
  }

  // ---- 备注历史数量 ----
  Future<void> setNoteHistoryCount(int count) async {
    _noteHistoryCount = count.clamp(0, 10);
    await _prefs!.setInt('note_history_count', _noteHistoryCount);
    notifyListeners();
  }

  // ---- 固化备注 ----
  /// 在数量上限内可编辑的预设备注列表
  List<String> get editablePresetNotes {
    // 保证列表长度 = presetNoteCount（不足补空字符串）
    final list = List<String>.from(_presetNotes);
    while (list.length < _presetNoteCount) { list.add(''); }
    if (list.length > _presetNoteCount) {
      list.removeRange(_presetNoteCount, list.length);
    }
    return list;
  }

  Future<void> setPresetNoteCount(int count) async {
    _presetNoteCount = count.clamp(0, 10);
    if (_presetNotes.length > _presetNoteCount) {
      _presetNotes = _presetNotes.sublist(0, _presetNoteCount);
    }
    await _prefs!.setInt('preset_note_count', _presetNoteCount);
    await _prefs!.setStringList('preset_notes', _presetNotes);
    notifyListeners();
  }

  /// 更新单个固化备注（按索引）
  Future<void> updatePresetNote(int index, String value) async {
    // 确保列表足够长
    while (_presetNotes.length <= index) { _presetNotes.add(''); }
    _presetNotes[index] = value.trim();
    // 移除尾部空字符串
    while (_presetNotes.isNotEmpty && _presetNotes.last.isEmpty) {
      _presetNotes.removeLast();
    }
    await _prefs!.setStringList('preset_notes', _presetNotes);
    notifyListeners();
  }
}

/// 全局实例
final AppPreferences appPrefs = AppPreferences();
