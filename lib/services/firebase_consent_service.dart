import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/firebase_consent.dart';

/// Firebase 同意配置服务
///
/// 负责存储和读取用户对 Firebase 各项功能的同意选择
class FirebaseConsentService {
  static const String _consentKey = 'firebase_consent';

  /// 加载用户同意配置
  static Future<FirebaseConsent> loadConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentJson = prefs.getString(_consentKey);

      if (consentJson == null || consentJson.isEmpty) {
        // 首次启动，返回默认配置（未显示过对话框）
        return const FirebaseConsent();
      }

      final consentMap = jsonDecode(consentJson) as Map<String, dynamic>;
      return FirebaseConsent.fromJson(consentMap);
    } catch (e) {
      // 解析失败，返回默认配置
      return const FirebaseConsent();
    }
  }

  /// 保存用户同意配置
  static Future<void> saveConsent(FirebaseConsent consent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentJson = jsonEncode(consent.toJson());
      await prefs.setString(_consentKey, consentJson);
    } catch (e) {
      // 保存失败，忽略错误
    }
  }

  /// 标记已显示过同意对话框
  static Future<void> markAsShown() async {
    final consent = await loadConsent();
    await saveConsent(consent.copyWith(hasShown: true));
  }

  /// 更新 Crashlytics 同意状态
  static Future<void> setCrashlyticsEnabled(bool enabled) async {
    final consent = await loadConsent();
    await saveConsent(
      consent.copyWith(
        hasShown: true,
        crashlyticsEnabled: enabled,
      ),
    );
  }

  /// 更新 Performance Monitoring 同意状态
  static Future<void> setPerformanceEnabled(bool enabled) async {
    final consent = await loadConsent();
    await saveConsent(
      consent.copyWith(
        hasShown: true,
        performanceEnabled: enabled,
      ),
    );
  }

  /// 更新 Analytics 同意状态
  static Future<void> setAnalyticsEnabled(bool enabled) async {
    final consent = await loadConsent();
    await saveConsent(
      consent.copyWith(
        hasShown: true,
        analyticsEnabled: enabled,
      ),
    );
  }

  /// 重置所有同意配置（用于测试或重置应用）
  static Future<void> resetConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentKey);
  }
}
