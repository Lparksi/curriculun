import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 配置文件版本管理器
/// 负责处理所有配置文件的版本控制和升级迁移
class ConfigVersionManager {
  /// 当前支持的最新版本号
  static const String currentVersion = '1.1.0';

  /// 历史版本列表（从旧到新）
  static const List<String> supportedVersions = [
    '1.0.0', // 初始版本
    '1.1.0', // 当前版本：添加版本管理支持
  ];

  /// 验证版本号格式
  static bool isValidVersion(String version) {
    // 语义化版本号格式：major.minor.patch
    final regex = RegExp(r'^\d+\.\d+\.\d+$');
    return regex.hasMatch(version);
  }

  /// 比较两个版本号
  /// 返回：-1 (v1 < v2), 0 (v1 == v2), 1 (v1 > v2)
  static int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  /// 检查版本是否需要升级
  static bool needsUpgrade(String fromVersion) {
    return compareVersions(fromVersion, currentVersion) < 0;
  }

  /// 检查版本是否兼容
  static bool isCompatible(String version) {
    return supportedVersions.contains(version) ||
        compareVersions(version, currentVersion) == 0;
  }

  /// 升级配置文件到最新版本
  /// [data] 原始配置数据（已解析的 Map）
  /// [fromVersion] 原始版本号
  /// 返回升级后的配置数据
  static Map<String, dynamic> upgradeConfig(
    Map<String, dynamic> data,
    String fromVersion,
  ) {
    if (!needsUpgrade(fromVersion)) {
      debugPrint('配置版本 $fromVersion 已是最新，无需升级');
      return data;
    }

    debugPrint('开始升级配置：$fromVersion -> $currentVersion');

    var upgradedData = Map<String, dynamic>.from(data);
    var currentVer = fromVersion;

    // 逐步升级到最新版本
    for (final targetVersion in supportedVersions) {
      if (compareVersions(currentVer, targetVersion) < 0) {
        debugPrint('升级配置：$currentVer -> $targetVersion');
        upgradedData = _upgradeToVersion(upgradedData, currentVer, targetVersion);
        currentVer = targetVersion;
      }
    }

    // 更新版本号
    upgradedData['version'] = currentVersion;
    debugPrint('配置升级完成：$fromVersion -> $currentVersion');

    return upgradedData;
  }

  /// 升级到指定版本
  static Map<String, dynamic> _upgradeToVersion(
    Map<String, dynamic> data,
    String fromVersion,
    String toVersion,
  ) {
    final upgradedData = Map<String, dynamic>.from(data);

    switch (toVersion) {
      case '1.1.0':
        return _upgradeTo_1_1_0(upgradedData, fromVersion);
      // 未来版本的升级逻辑在此添加
      // case '1.2.0':
      //   return _upgradeTo_1_2_0(upgradedData, fromVersion);
      default:
        debugPrint('未找到版本 $toVersion 的升级路径');
        return upgradedData;
    }
  }

  /// 升级到 v1.1.0
  /// 变更内容：添加版本管理支持
  static Map<String, dynamic> _upgradeTo_1_1_0(
    Map<String, dynamic> data,
    String fromVersion,
  ) {
    final upgradedData = Map<String, dynamic>.from(data);

    // v1.0.0 -> v1.1.0 的变更：
    // 1. 确保有 version 字段
    if (!upgradedData.containsKey('version')) {
      upgradedData['version'] = '1.1.0';
    }

    // 2. 确保有 exportTime 字段
    if (!upgradedData.containsKey('exportTime')) {
      upgradedData['exportTime'] = DateTime.now().toIso8601String();
    }

    // 3. 如果 data 字段存在，确保其内部配置项也有版本号
    if (upgradedData.containsKey('data')) {
      final dataSection = upgradedData['data'] as Map<String, dynamic>;

      // 为课程列表添加版本标记（如果需要）
      if (dataSection.containsKey('courses')) {
        // 课程数据本身不需要额外版本字段，因为它们继承主配置版本
        debugPrint('课程数据已包含在 v1.1.0 配置中');
      }

      // 为学期设置添加版本标记
      if (dataSection.containsKey('semesters')) {
        final semesters = dataSection['semesters'] as List<dynamic>;
        for (var i = 0; i < semesters.length; i++) {
          final semester = semesters[i] as Map<String, dynamic>;
          if (!semester.containsKey('version')) {
            semester['version'] = '1.1.0';
          }
        }
      }

      // 为时间表添加版本标记
      if (dataSection.containsKey('timeTables')) {
        final timeTables = dataSection['timeTables'] as List<dynamic>;
        for (var i = 0; i < timeTables.length; i++) {
          final timeTable = timeTables[i] as Map<String, dynamic>;
          if (!timeTable.containsKey('version')) {
            timeTable['version'] = '1.1.0';
          }
        }
      }
    }

    debugPrint('配置已升级到 v1.1.0');
    return upgradedData;
  }

  // ==================== 未来版本升级示例 ====================

  /// 升级到 v1.2.0 的示例
  /// 取消注释以启用
  /*
  static Map<String, dynamic> _upgradeTo_1_2_0(
    Map<String, dynamic> data,
    String fromVersion,
  ) {
    final upgradedData = Map<String, dynamic>.from(data);

    // 示例：添加新字段
    if (!upgradedData.containsKey('metadata')) {
      upgradedData['metadata'] = {
        'appVersion': '1.2.0',
        'platform': Platform.operatingSystem,
      };
    }

    // 示例：修改现有字段格式
    if (upgradedData.containsKey('data')) {
      final dataSection = upgradedData['data'] as Map<String, dynamic>;

      // 课程添加新属性
      if (dataSection.containsKey('courses')) {
        final courses = dataSection['courses'] as List<dynamic>;
        for (var course in courses) {
          final courseMap = course as Map<String, dynamic>;
          // 添加新字段，提供默认值
          if (!courseMap.containsKey('credits')) {
            courseMap['credits'] = 0;
          }
        }
      }
    }

    debugPrint('配置已升级到 v1.2.0');
    return upgradedData;
  }
  */

  /// 创建版本迁移报告
  static String generateMigrationReport(
    String fromVersion,
    String toVersion,
    Map<String, dynamic> originalData,
    Map<String, dynamic> upgradedData,
  ) {
    final report = StringBuffer();
    report.writeln('=== 配置文件版本升级报告 ===');
    report.writeln('原始版本: $fromVersion');
    report.writeln('目标版本: $toVersion');
    report.writeln('升级时间: ${DateTime.now().toIso8601String()}');
    report.writeln('');

    // 统计数据变化
    final originalDataSection = originalData['data'] as Map<String, dynamic>?;
    final upgradedDataSection = upgradedData['data'] as Map<String, dynamic>?;

    if (originalDataSection != null && upgradedDataSection != null) {
      report.writeln('数据统计:');

      final originalCourses = (originalDataSection['courses'] as List?)?.length ?? 0;
      final upgradedCourses = (upgradedDataSection['courses'] as List?)?.length ?? 0;
      report.writeln('  课程数量: $originalCourses -> $upgradedCourses');

      final originalSemesters = (originalDataSection['semesters'] as List?)?.length ?? 0;
      final upgradedSemesters = (upgradedDataSection['semesters'] as List?)?.length ?? 0;
      report.writeln('  学期数量: $originalSemesters -> $upgradedSemesters');

      final originalTimeTables = (originalDataSection['timeTables'] as List?)?.length ?? 0;
      final upgradedTimeTables = (upgradedDataSection['timeTables'] as List?)?.length ?? 0;
      report.writeln('  时间表数量: $originalTimeTables -> $upgradedTimeTables');
    }

    report.writeln('');
    report.writeln('升级状态: 成功 ✓');
    report.writeln('========================');

    return report.toString();
  }

  /// 备份配置文件（升级前）
  static String backupConfig(Map<String, dynamic> data, String version) {
    final backup = {
      'backup_version': version,
      'backup_time': DateTime.now().toIso8601String(),
      'original_data': data,
    };
    return jsonEncode(backup);
  }

  /// 从备份恢复配置
  static Map<String, dynamic>? restoreFromBackup(String backupJson) {
    try {
      final backup = jsonDecode(backupJson) as Map<String, dynamic>;
      return backup['original_data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('恢复备份失败: $e');
      return null;
    }
  }
}
