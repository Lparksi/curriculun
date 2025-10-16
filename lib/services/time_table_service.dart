import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_table.dart';

/// 时间表服务 - 处理时间表的增删改查和持久化
class TimeTableService {
  // SharedPreferences 存储键
  static const String _timeTablesKey = 'time_tables';
  static const String _activeTimeTableIdKey = 'active_time_table_id';

  /// 加载所有时间表
  static Future<List<TimeTable>> loadTimeTables() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_timeTablesKey);

      if (jsonString == null || jsonString.isEmpty) {
        // 首次使用,返回默认时间表
        final defaultTable = TimeTable.defaultTimeTable();
        await saveTimeTables([defaultTable]);
        await setActiveTimeTableId(defaultTable.id);
        return [defaultTable];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => TimeTable.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('加载时间表失败: $e');
      final defaultTable = TimeTable.defaultTimeTable();
      return [defaultTable];
    }
  }

  /// 保存所有时间表
  static Future<void> saveTimeTables(List<TimeTable> timeTables) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        timeTables.map((table) => table.toJson()).toList(),
      );
      await prefs.setString(_timeTablesKey, jsonString);
    } catch (e) {
      debugPrint('保存时间表失败: $e');
      rethrow;
    }
  }

  /// 获取当前激活的时间表 ID
  static Future<String?> getActiveTimeTableId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeTimeTableIdKey);
    } catch (e) {
      debugPrint('获取当前时间表 ID 失败: $e');
      return null;
    }
  }

  /// 设置当前激活的时间表 ID
  static Future<void> setActiveTimeTableId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeTimeTableIdKey, id);
    } catch (e) {
      debugPrint('设置当前时间表 ID 失败: $e');
      rethrow;
    }
  }

  /// 获取当前激活的时间表
  static Future<TimeTable> getActiveTimeTable() async {
    final timeTables = await loadTimeTables();
    final activeId = await getActiveTimeTableId();

    // 查找激活的时间表
    final activeTable = timeTables.firstWhere(
      (table) => table.id == activeId,
      orElse: () => timeTables.first,
    );

    return activeTable;
  }

  /// 添加新时间表
  static Future<void> addTimeTable(TimeTable timeTable) async {
    final timeTables = await loadTimeTables();

    // 检查 ID 是否已存在
    if (timeTables.any((t) => t.id == timeTable.id)) {
      throw Exception('时间表 ID 已存在: ${timeTable.id}');
    }

    timeTables.add(timeTable);
    await saveTimeTables(timeTables);
  }

  /// 更新时间表
  static Future<void> updateTimeTable(TimeTable timeTable) async {
    final timeTables = await loadTimeTables();
    final index = timeTables.indexWhere((t) => t.id == timeTable.id);

    if (index == -1) {
      throw Exception('时间表不存在: ${timeTable.id}');
    }

    timeTables[index] = timeTable.copyWith(updatedAt: DateTime.now());
    await saveTimeTables(timeTables);
  }

  /// 删除时间表
  static Future<void> deleteTimeTable(String id) async {
    final timeTables = await loadTimeTables();

    // 不允许删除默认时间表
    if (id == 'default') {
      throw Exception('不能删除默认时间表');
    }

    // 至少保留一个时间表
    if (timeTables.length <= 1) {
      throw Exception('至少需要保留一个时间表');
    }

    // 如果删除的是当前激活的时间表,切换到默认时间表
    final activeId = await getActiveTimeTableId();
    if (activeId == id) {
      final defaultTable = timeTables.firstWhere(
        (t) => t.id == 'default',
        orElse: () => timeTables.first,
      );
      await setActiveTimeTableId(defaultTable.id);
    }

    timeTables.removeWhere((t) => t.id == id);
    await saveTimeTables(timeTables);
  }

  /// 复制时间表
  static Future<TimeTable> duplicateTimeTable(String sourceId) async {
    final timeTables = await loadTimeTables();
    final sourceTable = timeTables.firstWhere(
      (t) => t.id == sourceId,
      orElse: () => throw Exception('源时间表不存在: $sourceId'),
    );

    // 生成新 ID
    final newId =
        '${sourceTable.id}_copy_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final newTable = TimeTable(
      id: newId,
      name: '${sourceTable.name} (副本)',
      sections: sourceTable.sections,
      createdAt: now,
      updatedAt: now,
    );

    await addTimeTable(newTable);
    return newTable;
  }

  /// 生成唯一的时间表 ID
  static String generateTimeTableId() {
    return 'timetable_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 验证时间格式 (HH:mm)
  static bool isValidTimeFormat(String time) {
    final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return regex.hasMatch(time);
  }

  /// 比较两个时间字符串 (HH:mm)
  /// 返回: startTime < endTime ? true : false
  static bool isTimeRangeValid(String startTime, String endTime) {
    if (!isValidTimeFormat(startTime) || !isValidTimeFormat(endTime)) {
      return false;
    }

    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    return start < end;
  }

  /// 解析时间字符串为分钟数
  static int _parseTime(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }
}
