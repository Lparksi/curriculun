/// Firebase 功能同意配置
///
/// 用于存储用户对各项 Firebase 功能的同意选择
class FirebaseConsent {
  /// 是否已显示过同意对话框
  final bool hasShown;

  /// 是否同意使用 Crashlytics（崩溃报告）
  final bool crashlyticsEnabled;

  /// 是否同意使用 Performance Monitoring（性能监控）
  final bool performanceEnabled;

  /// 是否同意使用 Analytics（数据分析）
  final bool analyticsEnabled;

  const FirebaseConsent({
    this.hasShown = false,
    this.crashlyticsEnabled = false,
    this.performanceEnabled = false,
    this.analyticsEnabled = false,
  });

  /// 是否启用了任何 Firebase 功能
  bool get hasAnyEnabled =>
      crashlyticsEnabled || performanceEnabled || analyticsEnabled;

  /// 从 JSON 反序列化
  factory FirebaseConsent.fromJson(Map<String, dynamic> json) {
    return FirebaseConsent(
      hasShown: json['hasShown'] as bool? ?? false,
      crashlyticsEnabled: json['crashlyticsEnabled'] as bool? ?? false,
      performanceEnabled: json['performanceEnabled'] as bool? ?? false,
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? false,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'hasShown': hasShown,
      'crashlyticsEnabled': crashlyticsEnabled,
      'performanceEnabled': performanceEnabled,
      'analyticsEnabled': analyticsEnabled,
    };
  }

  /// 创建副本
  FirebaseConsent copyWith({
    bool? hasShown,
    bool? crashlyticsEnabled,
    bool? performanceEnabled,
    bool? analyticsEnabled,
  }) {
    return FirebaseConsent(
      hasShown: hasShown ?? this.hasShown,
      crashlyticsEnabled: crashlyticsEnabled ?? this.crashlyticsEnabled,
      performanceEnabled: performanceEnabled ?? this.performanceEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }

  @override
  String toString() {
    return 'FirebaseConsent(hasShown: $hasShown, '
        'crashlytics: $crashlyticsEnabled, '
        'performance: $performanceEnabled, '
        'analytics: $analyticsEnabled)';
  }
}
