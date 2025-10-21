import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curriculum/services/course_service.dart';
import 'package:curriculum/models/course.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CourseService', () {
    setUp(() async {
      // 重置 SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    // ========== 数据加载测试 (5个) ==========
    group('数据加载', () {
      test('loadAllCourses - 首次加载返回空列表', () async {
        // Given: 空的本地存储
        SharedPreferences.setMockInitialValues({});

        // When: 加载课程
        final courses = await CourseService.loadAllCourses();

        // Then: 返回空列表
        expect(courses, isEmpty);
      });

      test('loadAllCourses - 从本地存储加载已保存课程', () async {
        // Given: 已保存的课程数据
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

        // When: 重新加载课程
        final courses = await CourseService.loadAllCourses();

        // Then: 成功加载
        expect(courses, hasLength(1));
        expect(courses[0].name, equals('测试课程'));
        expect(courses[0].location, equals('测试地点'));
        expect(courses[0].weekday, equals(1));
      });

      test('loadAllCourses - 加载失败返回空列表', () async {
        // Given: 无效的 JSON 数据
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_courses', 'invalid json');

        // When: 尝试加载
        final courses = await CourseService.loadAllCourses();

        // Then: 返回空列表而不崩溃
        expect(courses, isEmpty);
      });

      test('loadCoursesBySemester - 按学期筛选课程', () async {
        // Given: 不同学期的课程
        final course1 = Course(
          name: '学期1课程',
          location: '地点1',
          teacher: '老师1',
          weekday: 1,
          startSection: 1,
          duration: 2,
          color: Colors.blue,
          startWeek: 1,
          endWeek: 16,
          semesterId: 'semester_1',
        );

        final course2 = Course(
          name: '学期2课程',
          location: '地点2',
          teacher: '老师2',
          weekday: 2,
          startSection: 1,
          duration: 2,
          color: Colors.red,
          startWeek: 1,
          endWeek: 16,
          semesterId: 'semester_2',
        );

        final course3 = Course(
          name: '无学期课程',
          location: '地点3',
          teacher: '老师3',
          weekday: 3,
          startSection: 1,
          duration: 2,
          color: Colors.green,
          startWeek: 1,
          endWeek: 16,
          // semesterId 为 null
        );

        await CourseService.saveCourses([course1, course2, course3]);

        // When: 按学期筛选
        final semester1Courses =
            await CourseService.loadCoursesBySemester('semester_1');
        final semester2Courses =
            await CourseService.loadCoursesBySemester('semester_2');
        final noSemesterCourses =
            await CourseService.loadCoursesBySemester(null);

        // Then: 正确筛选
        expect(semester1Courses, hasLength(1));
        expect(semester1Courses[0].name, equals('学期1课程'));

        expect(semester2Courses, hasLength(1));
        expect(semester2Courses[0].name, equals('学期2课程'));

        expect(noSemesterCourses, hasLength(1));
        expect(noSemesterCourses[0].name, equals('无学期课程'));
      });

      test('loadCoursesFromAssets - 从assets加载课程（模拟）', () async {
        // Note: 实际的 assets 加载需要在 widget test 中测试
        // 这里仅测试错误处理逻辑

        // When: 尝试加载不存在的文件
        final courses = await CourseService.loadCoursesFromAssets(
          assetPath: 'non_existent.json',
        );

        // Then: 返回空列表
        expect(courses, isEmpty);
      });
    });

    // ========== 数据保存测试 (3个) ==========
    group('数据保存', () {
      test('saveCourses - 成功保存课程到本地', () async {
        // Given: 测试课程
        final testCourse = Course(
          name: '保存测试',
          location: '地点',
          teacher: '老师',
          weekday: 1,
          startSection: 1,
          duration: 2,
          color: Colors.blue,
          startWeek: 1,
          endWeek: 16,
        );

        // When: 保存课程
        await CourseService.saveCourses([testCourse]);

        // Then: 能从 SharedPreferences 读取
        final prefs = await SharedPreferences.getInstance();
        final savedJson = prefs.getString('saved_courses');
        expect(savedJson, isNotNull);
        expect(savedJson, contains('保存测试'));
      });

      test('saveCourses - 保存后能正确读取', () async {
        // Given: 多个课程
        final courses = [
          Course(
            name: '课程1',
            location: '地点1',
            teacher: '老师1',
            weekday: 1,
            startSection: 1,
            duration: 2,
            color: Colors.blue,
            startWeek: 1,
            endWeek: 16,
          ),
          Course(
            name: '课程2',
            location: '地点2',
            teacher: '老师2',
            weekday: 2,
            startSection: 3,
            duration: 1,
            color: Colors.red,
            startWeek: 1,
            endWeek: 16,
          ),
        ];

        // When: 保存并重新加载
        await CourseService.saveCourses(courses);
        final loadedCourses = await CourseService.loadAllCourses();

        // Then: 数据一致
        expect(loadedCourses, hasLength(2));
        expect(loadedCourses[0].name, equals('课程1'));
        expect(loadedCourses[1].name, equals('课程2'));
      });

      test('exportCoursesToJson - 导出为格式化JSON', () {
        // Given: 测试课程
        final courses = [
          Course(
            name: '导出测试',
            location: '地点',
            teacher: '老师',
            weekday: 1,
            startSection: 1,
            duration: 2,
            color: Colors.blue,
            startWeek: 1,
            endWeek: 16,
          ),
        ];

        // When: 导出为 JSON
        final jsonString = CourseService.exportCoursesToJson(courses);

        // Then: JSON 格式正确
        expect(jsonString, isNotEmpty);
        expect(jsonString, contains('"courses"'));
        expect(jsonString, contains('导出测试'));
      });
    });

    // ========== CRUD操作测试 (4个) ==========
    group('CRUD操作', () {
      test('addCourse - 成功添加课程', () async {
        // Given: 空的课程列表
        SharedPreferences.setMockInitialValues({});

        final newCourse = Course(
          name: '新课程',
          location: '新地点',
          teacher: '新老师',
          weekday: 1,
          startSection: 1,
          duration: 2,
          color: Colors.blue,
          startWeek: 1,
          endWeek: 16,
        );

        // When: 添加课程
        await CourseService.addCourse(newCourse);

        // Then: 课程已保存
        final courses = await CourseService.loadAllCourses();
        expect(courses, hasLength(1));
        expect(courses[0].name, equals('新课程'));
      });

      test('updateCourse - 更新指定索引的课程', () async {
        // Given: 已有课程
        final originalCourse = Course(
          name: '原始课程',
          location: '原始地点',
          teacher: '原始老师',
          weekday: 1,
          startSection: 1,
          duration: 2,
          color: Colors.blue,
          startWeek: 1,
          endWeek: 16,
        );

        await CourseService.saveCourses([originalCourse]);

        // When: 更新课程
        final updatedCourse = Course(
          name: '更新后课程',
          location: '更新后地点',
          teacher: '更新后老师',
          weekday: 2,
          startSection: 3,
          duration: 1,
          color: Colors.red,
          startWeek: 1,
          endWeek: 16,
        );

        await CourseService.updateCourse(0, updatedCourse);

        // Then: 课程已更新
        final courses = await CourseService.loadAllCourses();
        expect(courses, hasLength(1));
        expect(courses[0].name, equals('更新后课程'));
        expect(courses[0].weekday, equals(2));
      });

      test('deleteCourse - 删除指定索引的课程', () async {
        // Given: 多个课程
        final courses = [
          Course(
            name: '课程1',
            location: '地点1',
            teacher: '老师1',
            weekday: 1,
            startSection: 1,
            duration: 2,
            color: Colors.blue,
            startWeek: 1,
            endWeek: 16,
          ),
          Course(
            name: '课程2',
            location: '地点2',
            teacher: '老师2',
            weekday: 2,
            startSection: 1,
            duration: 2,
            color: Colors.red,
            startWeek: 1,
            endWeek: 16,
          ),
        ];

        await CourseService.saveCourses(courses);

        // When: 删除第一个课程
        await CourseService.deleteCourse(0);

        // Then: 只剩下第二个课程
        final remainingCourses = await CourseService.loadAllCourses();
        expect(remainingCourses, hasLength(1));
        expect(remainingCourses[0].name, equals('课程2'));
      });

      test('resetToDefault - 重置清空数据', () async {
        // Given: 已有课程数据
        final testCourse = Course(
          name: '测试课程',
          location: '地点',
          teacher: '老师',
          weekday: 1,
          startSection: 1,
          duration: 2,
          color: Colors.blue,
          startWeek: 1,
          endWeek: 16,
        );

        await CourseService.saveCourses([testCourse]);

        // When: 重置
        await CourseService.resetToDefault();

        // Then: 数据已清空
        final courses = await CourseService.loadAllCourses();
        expect(courses, isEmpty);
      });
    });

    // ========== 时间冲突检测测试 (7个) 🔥 核心算法 ==========
    group('时间冲突检测', () {
      test('hasTimeConflict - 同一天同一时间冲突', () {
        // Given: 已存在的课程
        final existingCourse = Course(
          name: '已存在课程',
          location: '地点',
          teacher: '老师',
          weekday: 1, // 星期一
          startSection: 1, // 第1节
          duration: 2, // 持续2节
          color: Colors.blue,
          startWeek: 1,
          endWeek: 16,
        );

        // When: 新课程在同一天、周次重叠、节次重叠
        final newCourse = Course(
          name: '新课程',
          location: '地点',
          teacher: '老师',
          weekday: 1, // 同一天
          startSection: 2, // 节次重叠（已有课程占1-2节）
          duration: 2,
          color: Colors.red,
          startWeek: 5, // 周次重叠
          endWeek: 12,
        );

        // Then: 检测到冲突
        final hasConflict =
            CourseService.hasTimeConflict([existingCourse], newCourse);
        expect(hasConflict, isTrue);
      });

      test('hasTimeConflict - 不同天不冲突', () {
        // Given: 星期一的课程
        final existingCourse = Course(
          name: '星期一课程',
          location: '地点',
          teacher: '老师',
          weekday: 1, // 星期一
          startSection: 1,
          duration: 2,
          color: Colors.blue,
          startWeek: 1,
          endWeek: 16,
        );

        // When: 星期二的课程
        final newCourse = Course(
          name: '星期二课程',
          location: '地点',
          teacher: '老师',
          weekday: 2, // 星期二
          startSection: 1, // 节次相同
          duration: 2,
          color: Colors.red,
          startWeek: 1, // 周次相同
          endWeek: 16,
        );

        // Then: 不冲突
        final hasConflict =
            CourseService.hasTimeConflict([existingCourse], newCourse);
        expect(hasConflict, isFalse);
      });

      test('hasTimeConflict - 周次不重叠不冲突', () {
        // Given: 1-8周的课程
        final existingCourse = Course(
          name: '前半学期课程',
          location: '地点',
          teacher: '老师',
          weekday: 1,
          startSection: 1,
          duration: 2,
          color: Colors.blue,
          startWeek: 1,
          endWeek: 8,
        );

        // When: 9-16周的课程
        final newCourse = Course(
          name: '后半学期课程',
          location: '地点',
          teacher: '老师',
          weekday: 1, // 同一天
          startSection: 1, // 节次相同
          duration: 2,
          color: Colors.red,
          startWeek: 9, // 周次不重叠
          endWeek: 16,
        );

        // Then: 不冲突
        final hasConflict =
            CourseService.hasTimeConflict([existingCourse], newCourse);
        expect(hasConflict, isFalse);
      });

      test('hasTimeConflict - 节次不重叠不冲突', () {
        // Given: 第1-2节的课程
        final existingCourse = Course(
          name: '上午课程',
          location: '地点',
          teacher: '老师',
          weekday: 1,
          startSection: 1, // 第1节
          duration: 2, // 持续2节（占1-2节）
          color: Colors.blue,
          startWeek: 1,
          endWeek: 16,
        );

        // When: 第3-4节的课程
        final newCourse = Course(
          name: '下午课程',
          location: '地点',
          teacher: '老师',
          weekday: 1, // 同一天
          startSection: 3, // 第3节（不重叠）
          duration: 2,
          color: Colors.red,
          startWeek: 1, // 周次相同
          endWeek: 16,
        );

        // Then: 不冲突
        final hasConflict =
            CourseService.hasTimeConflict([existingCourse], newCourse);
        expect(hasConflict, isFalse);
      });

      test('hasTimeConflict - 排除自身索引（更新场景）', () {
        // Given: 已有课程列表
        final courses = [
          Course(
            name: '课程1',
            location: '地点',
            teacher: '老师',
            weekday: 1,
            startSection: 1,
            duration: 2,
            color: Colors.blue,
            startWeek: 1,
            endWeek: 16,
          ),
          Course(
            name: '课程2',
            location: '地点',
            teacher: '老师',
            weekday: 1,
            startSection: 3,
            duration: 2,
            color: Colors.red,
            startWeek: 1,
            endWeek: 16,
          ),
        ];

        // When: 更新第一个课程（保持同样的时间）
        final updatedCourse = Course(
          name: '课程1（更新）',
          location: '新地点',
          teacher: '新老师',
          weekday: 1,
          startSection: 1,
          duration: 2,
          color: Colors.green,
          startWeek: 1,
          endWeek: 16,
        );

        // Then: 排除索引0后不冲突
        final hasConflict = CourseService.hasTimeConflict(
          courses,
          updatedCourse,
          excludeIndex: 0,
        );
        expect(hasConflict, isFalse);
      });

      test('getConflictingCourses - 返回所有冲突课程', () {
        // Given: 多个课程
        final courses = [
          Course(
            name: '课程1',
            location: '地点',
            teacher: '老师',
            weekday: 1,
            startSection: 1,
            duration: 2,
            color: Colors.blue,
            startWeek: 1,
            endWeek: 16,
          ),
          Course(
            name: '课程2',
            location: '地点',
            teacher: '老师',
            weekday: 1,
            startSection: 2, // 与课程1重叠
            duration: 2,
            color: Colors.red,
            startWeek: 1,
            endWeek: 16,
          ),
          Course(
            name: '课程3',
            location: '地点',
            teacher: '老师',
            weekday: 2, // 不同天
            startSection: 1,
            duration: 2,
            color: Colors.green,
            startWeek: 1,
            endWeek: 16,
          ),
        ];

        // When: 检查与课程1、2冲突的新课程
        final newCourse = Course(
          name: '新课程',
          location: '地点',
          teacher: '老师',
          weekday: 1,
          startSection: 1,
          duration: 2,
          color: Colors.yellow,
          startWeek: 1,
          endWeek: 16,
        );

        final conflicts =
            CourseService.getConflictingCourses(courses, newCourse);

        // Then: 返回课程1和课程2
        expect(conflicts, hasLength(2));
        expect(conflicts[0].name, equals('课程1'));
        expect(conflicts[1].name, equals('课程2'));
      });

      test('getConflictingCourses - 无冲突返回空列表', () {
        // Given: 已有课程
        final courses = [
          Course(
            name: '课程1',
            location: '地点',
            teacher: '老师',
            weekday: 1,
            startSection: 1,
            duration: 2,
            color: Colors.blue,
            startWeek: 1,
            endWeek: 16,
          ),
        ];

        // When: 完全不冲突的新课程
        final newCourse = Course(
          name: '新课程',
          location: '地点',
          teacher: '老师',
          weekday: 2, // 不同天
          startSection: 1,
          duration: 2,
          color: Colors.red,
          startWeek: 1,
          endWeek: 16,
        );

        final conflicts =
            CourseService.getConflictingCourses(courses, newCourse);

        // Then: 返回空列表
        expect(conflicts, isEmpty);
      });
    });
  });
}
