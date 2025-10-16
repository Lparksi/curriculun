import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 通用显示偏好存储服务
class DisplayPreferencesService {
  static const String _showWeekendKey = 'display_show_weekend';

  /// 读取是否展示周末，默认展示
  static Future<bool> loadShowWeekend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_showWeekendKey) ?? true;
    } catch (e) {
      debugPrint('读取显示偏好失败: $e');
      return true;
    }
  }

  /// 保存是否展示周末
  static Future<void> saveShowWeekend(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showWeekendKey, value);
    } catch (e) {
      debugPrint('保存显示偏好失败: $e');
    }
  }
}

