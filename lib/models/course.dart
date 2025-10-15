import 'package:flutter/material.dart';

/// 课程数据模型
class Course {
  final String name;           // 课程名称
  final String location;       // 上课地点
  final String teacher;        // 教师姓名
  final int weekday;          // 星期几 (1-7)
  final int startSection;     // 开始节次 (1-9)
  final int duration;         // 持续节数
  final Color color;          // 课程卡片颜色

  Course({
    required this.name,
    required this.location,
    required this.teacher,
    required this.weekday,
    required this.startSection,
    required this.duration,
    required this.color,
  });

  /// 结束节次
  int get endSection => startSection + duration - 1;
}

/// 节次时间配置
class SectionTime {
  final int section;
  final String startTime;
  final String endTime;

  const SectionTime({
    required this.section,
    required this.startTime,
    required this.endTime,
  });

  String get timeRange => '$startTime\n$endTime';
}

/// 预定义的节次时间表
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
