import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/semester_settings.dart';

/// 学期设置本地存储服务
class SettingsService {
  static const String _settingsKey = 'semester_settings';

  /// 保存学期设置
  static Future<void> saveSemesterSettings(SemesterSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, jsonString);
  }

  /// 读取学期设置
  static Future<SemesterSettings> loadSemesterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString == null) {
      // 如果没有保存过设置，返回默认设置
      return SemesterSettings.defaultSettings();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SemesterSettings.fromJson(json);
    } catch (e) {
      // 如果解析失败，返回默认设置
      return SemesterSettings.defaultSettings();
    }
  }

  /// 重置为默认设置
  static Future<void> resetToDefault() async {
    final defaultSettings = SemesterSettings.defaultSettings();
    await saveSemesterSettings(defaultSettings);
  }

  /// 清除所有设置
  static Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }
}
