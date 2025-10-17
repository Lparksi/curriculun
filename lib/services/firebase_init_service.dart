import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import '../models/firebase_consent.dart';
import 'firebase_consent_service.dart';

/// Firebase 条件初始化服务
///
/// 根据用户同意配置，选择性地初始化 Firebase 各项功能
class FirebaseInitService {
  static bool _isInitialized = false;
  static FirebaseConsent? _currentConsent;

  /// 获取当前同意配置
  static FirebaseConsent? get currentConsent => _currentConsent;

  /// Firebase 是否已初始化
  static bool get isInitialized => _isInitialized;

  /// 初始化 Firebase（根据用户同意）
  ///
  /// 返回 true 表示成功初始化，false 表示用户未同意或初始化失败
  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // 加载用户同意配置
      final consent = await FirebaseConsentService.loadConsent();
      _currentConsent = consent;

      // 如果用户未启用任何 Firebase 功能，直接返回
      if (!consent.hasAnyEnabled) {
        debugPrint('Firebase: 用户未启用任何功能，跳过初始化');
        return false;
      }

      // 初始化 Firebase Core
      await Firebase.initializeApp();
      debugPrint('Firebase: Core 初始化成功');

      // 根据用户同意，初始化各项功能
      await _initializeCrashlytics(consent.crashlyticsEnabled);
      await _initializePerformance(consent.performanceEnabled);
      await _initializeAnalytics(consent.analyticsEnabled);

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Firebase 初始化失败: $e');
      return false;
    }
  }

  /// 初始化 Crashlytics
  static Future<void> _initializeCrashlytics(bool enabled) async {
    if (!enabled) {
      debugPrint('Firebase: Crashlytics 已禁用');
      return;
    }

    try {
      // 启用 Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // 将 Flutter 框架错误传递给 Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // 捕获异步错误
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      debugPrint('Firebase: Crashlytics 初始化成功');
    } catch (e) {
      debugPrint('Firebase: Crashlytics 初始化失败: $e');
    }
  }

  /// 初始化 Performance Monitoring
  static Future<void> _initializePerformance(bool enabled) async {
    if (!enabled) {
      debugPrint('Firebase: Performance Monitoring 已禁用');
      return;
    }

    try {
      // 启用性能监控
      final performance = FirebasePerformance.instance;
      await performance.setPerformanceCollectionEnabled(true);

      debugPrint('Firebase: Performance Monitoring 初始化成功');
    } catch (e) {
      debugPrint('Firebase: Performance Monitoring 初始化失败: $e');
    }
  }

  /// 初始化 Analytics
  static Future<void> _initializeAnalytics(bool enabled) async {
    if (!enabled) {
      debugPrint('Firebase: Analytics 已禁用');
      return;
    }

    try {
      // 启用数据分析（如果项目集成了 Firebase Analytics）
      // 注意：当前项目未添加 firebase_analytics 依赖
      // 如果需要使用，请在 pubspec.yaml 中添加：
      // firebase_analytics: ^11.0.0

      debugPrint('Firebase: Analytics 初始化成功 (预留)');
    } catch (e) {
      debugPrint('Firebase: Analytics 初始化失败: $e');
    }
  }

  /// 重置初始化状态（用于测试或重新初始化）
  static void reset() {
    _isInitialized = false;
    _currentConsent = null;
  }

  /// 检查特定功能是否已启用
  static bool isCrashlyticsEnabled() {
    return _currentConsent?.crashlyticsEnabled ?? false;
  }

  static bool isPerformanceEnabled() {
    return _currentConsent?.performanceEnabled ?? false;
  }

  static bool isAnalyticsEnabled() {
    return _currentConsent?.analyticsEnabled ?? false;
  }
}
