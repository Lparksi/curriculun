import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../utils/course_colors.dart';

/// 课程数据服务
/// 负责从 JSON 文件加载课程数据以及课程的CRUD操作
class CourseService {
  static const String _coursesKey = 'saved_courses';

  /// 从 assets 中的 JSON 文件加载课程列表
  static Future<List<Course>> loadCoursesFromAssets({
    String assetPath = 'assets/courses.json',
  }) async {
    try {
      // 读取 JSON 文件
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // 重置颜色管理器
      CourseColorManager.reset();

      // 解析课程列表
      final List<dynamic> coursesJson = jsonData['courses'] as List<dynamic>;

      return coursesJson.map((courseJson) {
        final course = courseJson as Map<String, dynamic>;

        // 如果 JSON 中没有提供颜色,使用颜色管理器自动分配
        if (course['color'] == null || (course['color'] as String).isEmpty) {
          final courseName = course['name'] as String;
          course['color'] = Course.colorToHex(
            CourseColorManager.getColorForCourse(courseName),
          );
        }

        return Course.fromJson(course);
      }).toList();
    } catch (e) {
      // 如果加载失败,返回空列表
      debugPrint('加载课程数据失败: $e');
      return [];
    }
  }

  /// 将课程列表保存为 JSON 字符串(用于导出)
  static String exportCoursesToJson(List<Course> courses) {
    final Map<String, dynamic> jsonData = {
      'courses': courses.map((course) => course.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }

  /// 加载所有课程列表（不筛选学期）
  static Future<List<Course>> loadAllCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_coursesKey);

      if (savedJson != null && savedJson.isNotEmpty) {
        // 从本地存储加载
        final Map<String, dynamic> jsonData = json.decode(savedJson);
        final List<dynamic> coursesJson = jsonData['courses'] as List<dynamic>;

        // 重置颜色管理器
        CourseColorManager.reset();

        return coursesJson.map((courseJson) {
          final course = courseJson as Map<String, dynamic>;
          // 确保颜色存在
          if (course['color'] == null || (course['color'] as String).isEmpty) {
            final courseName = course['name'] as String;
            course['color'] = Course.colorToHex(
              CourseColorManager.getColorForCourse(courseName),
            );
          }
          return Course.fromJson(course);
        }).toList();
      } else {
        // 首次使用，从 assets 加载（暂不保存，让学期初始化完成后再保存）
        final courses = await loadCoursesFromAssets();
        return courses;
      }
    } catch (e) {
      debugPrint('加载课程数据失败: $e');
      return [];
    }
  }

  /// 按学期ID筛选课程
  static Future<List<Course>> loadCoursesBySemester(String? semesterId) async {
    final allCourses = await loadAllCourses();

    // 如果没有指定学期ID，返回所有没有学期ID的课程（向后兼容）
    if (semesterId == null) {
      return allCourses.where((course) => course.semesterId == null).toList();
    }

    // 筛选指定学期的课程
    final semesterCourses = allCourses
        .where((course) => course.semesterId == semesterId)
        .toList();

    // 如果没有该学期的课程，但存在没有学期ID的课程（首次加载的情况）
    if (semesterCourses.isEmpty && allCourses.any((c) => c.semesterId == null)) {
      // 为这些课程分配当前学期ID
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_coursesKey);

      // 只有当本地没有保存过课程时才自动分配（首次使用）
      if (savedJson == null || savedJson.isEmpty) {
        final updatedCourses = allCourses.map((course) {
          // 创建新的课程对象，添加学期ID
          return Course(
            name: course.name,
            location: course.location,
            teacher: course.teacher,
            weekday: course.weekday,
            startSection: course.startSection,
            duration: course.duration,
            color: course.color,
            startWeek: course.startWeek,
            endWeek: course.endWeek,
            semesterId: semesterId,
          );
        }).toList();

        // 保存到本地
        await saveCourses(updatedCourses);
        return updatedCourses;
      }
    }

    return semesterCourses;
  }

  /// 加载课程列表（默认加载所有课程）
  /// @deprecated 使用 loadAllCourses() 或 loadCoursesBySemester() 替代
  static Future<List<Course>> loadCourses() async {
    return loadAllCourses();
  }

  /// 保存课程列表到本地存储
  static Future<void> saveCourses(List<Course> courses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = exportCoursesToJson(courses);
      await prefs.setString(_coursesKey, jsonString);
    } catch (e) {
      debugPrint('保存课程数据失败: $e');
    }
  }

  /// 添加课程
  static Future<void> addCourse(Course course) async {
    final courses = await loadCourses();
    courses.add(course);
    await saveCourses(courses);
  }

  /// 更新课程
  static Future<void> updateCourse(int index, Course course) async {
    final courses = await loadCourses();
    if (index >= 0 && index < courses.length) {
      courses[index] = course;
      await saveCourses(courses);
    }
  }

  /// 删除课程
  static Future<void> deleteCourse(int index) async {
    final courses = await loadCourses();
    if (index >= 0 && index < courses.length) {
      courses.removeAt(index);
      await saveCourses(courses);
    }
  }

  /// 重置课程数据（恢复为assets中的默认数据）
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coursesKey);
  }

  /// 检查时间冲突
  static bool hasTimeConflict(
    List<Course> courses,
    Course newCourse, {
    int? excludeIndex,
  }) {
    for (int i = 0; i < courses.length; i++) {
      if (excludeIndex != null && i == excludeIndex) continue;

      final course = courses[i];

      // 检查是否在同一天
      if (course.weekday != newCourse.weekday) continue;

      // 检查周次是否有重叠
      final weekOverlap =
          !(newCourse.endWeek < course.startWeek ||
              newCourse.startWeek > course.endWeek);
      if (!weekOverlap) continue;

      // 检查节次是否有重叠
      final newEndSection = newCourse.startSection + newCourse.duration - 1;
      final existingEndSection = course.startSection + course.duration - 1;

      final sectionOverlap =
          !(newEndSection < course.startSection ||
              newCourse.startSection > existingEndSection);

      if (sectionOverlap) {
        return true;
      }
    }
    return false;
  }
}
