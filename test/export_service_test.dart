import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curriculum/services/export_service.dart';
import 'package:curriculum/services/course_service.dart';
import 'package:curriculum/services/settings_service.dart';
import 'package:curriculum/services/time_table_service.dart';
import 'package:curriculum/services/config_version_manager.dart';
import 'package:curriculum/models/course.dart';
import 'package:curriculum/models/semester_settings.dart';
import 'package:curriculum/models/time_table.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportService Tests', () {
    setUp(() async {
      // 重置 SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    test('exportAllData should return valid JSON', () async {
      // 准备测试数据
      final testCourse = Course(
        name: '测试课程',
        location: '测试地点',
        teacher: '测试老师',
        weekday: 1,
        startSection: 1,
        duration: 2,
        color: Colors.blue,
        startWeek: 1,
        endWeek: 16,
      );

      await CourseService.saveCourses([testCourse]);

      // 导出数据
      final jsonString = await ExportService.exportAllData();

      // 验证 JSON 格式
      expect(jsonString, isNotEmpty);

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // 验证必需字段
      expect(jsonData, containsPair('version', ConfigVersionManager.currentVersion));
      expect(jsonData, contains('exportTime'));
      expect(jsonData, contains('data'));

      final data = jsonData['data'] as Map<String, dynamic>;
      expect(data, contains('courses'));
      expect(data, contains('semesters'));
      expect(data, contains('timeTables'));

      // 验证课程数据
      final courses = data['courses'] as List<dynamic>;
      expect(courses, hasLength(1));

      final exportedCourse = courses[0] as Map<String, dynamic>;
      expect(exportedCourse['name'], equals('测试课程'));
    });

    test('exportCourses should export courses only', () async {
      final testCourse = Course(
        name: '测试课程',
        location: '测试地点',
        teacher: '测试老师',
        weekday: 1,
        startSection: 1,
        duration: 2,
        color: Colors.blue,
        startWeek: 1,
        endWeek: 16,
      );

      await CourseService.saveCourses([testCourse]);

      final jsonString = await ExportService.exportCourses();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final data = jsonData['data'] as Map<String, dynamic>;
      expect(data, contains('courses'));
      expect(data, isNot(contains('semesters')));
      expect(data, isNot(contains('timeTables')));
    });

    test('importAllData should import valid data', () async {
      // 准备导入数据
      final testSemester = SemesterSettings(
        id: 'test_semester',
        name: '测试学期',
        startDate: DateTime(2025, 9, 1),
        totalWeeks: 16,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testCourse = Course(
        name: '导入测试课程',
        location: '导入测试地点',
        teacher: '导入测试老师',
        weekday: 2,
        startSection: 3,
        duration: 2,
        color: Colors.green,
        startWeek: 1,
        endWeek: 16,
        semesterId: 'test_semester',
      );

      final testTimeTable = TimeTable.defaultTimeTable();

      final exportData = {
        'version': ConfigVersionManager.currentVersion,
        'exportTime': DateTime.now().toIso8601String(),
        'data': {
          'courses': [testCourse.toJson()],
          'semesters': [testSemester.toJson()],
          'timeTables': [testTimeTable.toJson()],
          'activeSemesterId': 'test_semester',
          'activeTimeTableId': testTimeTable.id,
        },
      };

      final jsonString = jsonEncode(exportData);

      // 导入数据（覆盖模式）
      final result = await ExportService.importAllData(jsonString, merge: false);

      // 验证导入结果
      expect(result.success, isTrue);
      expect(result.coursesImported, equals(1));
      expect(result.semestersImported, equals(1));
      expect(result.timeTablesImported, equals(1));

      // 验证数据已保存
      final courses = await CourseService.loadAllCourses();
      expect(courses, hasLength(1));
      expect(courses[0].name, equals('导入测试课程'));

      final semesters = await SettingsService.getAllSemesters();
      expect(semesters.length, greaterThanOrEqualTo(1));
      expect(semesters.any((s) => s.name == '测试学期'), isTrue);
    });

    test('importAllData should validate data format', () async {
      // 测试无效的数据格式
      final invalidJsonString = '{"invalid": "data"}';

      final result = await ExportService.importAllData(invalidJsonString);

      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('importAllData merge mode should preserve existing data', () async {
      // 先保存一个课程
      final existingCourse = Course(
        name: '现有课程',
        location: '现有地点',
        teacher: '现有老师',
        weekday: 1,
        startSection: 1,
        duration: 2,
        color: Colors.red,
        startWeek: 1,
        endWeek: 16,
      );

      await CourseService.saveCourses([existingCourse]);

      // 导入新课程（合并模式）
      final newCourse = Course(
        name: '新导入课程',
        location: '新地点',
        teacher: '新老师',
        weekday: 2,
        startSection: 1,
        duration: 2,
        color: Colors.blue,
        startWeek: 1,
        endWeek: 16,
      );

      final exportData = {
        'version': ConfigVersionManager.currentVersion,
        'exportTime': DateTime.now().toIso8601String(),
        'data': {
          'courses': [newCourse.toJson()],
        },
      };

      final jsonString = jsonEncode(exportData);

      await ExportService.importAllData(jsonString, merge: true);

      // 验证两个课程都存在
      final courses = await CourseService.loadAllCourses();
      expect(courses, hasLength(2));

      final courseNames = courses.map((c) => c.name).toList();
      expect(courseNames, contains('现有课程'));
      expect(courseNames, contains('新导入课程'));
    });

    test('ImportResult getSummary should return correct message', () {
      final result1 = ImportResult(
        success: true,
        coursesImported: 5,
        semestersImported: 2,
        timeTablesImported: 1,
      );

      expect(result1.getSummary(), contains('5 门课程'));
      expect(result1.getSummary(), contains('2 个学期'));
      expect(result1.getSummary(), contains('1 个时间表'));

      final result2 = ImportResult(
        success: false,
        error: '测试错误',
      );

      expect(result2.getSummary(), contains('导入失败'));
      expect(result2.getSummary(), contains('测试错误'));

      final result3 = ImportResult(success: true);
      expect(result3.getSummary(), equals('未导入任何数据'));
    });

    // ========== 版本管理测试 (5个新用例) ==========
    test('importAllData should upgrade from 1.0.0 to 1.1.0', () async {
      // Given: 旧版本 (1.0.0) 的导出数据
      final oldVersionData = {
        'version': '1.0.0',
        'exportTime': DateTime.now().toIso8601String(),
        'data': {
          'courses': [
            {
              'name': '旧版课程',
              'location': '地点',
              'teacher': '老师',
              'weekday': 1,
              'startSection': 1,
              'duration': 2,
              'color': '#FF0000',
              'startWeek': 1,
              'endWeek': 16,
              // 1.0.0 版本没有 semesterId 和 isHidden
            }
          ],
        },
      };

      final jsonString = jsonEncode(oldVersionData);

      // When: 导入旧版本数据
      final result = await ExportService.importAllData(jsonString, merge: false);

      // Then: 导入成功，数据已升级
      expect(result.success, isTrue);
      expect(result.coursesImported, equals(1));

      // 验证升级后的数据包含新字段
      final courses = await CourseService.loadAllCourses();
      expect(courses, hasLength(1));
      expect(courses[0].name, equals('旧版课程'));
      expect(courses[0].semesterId, isNull); // 默认值
      expect(courses[0].isHidden, isFalse); // 默认值
    });

    test('importAllData should handle invalid version format', () async {
      // Given: 无效版本号的数据
      final invalidVersionData = {
        'version': 'invalid.version.format',
        'exportTime': DateTime.now().toIso8601String(),
        'data': {
          'courses': [],
        },
      };

      final jsonString = jsonEncode(invalidVersionData);

      // When: 尝试导入
      final result = await ExportService.importAllData(jsonString);

      // Then: 导入失败，错误信息包含版本相关提示
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('version upgrade should preserve existing data integrity', () async {
      // Given: 旧版本数据包含多个课程
      final oldVersionData = {
        'version': '1.0.0',
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
        },
      };

      final jsonString = jsonEncode(oldVersionData);

      // When: 导入并升级
      final result = await ExportService.importAllData(jsonString, merge: false);

      // Then: 所有课程都正确升级
      expect(result.success, isTrue);
      expect(result.coursesImported, equals(2));

      final courses = await CourseService.loadAllCourses();
      expect(courses, hasLength(2));

      // 验证原有字段完整性
      expect(courses[0].name, equals('课程1'));
      expect(courses[0].location, equals('地点1'));
      expect(courses[0].teacher, equals('老师1'));
      expect(courses[1].name, equals('课程2'));
      expect(courses[1].location, equals('地点2'));
      expect(courses[1].teacher, equals('老师2'));
    });

    test('exportSemesters should export semesters only', () async {
      // Given: 保存一些学期数据
      final semester1 = SemesterSettings(
        id: 'semester_1',
        name: '2024秋季学期',
        startDate: DateTime(2024, 9, 1),
        totalWeeks: 16,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final semester2 = SemesterSettings(
        id: 'semester_2',
        name: '2025春季学期',
        startDate: DateTime(2025, 3, 1),
        totalWeeks: 18,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await SettingsService.addSemester(semester1);
      await SettingsService.addSemester(semester2);

      // When: 仅导出学期数据
      final jsonString = await ExportService.exportSemesters();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Then: 只包含学期数据，不包含课程和时间表
      final data = jsonData['data'] as Map<String, dynamic>;
      expect(data, contains('semesters'));
      expect(data, isNot(contains('courses')));
      expect(data, isNot(contains('timeTables')));

      // 验证学期数据完整
      final semesters = data['semesters'] as List<dynamic>;
      expect(semesters.length, greaterThanOrEqualTo(2));

      final semesterNames = semesters
          .map((s) => (s as Map<String, dynamic>)['name'] as String)
          .toList();
      expect(semesterNames, contains('2024秋季学期'));
      expect(semesterNames, contains('2025春季学期'));
    });

    test('exportTimeTables should export time tables only', () async {
      // Given: 获取或创建时间表
      final activeTimeTable = await TimeTableService.getActiveTimeTable();

      // When: 仅导出时间表数据
      final jsonString = await ExportService.exportTimeTables();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Then: 只包含时间表数据，不包含课程和学期
      final data = jsonData['data'] as Map<String, dynamic>;
      expect(data, contains('timeTables'));
      expect(data, isNot(contains('courses')));
      expect(data, isNot(contains('semesters')));

      // 验证时间表数据完整
      final timeTables = data['timeTables'] as List<dynamic>;
      expect(timeTables, hasLength(greaterThanOrEqualTo(1)));

      final firstTimeTable = timeTables[0] as Map<String, dynamic>;
      expect(firstTimeTable, contains('id'));
      expect(firstTimeTable, contains('name'));
      expect(firstTimeTable, contains('sections'));

      // 验证节次数据结构
      final sections = firstTimeTable['sections'] as List<dynamic>;
      expect(sections, isNotEmpty);

      final firstSection = sections[0] as Map<String, dynamic>;
      expect(firstSection, contains('section'));
      expect(firstSection, contains('startTime'));
      expect(firstSection, contains('endTime'));
    });
  });
}
