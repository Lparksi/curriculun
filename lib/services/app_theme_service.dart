import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用主题模式存储服务
class AppThemeService {
  static const String _themeModeKey = 'app_theme_mode';

  /// 加载主题模式，默认为系统样式
  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_themeModeKey);

    switch (rawValue) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// 保存主题模式
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, rawValue);
  }
}
