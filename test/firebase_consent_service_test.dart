import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curriculum/services/firebase_consent_service.dart';
import 'package:curriculum/models/firebase_consent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseConsentService Tests', () {
    setUp(() async {
      // 重置 SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    // ========== loadConsent 测试 (2个) ==========
    group('loadConsent', () {
      test('loadConsent - 首次启动返回默认配置', () async {
        // Given: 空的本地存储
        SharedPreferences.setMockInitialValues({});

        // When: 加载配置
        final consent = await FirebaseConsentService.loadConsent();

        // Then: 返回默认配置（全部为 false）
        expect(consent.hasShown, isFalse);
        expect(consent.crashlyticsEnabled, isFalse);
        expect(consent.performanceEnabled, isFalse);
        expect(consent.analyticsEnabled, isFalse);
        expect(consent.hasAnyEnabled, isFalse);
      });

      test('loadConsent - 加载已保存的配置', () async {
        // Given: 已保存的配置数据
        final savedConsent = const FirebaseConsent(
          hasShown: true,
          crashlyticsEnabled: true,
          performanceEnabled: false,
          analyticsEnabled: true,
        );

        await FirebaseConsentService.saveConsent(savedConsent);

        // When: 重新加载配置
        final loadedConsent = await FirebaseConsentService.loadConsent();

        // Then: 正确加载配置
        expect(loadedConsent.hasShown, isTrue);
        expect(loadedConsent.crashlyticsEnabled, isTrue);
        expect(loadedConsent.performanceEnabled, isFalse);
        expect(loadedConsent.analyticsEnabled, isTrue);
        expect(loadedConsent.hasAnyEnabled, isTrue);
      });
    });

    // ========== saveConsent 测试 (1个) ==========
    test('saveConsent - 成功保存配置', () async {
      // Given: 一个配置对象
      const newConsent = FirebaseConsent(
        hasShown: true,
        crashlyticsEnabled: false,
        performanceEnabled: true,
        analyticsEnabled: false,
      );

      // When: 保存配置
      await FirebaseConsentService.saveConsent(newConsent);

      // Then: 配置已保存到存储
      final loaded = await FirebaseConsentService.loadConsent();
      expect(loaded.hasShown, equals(newConsent.hasShown));
      expect(loaded.crashlyticsEnabled, equals(newConsent.crashlyticsEnabled));
      expect(loaded.performanceEnabled, equals(newConsent.performanceEnabled));
      expect(loaded.analyticsEnabled, equals(newConsent.analyticsEnabled));
    });

    // ========== markAsShown 测试 (1个) ==========
    test('markAsShown - 标记已显示对话框', () async {
      // Given: 初始状态（hasShown = false）
      final initialConsent = await FirebaseConsentService.loadConsent();
      expect(initialConsent.hasShown, isFalse);

      // When: 标记为已显示
      await FirebaseConsentService.markAsShown();

      // Then: hasShown 变为 true，其他字段保持不变
      final updatedConsent = await FirebaseConsentService.loadConsent();
      expect(updatedConsent.hasShown, isTrue);
      expect(updatedConsent.crashlyticsEnabled, isFalse);
      expect(updatedConsent.performanceEnabled, isFalse);
      expect(updatedConsent.analyticsEnabled, isFalse);
    });

    // ========== setCrashlyticsEnabled 测试 (1个) ==========
    test('setCrashlyticsEnabled - 更新 Crashlytics 同意状态', () async {
      // Given: 初始状态
      SharedPreferences.setMockInitialValues({});

      // When: 启用 Crashlytics
      await FirebaseConsentService.setCrashlyticsEnabled(true);

      // Then: Crashlytics 已启用，hasShown 自动设为 true
      final consent = await FirebaseConsentService.loadConsent();
      expect(consent.crashlyticsEnabled, isTrue);
      expect(consent.hasShown, isTrue);
      expect(consent.performanceEnabled, isFalse);
      expect(consent.analyticsEnabled, isFalse);

      // When: 禁用 Crashlytics
      await FirebaseConsentService.setCrashlyticsEnabled(false);

      // Then: Crashlytics 已禁用
      final disabledConsent = await FirebaseConsentService.loadConsent();
      expect(disabledConsent.crashlyticsEnabled, isFalse);
      expect(disabledConsent.hasShown, isTrue); // 仍然保持 true
    });

    // ========== setPerformanceEnabled 测试 (1个) ==========
    test('setPerformanceEnabled - 更新 Performance 同意状态', () async {
      // Given: 初始状态
      SharedPreferences.setMockInitialValues({});

      // When: 启用 Performance Monitoring
      await FirebaseConsentService.setPerformanceEnabled(true);

      // Then: Performance 已启用，hasShown 自动设为 true
      final consent = await FirebaseConsentService.loadConsent();
      expect(consent.performanceEnabled, isTrue);
      expect(consent.hasShown, isTrue);
      expect(consent.crashlyticsEnabled, isFalse);
      expect(consent.analyticsEnabled, isFalse);

      // When: 禁用 Performance Monitoring
      await FirebaseConsentService.setPerformanceEnabled(false);

      // Then: Performance 已禁用
      final disabledConsent = await FirebaseConsentService.loadConsent();
      expect(disabledConsent.performanceEnabled, isFalse);
    });

    // ========== setAnalyticsEnabled 测试 (1个) ==========
    test('setAnalyticsEnabled - 更新 Analytics 同意状态', () async {
      // Given: 初始状态
      SharedPreferences.setMockInitialValues({});

      // When: 启用 Analytics
      await FirebaseConsentService.setAnalyticsEnabled(true);

      // Then: Analytics 已启用，hasShown 自动设为 true
      final consent = await FirebaseConsentService.loadConsent();
      expect(consent.analyticsEnabled, isTrue);
      expect(consent.hasShown, isTrue);
      expect(consent.crashlyticsEnabled, isFalse);
      expect(consent.performanceEnabled, isFalse);

      // When: 禁用 Analytics
      await FirebaseConsentService.setAnalyticsEnabled(false);

      // Then: Analytics 已禁用
      final disabledConsent = await FirebaseConsentService.loadConsent();
      expect(disabledConsent.analyticsEnabled, isFalse);
    });

    // ========== resetConsent 测试 (1个) ==========
    test('resetConsent - 重置所有配置', () async {
      // Given: 已保存的配置
      const existingConsent = FirebaseConsent(
        hasShown: true,
        crashlyticsEnabled: true,
        performanceEnabled: true,
        analyticsEnabled: true,
      );
      await FirebaseConsentService.saveConsent(existingConsent);

      // 验证配置已保存
      final beforeReset = await FirebaseConsentService.loadConsent();
      expect(beforeReset.hasShown, isTrue);

      // When: 重置配置
      await FirebaseConsentService.resetConsent();

      // Then: 返回默认配置
      final afterReset = await FirebaseConsentService.loadConsent();
      expect(afterReset.hasShown, isFalse);
      expect(afterReset.crashlyticsEnabled, isFalse);
      expect(afterReset.performanceEnabled, isFalse);
      expect(afterReset.analyticsEnabled, isFalse);
    });

    // ========== 错误处理测试 (1个) ==========
    test('loadConsent - 处理无效 JSON 数据', () async {
      // Given: 无效的 JSON 数据
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('firebase_consent', 'invalid json data');

      // When: 尝试加载配置
      final consent = await FirebaseConsentService.loadConsent();

      // Then: 返回默认配置（不崩溃）
      expect(consent.hasShown, isFalse);
      expect(consent.crashlyticsEnabled, isFalse);
      expect(consent.performanceEnabled, isFalse);
      expect(consent.analyticsEnabled, isFalse);
    });
  });
}
