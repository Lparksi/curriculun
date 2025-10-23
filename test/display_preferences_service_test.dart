import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curriculum/services/display_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DisplayPreferencesService Tests', () {
    setUp(() async {
      // 重置 SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    // ========== loadShowWeekend 测试 (2个) ==========
    group('loadShowWeekend', () {
      test('loadShowWeekend - 首次启动返回默认值 true', () async {
        // Given: 空的本地存储
        SharedPreferences.setMockInitialValues({});

        // When: 加载是否显示周末
        final showWeekend = await DisplayPreferencesService.loadShowWeekend();

        // Then: 返回默认值 true（默认显示周末）
        expect(showWeekend, isTrue);
      });

      test('loadShowWeekend - 加载已保存的偏好值', () async {
        // Given: 已保存偏好为 false（不显示周末）
        await DisplayPreferencesService.saveShowWeekend(false);

        // When: 重新加载偏好
        final showWeekend = await DisplayPreferencesService.loadShowWeekend();

        // Then: 返回已保存的值
        expect(showWeekend, isFalse);

        // Given: 已保存偏好为 true（显示周末）
        await DisplayPreferencesService.saveShowWeekend(true);

        // When: 重新加载偏好
        final showWeekendTrue =
            await DisplayPreferencesService.loadShowWeekend();

        // Then: 返回已保存的值
        expect(showWeekendTrue, isTrue);
      });
    });

    // ========== saveShowWeekend 测试 (2个) ==========
    group('saveShowWeekend', () {
      test('saveShowWeekend - 保存显示周末（true）', () async {
        // Given: 初始状态
        SharedPreferences.setMockInitialValues({});

        // When: 保存显示周末偏好
        await DisplayPreferencesService.saveShowWeekend(true);

        // Then: 偏好已保存
        final showWeekend = await DisplayPreferencesService.loadShowWeekend();
        expect(showWeekend, isTrue);

        // 验证底层存储值
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('display_show_weekend'), isTrue);
      });

      test('saveShowWeekend - 保存不显示周末（false）', () async {
        // Given: 初始状态
        SharedPreferences.setMockInitialValues({});

        // When: 保存不显示周末偏好
        await DisplayPreferencesService.saveShowWeekend(false);

        // Then: 偏好已保存
        final showWeekend = await DisplayPreferencesService.loadShowWeekend();
        expect(showWeekend, isFalse);

        // 验证底层存储值
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('display_show_weekend'), isFalse);
      });
    });

    // ========== 偏好切换测试 (1个) ==========
    test('显示偏好切换 - 正确保存和加载不同值', () async {
      // Given: 初始状态
      SharedPreferences.setMockInitialValues({});

      // When: 切换显示偏好
      await DisplayPreferencesService.saveShowWeekend(true);
      expect(await DisplayPreferencesService.loadShowWeekend(), isTrue);

      await DisplayPreferencesService.saveShowWeekend(false);
      expect(await DisplayPreferencesService.loadShowWeekend(), isFalse);

      await DisplayPreferencesService.saveShowWeekend(true);
      expect(await DisplayPreferencesService.loadShowWeekend(), isTrue);

      // Then: 每次切换后都能正确加载
    });

    // ========== 双向转换验证 (1个) ==========
    test('显示偏好双向转换保持一致性', () async {
      // Given: 所有可能的值
      final values = [true, false];

      for (final originalValue in values) {
        // When: 保存并重新加载
        await DisplayPreferencesService.saveShowWeekend(originalValue);
        final loadedValue = await DisplayPreferencesService.loadShowWeekend();

        // Then: 值保持一致
        expect(
          loadedValue,
          equals(originalValue),
          reason: '显示偏好 $originalValue 双向转换应该保持一致',
        );
      }
    });

    // ========== 默认值测试 (1个) ==========
    test('首次使用默认显示周末', () async {
      // Given: 全新安装（无任何存储数据）
      SharedPreferences.setMockInitialValues({});

      // When: 读取显示周末偏好
      final showWeekend = await DisplayPreferencesService.loadShowWeekend();

      // Then: 默认为 true（显示周末）
      expect(showWeekend, isTrue);
    });

    // ========== 持久化验证 (1个) ==========
    test('偏好设置正确持久化', () async {
      // Given: 保存偏好为不显示周末
      await DisplayPreferencesService.saveShowWeekend(false);

      // When: 模拟应用重启（重新从存储加载）
      final showWeekendAfterRestart =
          await DisplayPreferencesService.loadShowWeekend();

      // Then: 偏好仍然保持不显示周末
      expect(showWeekendAfterRestart, isFalse);

      // When: 再次切换为显示周末
      await DisplayPreferencesService.saveShowWeekend(true);
      final showWeekendAfterChange =
          await DisplayPreferencesService.loadShowWeekend();

      // Then: 新的偏好已保存
      expect(showWeekendAfterChange, isTrue);
    });
  });
}
