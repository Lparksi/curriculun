import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curriculum/services/export_service.dart';
import 'package:curriculum/services/course_service.dart';
import 'package:curriculum/services/settings_service.dart';
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
  });
}
