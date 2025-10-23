import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curriculum/services/app_theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppThemeService Tests', () {
    setUp(() async {
      // 重置 SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    // ========== loadThemeMode 测试 (2个) ==========
    group('loadThemeMode', () {
      test('loadThemeMode - 首次启动返回系统默认模式', () async {
        // Given: 空的本地存储
        SharedPreferences.setMockInitialValues({});

        // When: 加载主题模式
        final themeMode = await AppThemeService.loadThemeMode();

        // Then: 返回系统默认模式
        expect(themeMode, equals(ThemeMode.system));
      });

      test('loadThemeMode - 加载已保存的主题模式', () async {
        // Given: 已保存亮色主题
        await AppThemeService.saveThemeMode(ThemeMode.light);

        // When: 重新加载主题模式
        final lightMode = await AppThemeService.loadThemeMode();

        // Then: 返回亮色模式
        expect(lightMode, equals(ThemeMode.light));

        // Given: 已保存暗色主题
        await AppThemeService.saveThemeMode(ThemeMode.dark);

        // When: 重新加载主题模式
        final darkMode = await AppThemeService.loadThemeMode();

        // Then: 返回暗色模式
        expect(darkMode, equals(ThemeMode.dark));
      });
    });

    // ========== saveThemeMode 测试 (3个) ==========
    group('saveThemeMode', () {
      test('saveThemeMode - 保存亮色主题', () async {
        // Given: 初始状态
        SharedPreferences.setMockInitialValues({});

        // When: 保存亮色主题
        await AppThemeService.saveThemeMode(ThemeMode.light);

        // Then: 主题已保存
        final themeMode = await AppThemeService.loadThemeMode();
        expect(themeMode, equals(ThemeMode.light));

        // 验证底层存储值
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_theme_mode'), equals('light'));
      });

      test('saveThemeMode - 保存暗色主题', () async {
        // Given: 初始状态
        SharedPreferences.setMockInitialValues({});

        // When: 保存暗色主题
        await AppThemeService.saveThemeMode(ThemeMode.dark);

        // Then: 主题已保存
        final themeMode = await AppThemeService.loadThemeMode();
        expect(themeMode, equals(ThemeMode.dark));

        // 验证底层存储值
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_theme_mode'), equals('dark'));
      });

      test('saveThemeMode - 保存系统主题', () async {
        // Given: 初始状态
        SharedPreferences.setMockInitialValues({});

        // When: 保存系统主题
        await AppThemeService.saveThemeMode(ThemeMode.system);

        // Then: 主题已保存
        final themeMode = await AppThemeService.loadThemeMode();
        expect(themeMode, equals(ThemeMode.system));

        // 验证底层存储值
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_theme_mode'), equals('system'));
      });
    });

    // ========== 主题切换测试 (1个) ==========
    test('主题模式切换 - 正确保存和加载不同模式', () async {
      // Given: 初始状态
      SharedPreferences.setMockInitialValues({});

      // When: 依次切换主题模式
      await AppThemeService.saveThemeMode(ThemeMode.light);
      expect(await AppThemeService.loadThemeMode(), equals(ThemeMode.light));

      await AppThemeService.saveThemeMode(ThemeMode.dark);
      expect(await AppThemeService.loadThemeMode(), equals(ThemeMode.dark));

      await AppThemeService.saveThemeMode(ThemeMode.system);
      expect(await AppThemeService.loadThemeMode(), equals(ThemeMode.system));

      // Then: 每次切换后都能正确加载
    });

    // ========== 边界情况测试 (1个) ==========
    test('loadThemeMode - 处理无效的存储值', () async {
      // Given: 无效的主题模式值
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme_mode', 'invalid_mode');

      // When: 加载主题模式
      final themeMode = await AppThemeService.loadThemeMode();

      // Then: 返回默认系统模式（不崩溃）
      expect(themeMode, equals(ThemeMode.system));
    });

    // ========== 双向转换验证 (1个) ==========
    test('主题模式双向转换保持一致性', () async {
      // Given: 所有可能的主题模式
      final themeModes = [
        ThemeMode.light,
        ThemeMode.dark,
        ThemeMode.system,
      ];

      for (final originalMode in themeModes) {
        // When: 保存并重新加载
        await AppThemeService.saveThemeMode(originalMode);
        final loadedMode = await AppThemeService.loadThemeMode();

        // Then: 模式保持一致
        expect(
          loadedMode,
          equals(originalMode),
          reason: '主题模式 $originalMode 双向转换应该保持一致',
        );
      }
    });
  });
}
