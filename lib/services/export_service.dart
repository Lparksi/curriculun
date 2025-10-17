import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../models/semester_settings.dart';
import '../models/time_table.dart';
import 'config_version_manager.dart';
import 'course_service.dart';
import 'settings_service.dart';
import 'time_table_service.dart';

/// 数据导出/导入服务
/// 负责应用数据的导出和导入功能，支持课程、学期设置和时间表
class ExportService {
  /// 导出所有数据为 JSON 字符串
  /// 包括：课程、学期设置、时间表
  static Future<String> exportAllData() async {
    try {
      // 并行加载所有数据
      final results = await Future.wait([
        CourseService.loadAllCourses(),
        SettingsService.getAllSemesters(),
        TimeTableService.loadTimeTables(),
        SettingsService.getActiveSemesterId(),
        TimeTableService.getActiveTimeTableId(),
      ]);

      final courses = results[0] as List<Course>;
      final semesters = results[1] as List<SemesterSettings>;
      final timeTables = results[2] as List<TimeTable>;
      final activeSemesterId = results[3] as String?;
      final activeTimeTableId = results[4] as String?;

      // 构建导出数据结构
      final exportData = {
        'version': ConfigVersionManager.currentVersion, // 使用版本管理器的当前版本
        'exportTime': DateTime.now().toIso8601String(),
        'data': {
          'courses': courses.map((c) => c.toJson()).toList(),
          'semesters': semesters.map((s) => s.toJson()).toList(),
          'timeTables': timeTables.map((t) => t.toJson()).toList(),
          'activeSemesterId': activeSemesterId,
          'activeTimeTableId': activeTimeTableId,
        },
      };

      // 格式化 JSON（美化输出）
      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      debugPrint('导出数据失败: $e');
      rethrow;
    }
  }

  /// 导出课程数据为 JSON 字符串
  static Future<String> exportCourses() async {
    try {
      final courses = await CourseService.loadAllCourses();

      final exportData = {
        'version': ConfigVersionManager.currentVersion,
        'exportTime': DateTime.now().toIso8601String(),
        'data': {
          'courses': courses.map((c) => c.toJson()).toList(),
        },
      };

      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      debugPrint('导出课程数据失败: $e');
      rethrow;
    }
  }

  /// 导出学期设置为 JSON 字符串
  static Future<String> exportSemesters() async {
    try {
      final results = await Future.wait([
        SettingsService.getAllSemesters(),
        SettingsService.getActiveSemesterId(),
      ]);

      final semesters = results[0] as List<SemesterSettings>;
      final activeSemesterId = results[1] as String?;

      final exportData = {
        'version': ConfigVersionManager.currentVersion,
        'exportTime': DateTime.now().toIso8601String(),
        'data': {
          'semesters': semesters.map((s) => s.toJson()).toList(),
          'activeSemesterId': activeSemesterId,
        },
      };

      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      debugPrint('导出学期设置失败: $e');
      rethrow;
    }
  }

  /// 导出时间表为 JSON 字符串
  static Future<String> exportTimeTables() async {
    try {
      final results = await Future.wait([
        TimeTableService.loadTimeTables(),
        TimeTableService.getActiveTimeTableId(),
      ]);

      final timeTables = results[0] as List<TimeTable>;
      final activeTimeTableId = results[1] as String?;

      final exportData = {
        'version': ConfigVersionManager.currentVersion,
        'exportTime': DateTime.now().toIso8601String(),
        'data': {
          'timeTables': timeTables.map((t) => t.toJson()).toList(),
          'activeTimeTableId': activeTimeTableId,
        },
      };

      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      debugPrint('导出时间表失败: $e');
      rethrow;
    }
  }

  /// 导入所有数据
  /// [jsonString] 导入的 JSON 字符串
  /// [merge] 是否合并数据（true=合并，false=覆盖）
  /// 返回导入结果统计
  static Future<ImportResult> importAllData(
    String jsonString, {
    bool merge = false,
  }) async {
    try {
      // 解析 JSON
      var jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // 验证并升级配置版本
      jsonData = _validateAndUpgradeConfig(jsonData);

      final data = jsonData['data'] as Map<String, dynamic>;

      // 统计信息
      int coursesImported = 0;
      int semestersImported = 0;
      int timeTablesImported = 0;

      // 导入课程
      if (data.containsKey('courses')) {
        final coursesJson = data['courses'] as List<dynamic>;
        final courses = coursesJson
            .map((json) => Course.fromJson(json as Map<String, dynamic>))
            .toList();

        if (merge) {
          final existingCourses = await CourseService.loadAllCourses();
          existingCourses.addAll(courses);
          await CourseService.saveCourses(existingCourses);
        } else {
          await CourseService.saveCourses(courses);
        }
        coursesImported = courses.length;
      }

      // 导入学期设置
      if (data.containsKey('semesters')) {
        final semestersJson = data['semesters'] as List<dynamic>;
        final semesters = semestersJson
            .map(
              (json) => SemesterSettings.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        if (merge) {
          final existingSemesters = await SettingsService.getAllSemesters();
          // 合并学期（避免ID冲突）
          for (final semester in semesters) {
            if (!existingSemesters.any((s) => s.id == semester.id)) {
              await SettingsService.addSemester(semester);
              semestersImported++;
            }
          }
        } else {
          // 清除现有学期并导入
          await SettingsService.clearAllSemesters();
          for (final semester in semesters) {
            await SettingsService.addSemester(semester);
            semestersImported++;
          }
        }

        // 设置激活的学期
        if (data.containsKey('activeSemesterId')) {
          final activeSemesterId = data['activeSemesterId'] as String?;
          if (activeSemesterId != null) {
            await SettingsService.setActiveSemesterId(activeSemesterId);
          }
        }
      }

      // 导入时间表
      if (data.containsKey('timeTables')) {
        final timeTablesJson = data['timeTables'] as List<dynamic>;
        final timeTables = timeTablesJson
            .map((json) => TimeTable.fromJson(json as Map<String, dynamic>))
            .toList();

        final existingTimeTables = await TimeTableService.loadTimeTables();

        if (merge) {
          // 合并时间表（避免ID冲突）
          for (final timeTable in timeTables) {
            if (!existingTimeTables.any((t) => t.id == timeTable.id)) {
              await TimeTableService.addTimeTable(timeTable);
              timeTablesImported++;
            }
          }
        } else {
          // 覆盖时间表
          await TimeTableService.saveTimeTables(timeTables);
          timeTablesImported = timeTables.length;
        }

        // 设置激活的时间表
        if (data.containsKey('activeTimeTableId')) {
          final activeTimeTableId = data['activeTimeTableId'] as String?;
          if (activeTimeTableId != null) {
            await TimeTableService.setActiveTimeTableId(activeTimeTableId);
          }
        }
      }

      return ImportResult(
        success: true,
        coursesImported: coursesImported,
        semestersImported: semestersImported,
        timeTablesImported: timeTablesImported,
      );
    } catch (e) {
      debugPrint('导入数据失败: $e');
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 导入课程数据
  /// [jsonString] 导入的 JSON 字符串
  /// [merge] 是否合并数据（true=合并，false=覆盖）
  static Future<ImportResult> importCourses(
    String jsonString, {
    bool merge = false,
  }) async {
    try {
      var jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      jsonData = _validateAndUpgradeConfig(jsonData);

      final data = jsonData['data'] as Map<String, dynamic>;

      if (!data.containsKey('courses')) {
        throw FormatException('数据中不包含课程信息');
      }

      final coursesJson = data['courses'] as List<dynamic>;
      final courses = coursesJson
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();

      if (merge) {
        final existingCourses = await CourseService.loadAllCourses();
        existingCourses.addAll(courses);
        await CourseService.saveCourses(existingCourses);
      } else {
        await CourseService.saveCourses(courses);
      }

      return ImportResult(
        success: true,
        coursesImported: courses.length,
      );
    } catch (e) {
      debugPrint('导入课程数据失败: $e');
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 验证并升级配置文件
  /// 返回升级后的配置数据
  static Map<String, dynamic> _validateAndUpgradeConfig(
    Map<String, dynamic> jsonData,
  ) {
    // 检查必需字段
    if (!jsonData.containsKey('version')) {
      // 兼容旧版本：如果没有版本号，假定为 1.0.0
      debugPrint('配置文件缺少版本信息，假定为 v1.0.0');
      jsonData['version'] = '1.0.0';
    }

    if (!jsonData.containsKey('data')) {
      throw const FormatException('配置文件缺少 data 字段');
    }

    final version = jsonData['version'] as String;

    // 验证版本号格式
    if (!ConfigVersionManager.isValidVersion(version)) {
      throw FormatException('无效的版本号格式: $version');
    }

    // 检查版本兼容性
    if (!ConfigVersionManager.isCompatible(version)) {
      throw FormatException(
        '不支持的配置文件版本: $version\n'
        '支持的版本: ${ConfigVersionManager.supportedVersions.join(", ")}\n'
        '当前版本: ${ConfigVersionManager.currentVersion}',
      );
    }

    // 如果需要升级，执行升级
    if (ConfigVersionManager.needsUpgrade(version)) {
      debugPrint('检测到配置文件版本 $version 需要升级');
      final upgradedData = ConfigVersionManager.upgradeConfig(jsonData, version);

      // 生成升级报告
      final report = ConfigVersionManager.generateMigrationReport(
        version,
        ConfigVersionManager.currentVersion,
        jsonData,
        upgradedData,
      );
      debugPrint(report);

      return upgradedData;
    }

    debugPrint('配置文件版本 $version 无需升级');
    return jsonData;
  }
}

/// 导入结果
class ImportResult {
  final bool success;
  final int coursesImported;
  final int semestersImported;
  final int timeTablesImported;
  final String? error;

  ImportResult({
    required this.success,
    this.coursesImported = 0,
    this.semestersImported = 0,
    this.timeTablesImported = 0,
    this.error,
  });

  /// 获取总导入数量
  int get totalImported =>
      coursesImported + semestersImported + timeTablesImported;

  /// 获取导入摘要
  String getSummary() {
    if (!success) {
      return '导入失败: ${error ?? "未知错误"}';
    }

    final parts = <String>[];
    if (coursesImported > 0) parts.add('$coursesImported 门课程');
    if (semestersImported > 0) parts.add('$semestersImported 个学期');
    if (timeTablesImported > 0) parts.add('$timeTablesImported 个时间表');

    if (parts.isEmpty) {
      return '未导入任何数据';
    }

    return '成功导入: ${parts.join('、')}';
  }
}
