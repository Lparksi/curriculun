import 'package:flutter_test/flutter_test.dart';
import 'package:curriculum/services/config_version_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfigVersionManager Tests', () {
    // ========== 版本验证测试 (2个) ==========
    group('版本验证', () {
      test('isValidVersion - 有效的版本号格式', () {
        // Given: 各种有效的版本号
        final validVersions = [
          '1.0.0',
          '1.1.0',
          '2.0.0',
          '0.0.1',
          '10.20.30',
        ];

        // When & Then: 所有版本号都应该有效
        for (final version in validVersions) {
          expect(
            ConfigVersionManager.isValidVersion(version),
            isTrue,
            reason: '$version 应该是有效的版本号',
          );
        }
      });

      test('isValidVersion - 无效的版本号格式', () {
        // Given: 各种无效的版本号
        final invalidVersions = [
          'invalid',
          '1.0',
          '1',
          '1.0.0.0',
          'v1.0.0',
          '1.0.a',
          '',
          '1.0.0-beta',
        ];

        // When & Then: 所有版本号都应该无效
        for (final version in invalidVersions) {
          expect(
            ConfigVersionManager.isValidVersion(version),
            isFalse,
            reason: '$version 应该是无效的版本号',
          );
        }
      });
    });

    // ========== 版本比较测试 (2个) ==========
    group('版本比较', () {
      test('compareVersions - 正确比较不同版本号', () {
        // Given: 各种版本号对比
        final comparisons = [
          {'v1': '1.0.0', 'v2': '1.1.0', 'expected': -1}, // v1 < v2
          {'v1': '2.0.0', 'v2': '1.9.9', 'expected': 1}, // v1 > v2
          {'v1': '1.1.0', 'v2': '1.1.0', 'expected': 0}, // v1 == v2
          {'v1': '1.0.1', 'v2': '1.0.0', 'expected': 1}, // 补丁版本
          {'v1': '0.9.0', 'v2': '1.0.0', 'expected': -1}, // 主版本
          {'v1': '1.2.3', 'v2': '1.2.10', 'expected': -1}, // 数字比较
        ];

        // When & Then: 验证每个比较结果
        for (final comparison in comparisons) {
          final v1 = comparison['v1'] as String;
          final v2 = comparison['v2'] as String;
          final expected = comparison['expected'] as int;

          final result = ConfigVersionManager.compareVersions(v1, v2);

          expect(
            result,
            equals(expected),
            reason: '$v1 vs $v2 应该返回 $expected',
          );
        }
      });

      test('compareVersions - 处理无效版本号', () {
        // Given: 无效的版本号
        final invalidVersion = 'invalid.version';
        final validVersion = '1.0.0';

        // When & Then: 应该抛出 FormatException
        expect(
          () => ConfigVersionManager.compareVersions(invalidVersion, validVersion),
          throwsFormatException,
        );

        expect(
          () => ConfigVersionManager.compareVersions(validVersion, invalidVersion),
          throwsFormatException,
        );
      });
    });

    // ========== 版本升级检查测试 (2个) ==========
    group('版本升级检查', () {
      test('needsUpgrade - 检测需要升级的版本', () {
        // Given: 当前版本是 1.1.0
        expect(ConfigVersionManager.currentVersion, equals('1.1.0'));

        // When & Then: 旧版本需要升级
        expect(ConfigVersionManager.needsUpgrade('1.0.0'), isTrue);
        expect(ConfigVersionManager.needsUpgrade('0.9.0'), isTrue);

        // 当前版本不需要升级
        expect(ConfigVersionManager.needsUpgrade('1.1.0'), isFalse);

        // 未来版本不需要升级（超过当前版本）
        expect(ConfigVersionManager.needsUpgrade('2.0.0'), isFalse);
      });

      test('needsUpgrade - 处理无效版本号', () {
        // Given: 无效的版本号
        final invalidVersion = 'invalid';

        // When & Then: 应该抛出 FormatException
        expect(
          () => ConfigVersionManager.needsUpgrade(invalidVersion),
          throwsFormatException,
        );
      });
    });

    // ========== 配置升级测试 (2个) ==========
    group('配置升级', () {
      test('upgradeConfig - 从 1.0.0 升级到 1.1.0', () {
        // Given: 1.0.0 版本的配置数据（缺少版本号和导出时间）
        final oldConfig = {
          'data': {
            'courses': [
              {
                'name': '测试课程',
                'location': '测试地点',
                'teacher': '测试老师',
                'weekday': 1,
                'startSection': 1,
                'duration': 2,
                'color': '#FF0000',
                'startWeek': 1,
                'endWeek': 16,
              }
            ],
          },
        };

        // When: 升级配置
        final upgradedConfig = ConfigVersionManager.upgradeConfig(
          oldConfig,
          '1.0.0',
        );

        // Then: 验证升级结果
        // 1. 版本号已更新
        expect(upgradedConfig['version'], equals('1.1.0'));

        // 2. 添加了导出时间
        expect(upgradedConfig, contains('exportTime'));

        // 3. 数据部分保留
        expect(upgradedConfig, contains('data'));

        final data = upgradedConfig['data'] as Map<String, dynamic>;
        expect(data, contains('courses'));

        final courses = data['courses'] as List<dynamic>;
        expect(courses, hasLength(1));

        // 4. 课程数据保持原样（升级不修改课程字段）
        final course = courses[0] as Map<String, dynamic>;
        expect(course['name'], equals('测试课程'));
        expect(course['location'], equals('测试地点'));
        expect(course['weekday'], equals(1));
      });

      test('upgradeConfig - 跳过不支持的版本', () {
        // Given: 未来版本或当前版本的配置
        final futureConfig = {
          'version': '2.0.0',
          'data': {'courses': []},
        };

        // When: 尝试升级
        final result = ConfigVersionManager.upgradeConfig(futureConfig, '2.0.0');

        // Then: 配置未改变
        expect(result['version'], equals('2.0.0'));
      });
    });

    // ========== 迁移报告测试 (2个) ==========
    group('迁移报告生成', () {
      test('generateMigrationReport - 生成完整的迁移报告', () {
        // Given: 升级前后的配置数据（包含 data 字段）
        final originalData = {
          'version': '1.0.0',
          'data': {
            'courses': [
              {
                'name': '课程1',
                'location': '地点1',
                'teacher': '老师1',
                'weekday': 1,
                'startSection': 1,
                'duration': 2,
                'color': '#FF0000',
                'startWeek': 1,
                'endWeek': 16,
              },
              {
                'name': '课程2',
                'location': '地点2',
                'teacher': '老师2',
                'weekday': 2,
                'startSection': 3,
                'duration': 2,
                'color': '#00FF00',
                'startWeek': 1,
                'endWeek': 16,
              },
            ],
          },
        };

        final upgradedData = {
          'version': '1.1.0',
          'exportTime': DateTime.now().toIso8601String(),
          'data': {
            'courses': [
              {
                'name': '课程1',
                'location': '地点1',
                'teacher': '老师1',
                'weekday': 1,
                'startSection': 1,
                'duration': 2,
                'color': '#FF0000',
                'startWeek': 1,
                'endWeek': 16,
              },
              {
                'name': '课程2',
                'location': '地点2',
                'teacher': '老师2',
                'weekday': 2,
                'startSection': 3,
                'duration': 2,
                'color': '#00FF00',
                'startWeek': 1,
                'endWeek': 16,
              },
            ],
            'semesters': [],
            'timeTables': [],
          },
        };

        // When: 生成迁移报告
        final report = ConfigVersionManager.generateMigrationReport(
          '1.0.0',
          '1.1.0',
          originalData,
          upgradedData,
        );

        // Then: 验证报告内容
        expect(report, contains('原始版本: 1.0.0'));
        expect(report, contains('目标版本: 1.1.0'));
        expect(report, contains('数据统计:'));
        expect(report, contains('课程数量: 2 -> 2'));
        expect(report, contains('学期数量: 0 -> 0'));
        expect(report, contains('时间表数量: 0 -> 0'));
        expect(report, contains('升级状态: 成功'));
      });

      test('generateMigrationReport - 包含数据变化统计', () {
        // Given: 升级导致数据数量变化
        final originalData = {
          'version': '1.0.0',
          'data': {
            'courses': [
              {'name': '课程1'},
            ],
          },
        };

        final upgradedData = {
          'version': '1.1.0',
          'exportTime': DateTime.now().toIso8601String(),
          'data': {
            'courses': [
              {'name': '课程1'},
            ],
            'semesters': [
              {'id': 'default', 'name': '默认学期'},
            ],
            'timeTables': [],
          },
        };

        // When: 生成迁移报告
        final report = ConfigVersionManager.generateMigrationReport(
          '1.0.0',
          '1.1.0',
          originalData,
          upgradedData,
        );

        // Then: 验证数据统计
        expect(report, contains('课程数量: 1 -> 1'));
        expect(report, contains('学期数量: 0 -> 1'));
        expect(report, contains('时间表数量: 0 -> 0'));
      });
    });
  });
}
