import 'package:flutter_test/flutter_test.dart';
import 'package:curriculum/models/time_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SectionTime Model Tests', () {
    // ========== SectionTime 序列化测试 (2个) ==========
    test('SectionTime fromJson/toJson - 双向转换', () {
      // Given: SectionTime JSON 数据
      final json = {
        'section': 1,
        'startTime': '08:00',
        'endTime': '08:45',
      };

      // When: 反序列化
      final sectionTime = SectionTime.fromJson(json);

      // Then: 字段正确解析
      expect(sectionTime.section, equals(1));
      expect(sectionTime.startTime, equals('08:00'));
      expect(sectionTime.endTime, equals('08:45'));

      // When: 再序列化
      final serialized = sectionTime.toJson();

      // Then: 数据一致
      expect(serialized, equals(json));
    });

    test('SectionTime copyWith - 修改部分字段', () {
      // Given: 原始 SectionTime
      const original = SectionTime(
        section: 1,
        startTime: '08:00',
        endTime: '08:45',
      );

      // When: 修改时间
      final updated = original.copyWith(
        startTime: '08:10',
        endTime: '08:55',
      );

      // Then: 部分字段更新
      expect(updated.section, equals(1)); // 未改变
      expect(updated.startTime, equals('08:10')); // 已更新
      expect(updated.endTime, equals('08:55')); // 已更新
    });
  });

  group('TimeTable Model Serialization Tests', () {
    // ========== JSON 反序列化测试 (1个) ==========
    test('TimeTable fromJson - 完整数据解析', () {
      // Given: 完整的时间表 JSON 数据
      final json = {
        'id': 'custom_timetable',
        'name': '自定义时间表',
        'sections': [
          {'section': 1, 'startTime': '08:00', 'endTime': '08:50'},
          {'section': 2, 'startTime': '09:00', 'endTime': '09:50'},
          {'section': 3, 'startTime': '10:00', 'endTime': '10:50'},
        ],
        'createdAt': '2025-01-01T10:00:00.000Z',
        'updatedAt': '2025-01-15T14:30:00.000Z',
      };

      // When: 从 JSON 创建时间表
      final timeTable = TimeTable.fromJson(json);

      // Then: 所有字段正确解析
      expect(timeTable.id, equals('custom_timetable'));
      expect(timeTable.name, equals('自定义时间表'));
      expect(timeTable.sections.length, equals(3));
      expect(timeTable.sections[0].section, equals(1));
      expect(timeTable.sections[0].startTime, equals('08:00'));
      expect(timeTable.sections[0].endTime, equals('08:50'));
      expect(timeTable.createdAt, equals(DateTime.parse('2025-01-01T10:00:00.000Z')));
      expect(timeTable.updatedAt, equals(DateTime.parse('2025-01-15T14:30:00.000Z')));
    });

    // ========== JSON 序列化测试 (1个) ==========
    test('TimeTable toJson - 完整序列化', () {
      // Given: 完整的时间表对象
      final timeTable = TimeTable(
        id: 'test_timetable',
        name: '测试时间表',
        sections: const [
          SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          SectionTime(section: 2, startTime: '08:55', endTime: '09:40'),
        ],
        createdAt: DateTime(2025, 1, 1, 8, 0),
        updatedAt: DateTime(2025, 1, 10, 15, 30),
      );

      // When: 序列化为 JSON
      final json = timeTable.toJson();

      // Then: 所有字段正确序列化
      expect(json['id'], equals('test_timetable'));
      expect(json['name'], equals('测试时间表'));
      expect(json['sections'], isList);
      expect((json['sections'] as List).length, equals(2));
      expect(json['createdAt'], equals('2025-01-01T08:00:00.000'));
      expect(json['updatedAt'], equals('2025-01-10T15:30:00.000'));

      // 验证节次数据
      final sections = json['sections'] as List;
      expect(sections[0]['section'], equals(1));
      expect(sections[0]['startTime'], equals('08:00'));
      expect(sections[0]['endTime'], equals('08:45'));
    });

    // ========== 工厂方法测试 (1个) ==========
    test('TimeTable.defaultTimeTable - 创建默认时间表', () {
      // When: 创建默认时间表
      final timeTable = TimeTable.defaultTimeTable();

      // Then: 返回预期的默认值
      expect(timeTable.id, equals('default'));
      expect(timeTable.name, equals('默认时间表'));
      expect(timeTable.sections.length, equals(10)); // 10个节次
      expect(timeTable.sections[0].section, equals(1));
      expect(timeTable.sections[0].startTime, equals('08:00'));
      expect(timeTable.sections[0].endTime, equals('08:45'));
      expect(timeTable.sections[9].section, equals(10));
      expect(timeTable.sections[9].startTime, equals('20:55'));
      expect(timeTable.sections[9].endTime, equals('21:40'));
      expect(timeTable.createdAt, isNotNull);
      expect(timeTable.updatedAt, isNotNull);
    });

    // ========== getSectionTime 方法测试 (2个) ==========
    group('getSectionTime 方法', () {
      test('getSectionTime - 返回有效节次的时间', () {
        // Given: 默认时间表
        final timeTable = TimeTable.defaultTimeTable();

        // When: 获取第1节和第5节的时间
        final section1 = timeTable.getSectionTime(1);
        final section5 = timeTable.getSectionTime(5);

        // Then: 返回正确的时间信息
        expect(section1, isNotNull);
        expect(section1!.startTime, equals('08:00'));
        expect(section1.endTime, equals('08:45'));

        expect(section5, isNotNull);
        expect(section5!.startTime, equals('15:00'));
        expect(section5.endTime, equals('15:45'));
      });

      test('getSectionTime - 无效节次返回 null', () {
        // Given: 默认时间表
        final timeTable = TimeTable.defaultTimeTable();

        // When: 获取无效节次（<1 或 >10）
        final section0 = timeTable.getSectionTime(0);
        final section11 = timeTable.getSectionTime(11);

        // Then: 返回 null
        expect(section0, isNull);
        expect(section11, isNull);
      });
    });

    // ========== isValid 验证测试 (2个) ==========
    group('isValid 验证', () {
      test('isValid - 有效的时间表', () {
        // Given: 节次编号连续的时间表
        final timeTable = TimeTable(
          id: 'valid_table',
          name: '有效时间表',
          sections: const [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
            SectionTime(section: 2, startTime: '08:55', endTime: '09:40'),
            SectionTime(section: 3, startTime: '10:00', endTime: '10:45'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // When & Then: 验证为有效
        expect(timeTable.isValid, isTrue);
      });

      test('isValid - 无效的时间表（节次不连续或为空）', () {
        // Given: 节次编号不连续的时间表
        final invalidTable = TimeTable(
          id: 'invalid_table',
          name: '无效时间表',
          sections: const [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
            SectionTime(section: 3, startTime: '10:00', endTime: '10:45'), // 跳过了2
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // When & Then: 验证为无效
        expect(invalidTable.isValid, isFalse);

        // Given: 空节次列表
        final emptyTable = TimeTable(
          id: 'empty_table',
          name: '空时间表',
          sections: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // When & Then: 验证为无效
        expect(emptyTable.isValid, isFalse);
      });
    });

    // ========== copyWith 方法测试 (1个) ==========
    test('TimeTable copyWith - 修改部分字段', () {
      // Given: 原始时间表
      final original = TimeTable(
        id: 'original_id',
        name: '原始时间表',
        sections: const [
          SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
        ],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      // When: 修改名称
      final updated = original.copyWith(name: '更新后时间表');

      // Then: 指定字段已更新，其他字段保持不变
      expect(updated.id, equals('original_id')); // 未改变
      expect(updated.name, equals('更新后时间表')); // 已更新
      expect(updated.sections.length, equals(1)); // 未改变
      expect(updated.createdAt, equals(DateTime(2025, 1, 1))); // 未改变
    });

    // ========== 相等性比较测试 (1个) ==========
    test('TimeTable 相等性比较', () {
      // Given: 两个内容相同的时间表
      final timeTable1 = TimeTable(
        id: 'test_id',
        name: '测试时间表',
        sections: const [
          SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          SectionTime(section: 2, startTime: '08:55', endTime: '09:40'),
        ],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      final timeTable2 = TimeTable(
        id: 'test_id',
        name: '测试时间表',
        sections: const [
          SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          SectionTime(section: 2, startTime: '08:55', endTime: '09:40'),
        ],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      // When & Then: 判断为相等
      expect(timeTable1 == timeTable2, isTrue);
      expect(timeTable1.hashCode, equals(timeTable2.hashCode));
    });

    // ========== 双向转换测试 (1个) ==========
    test('TimeTable JSON 双向转换保持数据一致性', () {
      // Given: 原始时间表对象
      final original = TimeTable(
        id: 'test_table_001',
        name: '2025年春季时间表',
        sections: const [
          SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          SectionTime(section: 2, startTime: '08:55', endTime: '09:40'),
          SectionTime(section: 3, startTime: '10:10', endTime: '10:55'),
        ],
        createdAt: DateTime(2025, 1, 1, 8, 0),
        updatedAt: DateTime(2025, 1, 10, 15, 30),
      );

      // When: 序列化再反序列化
      final json = original.toJson();
      final deserialized = TimeTable.fromJson(json);

      // Then: 数据完全一致
      expect(deserialized.id, equals(original.id));
      expect(deserialized.name, equals(original.name));
      expect(deserialized.sections.length, equals(original.sections.length));
      expect(deserialized.createdAt, equals(original.createdAt));
      expect(deserialized.updatedAt, equals(original.updatedAt));

      // 验证节次数据
      for (int i = 0; i < original.sections.length; i++) {
        expect(deserialized.sections[i], equals(original.sections[i]));
      }

      // 使用相等性运算符验证
      expect(deserialized, equals(original));
    });
  });
}
