import 'package:flutter_test/flutter_test.dart';
import 'package:curriculum/models/semester_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SemesterSettings Model Serialization Tests', () {
    // ========== JSON 反序列化测试 (2个) ==========
    group('fromJson 反序列化', () {
      test('fromJson - 完整数据解析', () {
        // Given: 完整的 JSON 数据
        final json = {
          'id': 'semester_2025_spring',
          'name': '2025春季学期',
          'startDate': '2025-03-01T00:00:00.000Z',
          'totalWeeks': 18,
          'createdAt': '2025-01-01T10:00:00.000Z',
          'updatedAt': '2025-01-15T14:30:00.000Z',
        };

        // When: 从 JSON 创建学期设置
        final settings = SemesterSettings.fromJson(json);

        // Then: 所有字段正确解析
        expect(settings.id, equals('semester_2025_spring'));
        expect(settings.name, equals('2025春季学期'));
        expect(settings.startDate, equals(DateTime.parse('2025-03-01T00:00:00.000Z')));
        expect(settings.totalWeeks, equals(18));
        expect(settings.createdAt, equals(DateTime.parse('2025-01-01T10:00:00.000Z')));
        expect(settings.updatedAt, equals(DateTime.parse('2025-01-15T14:30:00.000Z')));
      });

      test('fromJson - 处理缺失可选字段（使用默认值）', () {
        // Given: 仅包含必需字段的 JSON
        final json = {
          'startDate': '2024-09-01T00:00:00.000Z',
          'totalWeeks': 16,
        };

        // When: 从 JSON 创建学期设置
        final settings = SemesterSettings.fromJson(json);

        // Then: 可选字段使用默认值
        expect(settings.id, startsWith('semester_')); // 自动生成的ID
        expect(settings.name, equals('未命名学期')); // 默认名称
        expect(settings.startDate, equals(DateTime.parse('2024-09-01T00:00:00.000Z')));
        expect(settings.totalWeeks, equals(16));
        expect(settings.createdAt, isNotNull); // 自动生成的时间
        expect(settings.updatedAt, isNotNull); // 自动生成的时间
      });
    });

    // ========== JSON 序列化测试 (1个) ==========
    test('toJson - 完整序列化', () {
      // Given: 完整的学期设置对象
      final settings = SemesterSettings(
        id: 'semester_test_id',
        name: '测试学期',
        startDate: DateTime(2025, 9, 1),
        totalWeeks: 20,
        createdAt: DateTime(2025, 1, 1, 8, 0),
        updatedAt: DateTime(2025, 1, 10, 15, 30),
      );

      // When: 序列化为 JSON
      final json = settings.toJson();

      // Then: 所有字段正确序列化
      expect(json['id'], equals('semester_test_id'));
      expect(json['name'], equals('测试学期'));
      expect(json['startDate'], equals('2025-09-01T00:00:00.000'));
      expect(json['totalWeeks'], equals(20));
      expect(json['createdAt'], equals('2025-01-01T08:00:00.000'));
      expect(json['updatedAt'], equals('2025-01-10T15:30:00.000'));
    });

    // ========== copyWith 方法测试 (2个) ==========
    group('copyWith 方法', () {
      test('copyWith - 修改部分字段', () {
        // Given: 原始学期设置
        final original = SemesterSettings(
          id: 'original_id',
          name: '原始学期',
          startDate: DateTime(2025, 3, 1),
          totalWeeks: 16,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        // When: 使用 copyWith 修改部分字段
        final updated = original.copyWith(
          name: '更新后学期',
          totalWeeks: 18,
        );

        // Then: 指定字段已更新，其他字段保持不变
        expect(updated.id, equals('original_id')); // 未改变
        expect(updated.name, equals('更新后学期')); // 已更新
        expect(updated.startDate, equals(DateTime(2025, 3, 1))); // 未改变
        expect(updated.totalWeeks, equals(18)); // 已更新
        expect(updated.createdAt, equals(DateTime(2025, 1, 1))); // 未改变
        expect(updated.updatedAt, equals(DateTime(2025, 1, 1))); // 未改变
      });

      test('copyWith - 不传参数时返回相同内容的新对象', () {
        // Given: 原始学期设置
        final original = SemesterSettings(
          id: 'test_id',
          name: '测试学期',
          startDate: DateTime(2025, 9, 1),
          totalWeeks: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // When: 不传参数调用 copyWith
        final copy = original.copyWith();

        // Then: 所有字段内容相同（但是不同的对象实例）
        expect(copy.id, equals(original.id));
        expect(copy.name, equals(original.name));
        expect(copy.startDate, equals(original.startDate));
        expect(copy.totalWeeks, equals(original.totalWeeks));
        expect(copy.createdAt, equals(original.createdAt));
        expect(copy.updatedAt, equals(original.updatedAt));
      });
    });

    // ========== 相等性比较测试 (2个) ==========
    group('相等性比较', () {
      test('operator == - 相同内容的对象相等', () {
        // Given: 两个内容相同的学期设置
        final settings1 = SemesterSettings(
          id: 'test_id',
          name: '测试学期',
          startDate: DateTime(2025, 9, 1),
          totalWeeks: 20,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        final settings2 = SemesterSettings(
          id: 'test_id',
          name: '测试学期',
          startDate: DateTime(2025, 9, 1),
          totalWeeks: 20,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        // When & Then: 判断为相等
        expect(settings1 == settings2, isTrue);
        expect(settings1.hashCode, equals(settings2.hashCode));
      });

      test('operator == - 不同内容的对象不相等', () {
        // Given: 两个不同内容的学期设置
        final settings1 = SemesterSettings(
          id: 'id_1',
          name: '学期1',
          startDate: DateTime(2025, 3, 1),
          totalWeeks: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final settings2 = SemesterSettings(
          id: 'id_2',
          name: '学期2',
          startDate: DateTime(2025, 9, 1),
          totalWeeks: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // When & Then: 判断为不相等
        expect(settings1 == settings2, isFalse);
      });
    });

    // ========== 双向转换测试 (1个) ==========
    test('JSON 双向转换保持数据一致性', () {
      // Given: 原始学期设置对象
      final original = SemesterSettings(
        id: 'test_semester_001',
        name: '2024秋季学期',
        startDate: DateTime(2024, 9, 1, 8, 0),
        totalWeeks: 16,
        createdAt: DateTime(2024, 6, 1, 10, 30),
        updatedAt: DateTime(2024, 8, 15, 14, 20),
      );

      // When: 序列化再反序列化
      final json = original.toJson();
      final deserialized = SemesterSettings.fromJson(json);

      // Then: 数据完全一致
      expect(deserialized.id, equals(original.id));
      expect(deserialized.name, equals(original.name));
      expect(deserialized.startDate, equals(original.startDate));
      expect(deserialized.totalWeeks, equals(original.totalWeeks));
      expect(deserialized.createdAt, equals(original.createdAt));
      expect(deserialized.updatedAt, equals(original.updatedAt));

      // 使用相等性运算符验证
      expect(deserialized, equals(original));
    });

    // ========== 工厂方法测试 (1个) ==========
    test('defaultSettings - 创建默认学期设置', () {
      // When: 创建默认设置
      final settings = SemesterSettings.defaultSettings();

      // Then: 返回预期的默认值
      expect(settings.id, startsWith('semester_'));
      expect(settings.name, equals('默认学期'));
      expect(settings.startDate, equals(DateTime(2025, 9, 1)));
      expect(settings.totalWeeks, equals(20));
      expect(settings.createdAt, isNotNull);
      expect(settings.updatedAt, isNotNull);
    });
  });
}
