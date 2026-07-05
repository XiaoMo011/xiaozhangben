import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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
  double _bgOpacity = 0.12; // 背景透明度，默认12%
  int _noteHistoryCount = 3;
  List<String> _presetNotes = [];
  int _presetNoteCount = 3;
  int _defaultDateRange = 0; // 0=近7天 1=本周 2=本月 3=本年

  // ---- Getters ----
  String? get bgImagePath => _bgImagePath;
  double get bgOpacity => _bgOpacity;
  int get noteHistoryCount => _noteHistoryCount;
  List<String> get presetNotes => _presetNotes;
  int get presetNoteCount => _presetNoteCount;
  int get defaultDateRange => _defaultDateRange;

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _bgImagePath = _prefs!.getString('bg_image_path');
    _noteHistoryCount = _prefs!.getInt('note_history_count') ?? 3;
    _presetNotes = _prefs!.getStringList('preset_notes') ?? [];
    _presetNoteCount = _prefs!.getInt('preset_note_count') ?? 3;
    _defaultDateRange = _prefs!.getInt('default_date_range') ?? 0;
    _bgOpacity = _prefs!.getDouble('bg_opacity') ?? 0.12;
  }

  // ---- 背景图片 ----
  Future<void> pickBackgroundImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1920, imageQuality: 90);
    if (picked == null) return;

    // 裁剪图片以适配手机屏幕比例
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 19.5),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪背景',
          toolbarColor: Colors.green.shade700,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
      ],
    );

    final sourcePath = cropped?.path ?? picked.path;

    // 删除旧背景防止堆叠
    if (_bgImagePath != null) {
      try { await File(_bgImagePath!).delete(); } catch (_) {}
    }
    final dir = await getApplicationDocumentsDirectory();
    final destPath = '${dir.path}/bg_image.jpg';
    await File(sourcePath).copy(destPath);
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

  // ---- 默认日期范围 ----
  Future<void> setDefaultDateRange(int range) async {
    _defaultDateRange = range.clamp(0, 3);
    await _prefs!.setInt('default_date_range', _defaultDateRange);
    notifyListeners();
  }

  // ---- 背景透明度 ----
  Future<void> setBgOpacity(double opacity) async {
    _bgOpacity = opacity.clamp(0.03, 0.50);
    await _prefs!.setDouble('bg_opacity', _bgOpacity);
    notifyListeners();
  }

  // ---- 备注历史数量 ----
  Future<void> setNoteHistoryCount(int count) async {
    _noteHistoryCount = count.clamp(0, 10);
    await _prefs!.setInt('note_history_count', _noteHistoryCount);
    notifyListeners();
  }

  // ---- 固化备注 ----
  List<String> get editablePresetNotes {
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

  Future<void> updatePresetNote(int index, String value) async {
    while (_presetNotes.length <= index) { _presetNotes.add(''); }
    _presetNotes[index] = value.trim();
    while (_presetNotes.isNotEmpty && _presetNotes.last.isEmpty) {
      _presetNotes.removeLast();
    }
    await _prefs!.setStringList('preset_notes', _presetNotes);
    notifyListeners();
  }
}

/// 全局实例
final AppPreferences appPrefs = AppPreferences();
