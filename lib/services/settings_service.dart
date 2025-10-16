import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/semester_settings.dart';

/// 学期设置本地存储服务
class SettingsService {
  // 多学期存储键
  static const String _semestersKey = 'semesters_list'; // 学期列表
  static const String _activeSemesterIdKey = 'active_semester_id'; // 当前激活的学期ID

  // 旧的单学期存储键（用于向后兼容）
  static const String _oldSettingsKey = 'semester_settings';

  /// 生成学期ID
  static String generateSemesterId() {
    return 'semester_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 获取所有学期列表
  static Future<List<SemesterSettings>> getAllSemesters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_semestersKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
        return jsonList
            .map(
              (json) => SemesterSettings.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      // 尝试迁移旧数据
      final migrated = await _migrateOldSettings();
      if (migrated != null) {
        return [migrated];
      }

      // 创建默认学期（直接保存，避免递归调用）
      final defaultSemester = SemesterSettings.defaultSettings();
      final semesters = [defaultSemester];
      await _saveSemesters(semesters);
      await setActiveSemesterId(defaultSemester.id);
      return semesters;
    } catch (e) {
      debugPrint('获取学期列表失败: $e');
      // 返回默认学期避免崩溃
      return [SemesterSettings.defaultSettings()];
    }
  }

  /// 保存学期列表
  static Future<void> _saveSemesters(List<SemesterSettings> semesters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        semesters.map((semester) => semester.toJson()).toList(),
      );
      await prefs.setString(_semestersKey, jsonString);
    } catch (e) {
      debugPrint('保存学期列表失败: $e');
    }
  }

  /// 添加新学期
  static Future<void> addSemester(SemesterSettings semester) async {
    final semesters = await getAllSemesters();
    semesters.add(semester);
    await _saveSemesters(semesters);
  }

  /// 更新学期
  static Future<void> updateSemester(SemesterSettings semester) async {
    final semesters = await getAllSemesters();
    final index = semesters.indexWhere((s) => s.id == semester.id);

    if (index != -1) {
      semesters[index] = semester.copyWith(updatedAt: DateTime.now());
      await _saveSemesters(semesters);
    } else {
      debugPrint('未找到要更新的学期: ${semester.id}');
    }
  }

  /// 删除学期
  static Future<bool> deleteSemester(String semesterId) async {
    final semesters = await getAllSemesters();

    // 不允许删除唯一的学期
    if (semesters.length <= 1) {
      debugPrint('无法删除唯一的学期');
      return false;
    }

    // 查找要删除的学期
    final index = semesters.indexWhere((s) => s.id == semesterId);
    if (index == -1) {
      debugPrint('未找到要删除的学期: $semesterId');
      return false;
    }

    // 如果删除的是激活学期，切换到第一个学期
    final activeSemesterId = await getActiveSemesterId();
    if (activeSemesterId == semesterId) {
      final newActiveSemester = semesters.firstWhere(
        (s) => s.id != semesterId,
        orElse: () => semesters[0],
      );
      await setActiveSemesterId(newActiveSemester.id);
    }

    semesters.removeAt(index);
    await _saveSemesters(semesters);
    return true;
  }

  /// 获取当前激活的学期ID
  static Future<String?> getActiveSemesterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeSemesterIdKey);
  }

  /// 设置当前激活的学期ID
  static Future<void> setActiveSemesterId(String semesterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSemesterIdKey, semesterId);
  }

  /// 获取当前激活的学期
  static Future<SemesterSettings> getActiveSemester() async {
    final activeSemesterId = await getActiveSemesterId();
    final semesters = await getAllSemesters();

    if (activeSemesterId != null) {
      final activeSemester = semesters.firstWhere(
        (s) => s.id == activeSemesterId,
        orElse: () => semesters.isNotEmpty
            ? semesters.first
            : SemesterSettings.defaultSettings(),
      );
      return activeSemester;
    }

    // 如果没有激活学期，激活第一个学期
    if (semesters.isNotEmpty) {
      await setActiveSemesterId(semesters.first.id);
      return semesters.first;
    }

    // 创建并返回默认学期
    final defaultSemester = SemesterSettings.defaultSettings();
    await addSemester(defaultSemester);
    await setActiveSemesterId(defaultSemester.id);
    return defaultSemester;
  }

  /// 复制学期
  static Future<SemesterSettings> duplicateSemester(
    String sourceSemesterId,
  ) async {
    final semesters = await getAllSemesters();
    final sourceSemester = semesters.firstWhere(
      (s) => s.id == sourceSemesterId,
      orElse: () => throw Exception('未找到源学期'),
    );

    final now = DateTime.now();
    final duplicated = sourceSemester.copyWith(
      id: generateSemesterId(),
      name: '${sourceSemester.name} (副本)',
      createdAt: now,
      updatedAt: now,
    );

    await addSemester(duplicated);
    return duplicated;
  }

  /// 迁移旧的单学期设置 (向后兼容)
  static Future<SemesterSettings?> _migrateOldSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldJsonString = prefs.getString(_oldSettingsKey);

      if (oldJsonString != null && oldJsonString.isNotEmpty) {
        final oldJson = jsonDecode(oldJsonString) as Map<String, dynamic>;

        // 创建新的学期对象（保持旧的数据但添加新字段）
        final now = DateTime.now();
        final migratedSemester = SemesterSettings(
          id: generateSemesterId(),
          name: '已迁移学期',
          startDate: DateTime.parse(oldJson['startDate'] as String),
          totalWeeks: oldJson['totalWeeks'] as int,
          createdAt: now,
          updatedAt: now,
        );

        // 直接保存到新格式（避免递归调用 getAllSemesters）
        final semesters = [migratedSemester];
        await _saveSemesters(semesters);
        await setActiveSemesterId(migratedSemester.id);

        // 删除旧数据
        await prefs.remove(_oldSettingsKey);

        debugPrint('成功迁移旧学期设置');
        return migratedSemester;
      }
    } catch (e) {
      debugPrint('迁移旧学期设置失败: $e');
    }
    return null;
  }

  /// 清除所有学期数据
  static Future<void> clearAllSemesters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_semestersKey);
    await prefs.remove(_activeSemesterIdKey);
    await prefs.remove(_oldSettingsKey);
  }

  // ========== 向后兼容的旧API (标记为废弃) ==========

  /// @deprecated 使用 getActiveSemester() 替代
  static Future<SemesterSettings> loadSemesterSettings() async {
    return getActiveSemester();
  }

  /// @deprecated 使用 updateSemester() 替代
  static Future<void> saveSemesterSettings(SemesterSettings settings) async {
    await updateSemester(settings);
  }

  /// @deprecated 使用 clearAllSemesters() 替代
  static Future<void> clearSettings() async {
    await clearAllSemesters();
  }
}
