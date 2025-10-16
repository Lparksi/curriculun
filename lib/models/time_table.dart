/// 节次时间数据模型
class SectionTime {
  final int section; // 节次编号 (1-10)
  final String startTime; // 开始时间 (HH:mm)
  final String endTime; // 结束时间 (HH:mm)

  const SectionTime({
    required this.section,
    required this.startTime,
    required this.endTime,
  });

  /// 从 JSON 创建
  factory SectionTime.fromJson(Map<String, dynamic> json) {
    return SectionTime(
      section: json['section'] as int,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'section': section, 'startTime': startTime, 'endTime': endTime};
  }

  /// 获取时间范围文本 (用于 UI 显示)
  String get timeRange => '$startTime\n$endTime';

  /// 复制并修改
  SectionTime copyWith({int? section, String? startTime, String? endTime}) {
    return SectionTime(
      section: section ?? this.section,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SectionTime &&
        other.section == section &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => Object.hash(section, startTime, endTime);
}

/// 时间表数据模型
class TimeTable {
  final String id; // 时间表唯一标识
  final String name; // 时间表名称
  final List<SectionTime> sections; // 节次时间列表
  final DateTime createdAt; // 创建时间
  final DateTime updatedAt; // 更新时间

  const TimeTable({
    required this.id,
    required this.name,
    required this.sections,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 默认时间表 (与原有 SectionTimeTable 一致)
  factory TimeTable.defaultTimeTable() {
    final now = DateTime.now();
    return TimeTable(
      id: 'default',
      name: '默认时间表',
      sections: const [
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
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从 JSON 创建
  factory TimeTable.fromJson(Map<String, dynamic> json) {
    return TimeTable(
      id: json['id'] as String,
      name: json['name'] as String,
      sections: (json['sections'] as List)
          .map((e) => SectionTime.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sections': sections.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  TimeTable copyWith({
    String? id,
    String? name,
    List<SectionTime>? sections,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeTable(
      id: id ?? this.id,
      name: name ?? this.name,
      sections: sections ?? this.sections,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取指定节次的时间信息
  SectionTime? getSectionTime(int section) {
    if (section < 1 || section > sections.length) return null;
    return sections[section - 1];
  }

  /// 验证时间表是否有效
  bool get isValid {
    if (sections.isEmpty) return false;

    // 检查节次编号是否连续
    for (int i = 0; i < sections.length; i++) {
      if (sections[i].section != i + 1) return false;
    }

    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeTable &&
        other.id == id &&
        other.name == name &&
        _listEquals(other.sections, sections) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, Object.hashAll(sections), createdAt, updatedAt);

  /// 列表相等性比较辅助方法
  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
