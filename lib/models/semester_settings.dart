/// 学期设置数据模型
class SemesterSettings {
  final String id; // 学期唯一标识
  final String name; // 学期名称 (例如: "2025春季学期", "大三上学期")
  final DateTime startDate; // 学期开始日期
  final int totalWeeks; // 学期总周数
  final DateTime createdAt; // 创建时间
  final DateTime updatedAt; // 更新时间

  const SemesterSettings({
    required this.id,
    required this.name,
    required this.startDate,
    required this.totalWeeks,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 默认设置
  factory SemesterSettings.defaultSettings() {
    final now = DateTime.now();
    return SemesterSettings(
      id: 'semester_${now.millisecondsSinceEpoch}',
      name: '默认学期',
      startDate: DateTime(2025, 9, 1),
      totalWeeks: 20,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从 JSON 创建
  factory SemesterSettings.fromJson(Map<String, dynamic> json) {
    return SemesterSettings(
      id:
          json['id'] as String? ??
          'semester_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? '未命名学期',
      startDate: DateTime.parse(json['startDate'] as String),
      totalWeeks: json['totalWeeks'] as int,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'totalWeeks': totalWeeks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  SemesterSettings copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    int? totalWeeks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SemesterSettings(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取学期结束日期
  DateTime get endDate {
    return startDate.add(Duration(days: totalWeeks * 7));
  }

  /// 格式化的日期范围文字
  String get dateRangeText {
    final end = endDate;
    return '${startDate.year}年${startDate.month}月${startDate.day}日 - ${end.year}年${end.month}月${end.day}日';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemesterSettings &&
        other.id == id &&
        other.name == name &&
        other.startDate == startDate &&
        other.totalWeeks == totalWeeks;
  }

  @override
  int get hashCode => Object.hash(id, name, startDate, totalWeeks);
}
