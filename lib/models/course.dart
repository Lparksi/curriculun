import 'package:flutter/material.dart';
import 'time_table.dart';

/// 课程数据模型
class Course {
  final String name; // 课程名称
  final String location; // 上课地点
  final String teacher; // 教师姓名
  final int weekday; // 星期几 (1-7)
  final int startSection; // 开始节次 (1-9)
  final int duration; // 持续节数
  final Color color; // 课程卡片颜色
  final int startWeek; // 开始周次
  final int endWeek; // 结束周次
  final String? semesterId; // 关联的学期ID (可选，用于多学期支持)
  final bool isHidden; // 是否隐藏 (用于处理冲突课程)

  Course({
    required this.name,
    required this.location,
    required this.teacher,
    required this.weekday,
    required this.startSection,
    required this.duration,
    required this.color,
    this.startWeek = 1, // 默认第1周开始
    this.endWeek = 20, // 默认第20周结束
    this.semesterId, // 默认为null (向后兼容)
    this.isHidden = false, // 默认不隐藏
  });

  /// 从 JSON 创建 Course 对象
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      name: json['name'] as String,
      location: json['location'] as String? ?? '',
      teacher: json['teacher'] as String? ?? '',
      weekday: json['weekday'] as int,
      startSection: json['startSection'] as int,
      duration: json['duration'] as int,
      startWeek: json['startWeek'] as int? ?? 1,
      endWeek: json['endWeek'] as int? ?? 20,
      color: colorFromHex(json['color'] as String?),
      semesterId: json['semesterId'] as String?, // 可选字段
      isHidden: json['isHidden'] as bool? ?? false, // 默认不隐藏
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'teacher': teacher,
      'weekday': weekday,
      'startSection': startSection,
      'duration': duration,
      'startWeek': startWeek,
      'endWeek': endWeek,
      'color': colorToHex(color),
      if (semesterId != null) 'semesterId': semesterId, // 仅在非null时保存
      'isHidden': isHidden,
    };
  }

  /// 将十六进制颜色字符串转换为 Color
  static Color colorFromHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return Colors.blue; // 默认颜色
    }
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// 将 Color 转换为十六进制字符串
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// 结束节次
  int get endSection => startSection + duration - 1;

  /// 获取上课时间段文字描述 (需要传入时间表)
  String getTimeRangeText(TimeTable timeTable) {
    final start = timeTable.getSectionTime(startSection);
    final end = timeTable.getSectionTime(endSection);
    if (start == null || end == null) return '';
    return '${start.startTime}-${end.endTime}';
  }

  /// 获取周次范围文字描述
  String get weekRangeText {
    if (startWeek == endWeek) {
      return '第$startWeek周';
    }
    return '第$startWeek-$endWeek周';
  }

  /// 获取节次范围文字描述
  String get sectionRangeText {
    if (duration == 1) {
      return '第$startSection节';
    }
    return '第$startSection-$endSection节';
  }
}

/// 预定义的节次时间表 (保持向后兼容)
/// @deprecated 使用 TimeTable.defaultTimeTable() 替代
class SectionTimeTable {
  static const List<SectionTime> sections = [
    SectionTime(section: 1, startTime: '08:00', endTime: '08:45'),
    SectionTime(section: 2, startTime: '08:55', endTime: '09:40'),
    SectionTime(section: 3, startTime: '10:10', endTime: '10:55'),
    SectionTime(section: 4, startTime: '11:05', endTime: '11:50'),
    SectionTime(section: 5, startTime: '15:00', endTime: '15:45'),
    SectionTime(section: 6, startTime: '15:55', endTime: '17:10'),
    SectionTime(section: 7, startTime: '17:10', endTime: '17:55'),
    SectionTime(section: 8, startTime: '18:05', endTime: '18:50'),
    SectionTime(section: 9, startTime: '20:00', endTime: '20:45'),
    SectionTime(section: 10, startTime: '20:55', endTime: '21:40'),
  ];
}
