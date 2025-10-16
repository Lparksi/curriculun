/// 学期设置数据模型
class SemesterSettings {
  final DateTime startDate; // 学期开始日期
  final int totalWeeks; // 学期总周数

  const SemesterSettings({
    required this.startDate,
    required this.totalWeeks,
  });

  /// 默认设置
  factory SemesterSettings.defaultSettings() {
    return SemesterSettings(
      startDate: DateTime(2025, 9, 1),
      totalWeeks: 20,
    );
  }

  /// 从 JSON 创建
  factory SemesterSettings.fromJson(Map<String, dynamic> json) {
    return SemesterSettings(
      startDate: DateTime.parse(json['startDate'] as String),
      totalWeeks: json['totalWeeks'] as int,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'totalWeeks': totalWeeks,
    };
  }

  /// 复制并修改
  SemesterSettings copyWith({
    DateTime? startDate,
    int? totalWeeks,
  }) {
    return SemesterSettings(
      startDate: startDate ?? this.startDate,
      totalWeeks: totalWeeks ?? this.totalWeeks,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemesterSettings &&
        other.startDate == startDate &&
        other.totalWeeks == totalWeeks;
  }

  @override
  int get hashCode => Object.hash(startDate, totalWeeks);
}
