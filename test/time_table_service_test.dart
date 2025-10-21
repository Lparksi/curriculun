import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curriculum/services/time_table_service.dart';
import 'package:curriculum/models/time_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimeTableService', () {
    setUp(() async {
      // 重置 SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    // ========== 时间表管理测试 (7个) ==========
    group('时间表管理', () {
      test('loadTimeTables - 首次加载返回默认时间表', () async {
        // Given: 空的本地存储
        SharedPreferences.setMockInitialValues({});

        // When: 加载时间表
        final timeTables = await TimeTableService.loadTimeTables();

        // Then: 返回包含默认时间表的列表
        expect(timeTables, hasLength(1));
        expect(timeTables[0].id, equals('default'));
        expect(timeTables[0].name, equals('默认时间表'));
      });

      test('loadTimeTables - 加载已保存的时间表列表', () async {
        // Given: 已保存的时间表数据
        final timeTable1 = TimeTable(
          id: 'test_table_1',
          name: '高中时间表',
          sections: [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
            SectionTime(section: 2, startTime: '08:55', endTime: '09:40'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final timeTable2 = TimeTable(
          id: 'test_table_2',
          name: '大学时间表',
          sections: [
            SectionTime(section: 1, startTime: '08:30', endTime: '09:15'),
            SectionTime(section: 2, startTime: '09:25', endTime: '10:10'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await TimeTableService.saveTimeTables([timeTable1, timeTable2]);

        // When: 重新加载
        final timeTables = await TimeTableService.loadTimeTables();

        // Then: 正确加载所有时间表
        expect(timeTables, hasLength(2));
        expect(
          timeTables.any((t) => t.name == '高中时间表'),
          isTrue,
        );
        expect(
          timeTables.any((t) => t.name == '大学时间表'),
          isTrue,
        );
      });

      test('saveTimeTables - 成功保存时间表', () async {
        // Given: 测试时间表
        final timeTable = TimeTable(
          id: 'test_table',
          name: '测试时间表',
          sections: [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // When: 保存时间表
        await TimeTableService.saveTimeTables([timeTable]);

        // Then: 能从 SharedPreferences 读取
        final prefs = await SharedPreferences.getInstance();
        final savedJson = prefs.getString('time_tables');
        expect(savedJson, isNotNull);
        expect(savedJson, contains('测试时间表'));
      });

      test('addTimeTable - 成功添加新时间表', () async {
        // Given: 空的时间表列表
        SharedPreferences.setMockInitialValues({});

        final newTimeTable = TimeTable(
          id: 'new_table',
          name: '新时间表',
          sections: [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // When: 添加新时间表
        await TimeTableService.addTimeTable(newTimeTable);

        // Then: 时间表已保存
        final timeTables = await TimeTableService.loadTimeTables();
        expect(
          timeTables.any((t) => t.name == '新时间表'),
          isTrue,
        );
      });

      test('addTimeTable - ID重复时抛出异常', () async {
        // Given: 已有时间表
        final existingTable = TimeTable(
          id: 'duplicate_id',
          name: '已存在时间表',
          sections: [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await TimeTableService.addTimeTable(existingTable);

        // When & Then: 添加相同ID的时间表时抛出异常
        final duplicateTable = TimeTable(
          id: 'duplicate_id',
          name: '重复ID时间表',
          sections: [
            SectionTime(section: 1, startTime: '09:00', endTime: '09:45'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          () => TimeTableService.addTimeTable(duplicateTable),
          throwsException,
        );
      });

      test('updateTimeTable - 更新时间表', () async {
        // Given: 已有时间表
        final originalTable = TimeTable(
          id: 'test_table',
          name: '原始时间表',
          sections: [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await TimeTableService.addTimeTable(originalTable);

        // When: 更新时间表
        final updatedTable = originalTable.copyWith(
          name: '更新后时间表',
          sections: [
            SectionTime(section: 1, startTime: '08:30', endTime: '09:15'),
            SectionTime(section: 2, startTime: '09:25', endTime: '10:10'),
          ],
        );

        await TimeTableService.updateTimeTable(updatedTable);

        // Then: 时间表已更新
        final timeTables = await TimeTableService.loadTimeTables();
        final found = timeTables.firstWhere((t) => t.id == 'test_table');
        expect(found.name, equals('更新后时间表'));
        expect(found.sections, hasLength(2));
      });

      test('deleteTimeTable - 删除时间表', () async {
        // Given: 多个时间表
        final table1 = TimeTable(
          id: 'table_1',
          name: '时间表1',
          sections: [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final table2 = TimeTable(
          id: 'table_2',
          name: '时间表2',
          sections: [
            SectionTime(section: 1, startTime: '08:30', endTime: '09:15'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await TimeTableService.saveTimeTables([table1, table2]);

        // When: 删除第一个时间表
        await TimeTableService.deleteTimeTable('table_1');

        // Then: 时间表已删除
        final timeTables = await TimeTableService.loadTimeTables();
        expect(
          timeTables.any((t) => t.id == 'table_1'),
          isFalse,
        );
        expect(
          timeTables.any((t) => t.id == 'table_2'),
          isTrue,
        );
      });
    });

    // ========== 激活时间表测试 (3个) ==========
    group('激活时间表', () {
      test('getActiveTimeTable - 返回当前激活的时间表', () async {
        // Given: 多个时间表，设置其中一个为激活
        final table1 = TimeTable(
          id: 'table_1',
          name: '时间表1',
          sections: [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final table2 = TimeTable(
          id: 'table_2',
          name: '时间表2',
          sections: [
            SectionTime(section: 1, startTime: '08:30', endTime: '09:15'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await TimeTableService.saveTimeTables([table1, table2]);
        await TimeTableService.setActiveTimeTableId('table_2');

        // When: 获取激活时间表
        final activeTable = await TimeTableService.getActiveTimeTable();

        // Then: 返回正确的激活时间表
        expect(activeTable.id, equals('table_2'));
        expect(activeTable.name, equals('时间表2'));
      });

      test('setActiveTimeTableId - 设置激活时间表', () async {
        // Given: 已有时间表
        final timeTable = TimeTable(
          id: 'test_table',
          name: '测试时间表',
          sections: [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await TimeTableService.addTimeTable(timeTable);

        // When: 设置激活时间表
        await TimeTableService.setActiveTimeTableId('test_table');

        // Then: 激活时间表已设置
        final activeId = await TimeTableService.getActiveTimeTableId();
        expect(activeId, equals('test_table'));
      });

      test('deleteTimeTable - 删除激活时间表时自动切换', () async {
        // Given: 多个时间表，第一个是激活的
        final table1 = TimeTable(
          id: 'table_1',
          name: '时间表1',
          sections: [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final table2 = TimeTable(
          id: 'default', // 使用 default 作为后备
          name: '默认时间表',
          sections: [
            SectionTime(section: 1, startTime: '08:30', endTime: '09:15'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await TimeTableService.saveTimeTables([table1, table2]);
        await TimeTableService.setActiveTimeTableId('table_1');

        // When: 删除激活时间表
        await TimeTableService.deleteTimeTable('table_1');

        // Then: 自动切换到默认时间表
        final activeId = await TimeTableService.getActiveTimeTableId();
        expect(activeId, equals('default'));
      });
    });

    // ========== 时间验证测试 (4个) 🔥 关键算法 ==========
    group('时间验证', () {
      test('isValidTimeFormat - 有效的时间格式 (HH:mm)', () {
        // Given: 各种有效的时间格式
        final validTimes = [
          '00:00',
          '08:00',
          '12:30',
          '23:59',
          '09:05',
        ];

        // When & Then: 所有格式都应该有效
        for (final time in validTimes) {
          expect(
            TimeTableService.isValidTimeFormat(time),
            isTrue,
            reason: '$time 应该是有效的时间格式',
          );
        }
      });

      test('isValidTimeFormat - 无效的时间格式', () {
        // Given: 各种无效的时间格式
        final invalidTimes = [
          '24:00', // 小时超出范围
          '12:60', // 分钟超出范围
          '8:00', // 小时缺少前导零
          '08:5', // 分钟缺少前导零
          '08-00', // 错误的分隔符
          '08:00:00', // 包含秒
          'abc', // 无效字符
          '', // 空字符串
        ];

        // When & Then: 所有格式都应该无效
        for (final time in invalidTimes) {
          expect(
            TimeTableService.isValidTimeFormat(time),
            isFalse,
            reason: '$time 应该是无效的时间格式',
          );
        }
      });

      test('isTimeRangeValid - 开始时间早于结束时间', () {
        // Given: 有效的时间范围
        final validRanges = [
          {'start': '08:00', 'end': '08:45'},
          {'start': '09:00', 'end': '10:00'},
          {'start': '00:00', 'end': '23:59'},
          {'start': '12:00', 'end': '12:01'},
        ];

        // When & Then: 所有范围都应该有效
        for (final range in validRanges) {
          expect(
            TimeTableService.isTimeRangeValid(
              range['start']!,
              range['end']!,
            ),
            isTrue,
            reason:
                '${range['start']} - ${range['end']} 应该是有效的时间范围',
          );
        }
      });

      test('isTimeRangeValid - 开始时间晚于或等于结束时间', () {
        // Given: 无效的时间范围
        final invalidRanges = [
          {'start': '08:45', 'end': '08:00'}, // 开始晚于结束
          {'start': '12:00', 'end': '12:00'}, // 相同时间
          {'start': '23:59', 'end': '00:00'}, // 开始晚于结束
          {'start': 'invalid', 'end': '08:00'}, // 无效格式
          {'start': '08:00', 'end': 'invalid'}, // 无效格式
        ];

        // When & Then: 所有范围都应该无效
        for (final range in invalidRanges) {
          expect(
            TimeTableService.isTimeRangeValid(
              range['start']!,
              range['end']!,
            ),
            isFalse,
            reason:
                '${range['start']} - ${range['end']} 应该是无效的时间范围',
          );
        }
      });
    });

    // ========== 其他功能测试 ==========
    group('其他功能', () {
      test('duplicateTimeTable - 成功复制时间表', () async {
        // Given: 已有时间表
        final sourceTable = TimeTable(
          id: 'source_table',
          name: '源时间表',
          sections: [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
            SectionTime(section: 2, startTime: '08:55', endTime: '09:40'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await TimeTableService.addTimeTable(sourceTable);

        // When: 复制时间表
        final duplicated =
            await TimeTableService.duplicateTimeTable('source_table');

        // Then: 复制成功
        expect(duplicated.name, equals('源时间表 (副本)'));
        expect(duplicated.sections, hasLength(2));
        expect(duplicated.id, isNot(equals('source_table')));

        // 两个时间表都存在
        final timeTables = await TimeTableService.loadTimeTables();
        expect(
          timeTables.any((t) => t.id == 'source_table'),
          isTrue,
        );
        expect(
          timeTables.any((t) => t.id == duplicated.id),
          isTrue,
        );
      });

      test('duplicateTimeTable - 源时间表不存在时抛出异常', () async {
        // Given: 不存在的时间表ID
        SharedPreferences.setMockInitialValues({});

        // When & Then: 抛出异常
        expect(
          () => TimeTableService.duplicateTimeTable('non_existent_table'),
          throwsException,
        );
      });

      test('generateTimeTableId - 生成唯一ID', () async {
        // When: 生成多个ID（添加延迟确保时间戳不同）
        final id1 = TimeTableService.generateTimeTableId();
        await Future.delayed(const Duration(milliseconds: 10));
        final id2 = TimeTableService.generateTimeTableId();

        // Then: ID不同
        expect(id1, isNot(equals(id2)));
        expect(id1, startsWith('timetable_'));
        expect(id2, startsWith('timetable_'));
      });

      test('deleteTimeTable - 不允许删除默认时间表', () async {
        // Given: 包含默认时间表的列表
        final defaultTable = TimeTable.defaultTimeTable();
        final customTable = TimeTable(
          id: 'custom',
          name: '自定义时间表',
          sections: [
            SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await TimeTableService.saveTimeTables([defaultTable, customTable]);

        // When & Then: 尝试删除默认时间表时抛出异常
        expect(
          () => TimeTableService.deleteTimeTable('default'),
          throwsException,
        );
      });

      test('deleteTimeTable - 至少保留一个时间表', () async {
        // Given: 只有一个时间表
        SharedPreferences.setMockInitialValues({});
        final timeTables = await TimeTableService.loadTimeTables();
        expect(timeTables, hasLength(1));

        final onlyTableId = timeTables[0].id;

        // When & Then: 尝试删除唯一的时间表时抛出异常
        expect(
          () => TimeTableService.deleteTimeTable(onlyTableId),
          throwsException,
        );
      });
    });
  });
}
