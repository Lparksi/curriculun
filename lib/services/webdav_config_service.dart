import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/webdav_config.dart';

/// WebDAV 配置存储服务
/// 负责 WebDAV 配置的持久化存储和读取
class WebDavConfigService {
  /// SharedPreferences 存储键
  static const String _configKey = 'webdav_config';

  /// 保存 WebDAV 配置
  static Future<void> saveConfig(WebDavConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(config.toJson());
      await prefs.setString(_configKey, jsonString);
      debugPrint('WebDAV 配置已保存');
    } catch (e) {
      debugPrint('保存 WebDAV 配置失败: $e');
      rethrow;
    }
  }

  /// 加载 WebDAV 配置
  /// 如果不存在或加载失败，返回默认配置
  static Future<WebDavConfig> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_configKey);

      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('未找到 WebDAV 配置，返回默认配置');
        return WebDavConfig.defaultConfig();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final config = WebDavConfig.fromJson(json);
      debugPrint('WebDAV 配置加载成功');
      return config;
    } catch (e) {
      debugPrint('加载 WebDAV 配置失败: $e，返回默认配置');
      return WebDavConfig.defaultConfig();
    }
  }

  /// 清除 WebDAV 配置
  static Future<void> clearConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_configKey);
      debugPrint('WebDAV 配置已清除');
    } catch (e) {
      debugPrint('清除 WebDAV 配置失败: $e');
      rethrow;
    }
  }

  /// 检查是否已配置 WebDAV
  static Future<bool> hasConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_configKey);
    } catch (e) {
      debugPrint('检查 WebDAV 配置失败: $e');
      return false;
    }
  }

  /// 启用或禁用 WebDAV 备份
  static Future<void> setEnabled(bool enabled) async {
    try {
      final config = await loadConfig();
      final newConfig = config.copyWith(enabled: enabled);
      await saveConfig(newConfig);
      debugPrint('WebDAV 备份已${enabled ? "启用" : "禁用"}');
    } catch (e) {
      debugPrint('设置 WebDAV 启用状态失败: $e');
      rethrow;
    }
  }

  /// 测试连接（验证配置是否有效）
  static Future<bool> testConnection(WebDavConfig config) async {
    try {
      if (!config.isValid) {
        debugPrint('WebDAV 配置无效');
        return false;
      }

      // TODO: 实际的连接测试将在 WebDAV 服务层实现
      // 这里暂时只验证配置的有效性
      debugPrint('WebDAV 配置验证通过');
      return true;
    } catch (e) {
      debugPrint('WebDAV 连接测试失败: $e');
      return false;
    }
  }
}
