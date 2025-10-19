import 'package:flutter/foundation.dart';

/// 原始 HTML 数据的封装，包含可选的来源地址，便于记录解析上下文。
class CourseImportSource {
  CourseImportSource({
    required this.rawContent,
    this.origin,
  });

  final String rawContent;
  final Uri? origin;
}

/// 解析出的课程实体，尚未绑定颜色等界面属性。
class ParsedCourse {
  ParsedCourse({
    required this.name,
    required this.weekday,
    required this.startSection,
    required this.duration,
    this.location = '',
    this.teacher = '',
    this.startWeek = 1,
    this.endWeek = 20,
    this.rawWeeks,
    this.rawSections,
    this.notes = const <String>[],
  }) : assert(
          weekday >= 1 && weekday <= 7,
          'weekday 需在 1-7 之间，实际为 $weekday',
        );

  final String name;
  final String location;
  final String teacher;
  final int weekday;
  final int startSection;
  final int duration;
  final int startWeek;
  final int endWeek;
  final String? rawWeeks;
  final String? rawSections;
  final List<String> notes;

  ParsedCourse copyWith({
    String? name,
    String? location,
    String? teacher,
    int? weekday,
    int? startSection,
    int? duration,
    int? startWeek,
    int? endWeek,
    String? rawWeeks,
    String? rawSections,
    List<String>? notes,
  }) {
    return ParsedCourse(
      name: name ?? this.name,
      location: location ?? this.location,
      teacher: teacher ?? this.teacher,
      weekday: weekday ?? this.weekday,
      startSection: startSection ?? this.startSection,
      duration: duration ?? this.duration,
      startWeek: startWeek ?? this.startWeek,
      endWeek: endWeek ?? this.endWeek,
      rawWeeks: rawWeeks ?? this.rawWeeks,
      rawSections: rawSections ?? this.rawSections,
      notes: notes ?? List<String>.from(this.notes),
    );
  }
}

/// 解析过程中产生的提示或告警。
class CourseImportMessage {
  const CourseImportMessage({
    required this.severity,
    required this.message,
    this.detail,
  });

  final ParserMessageSeverity severity;
  final String message;
  final String? detail;
}

/// 解析器整体状态，帮助上层判断下一步处理。
enum ParseStatus {
  success,
  partial,
  unsupported,
  needAdditionalInput,
  failed,
}

/// 解析器消息级别。
enum ParserMessageSeverity {
  info,
  warning,
  error,
}

/// 当页面包含 iframe 等子页面时，用于通知上层需要继续抓取。
class FrameRequest {
  FrameRequest({
    required this.src,
    this.description,
  });

  final String src;
  final String? description;
}

/// HTML 解析的输出结果。
class CourseImportParseResult {
  CourseImportParseResult({
    required this.parserId,
    required this.status,
    this.courses = const <ParsedCourse>[],
    this.messages = const <CourseImportMessage>[],
    this.frameRequests = const <FrameRequest>[],
    this.metadata = const <String, Object?>{},
  });

  final String parserId;
  final ParseStatus status;
  final List<ParsedCourse> courses;
  final List<CourseImportMessage> messages;
  final List<FrameRequest> frameRequests;
  final Map<String, Object?> metadata;

  bool get hasCourses => courses.isNotEmpty;
  bool get hasErrors =>
      messages.any((msg) => msg.severity == ParserMessageSeverity.error);
}

/// 上层导入服务的统一返回结构。
class CourseImportResult {
  CourseImportResult({
    required this.status,
    required this.courses,
    this.messages = const <CourseImportMessage>[],
    this.parserId,
    this.metadata = const <String, Object?>{},
    this.frameRequests = const <FrameRequest>[],
  });

  final ParseStatus status;
  final List<ParsedCourse> courses;
  final List<CourseImportMessage> messages;
  final String? parserId;
  final Map<String, Object?> metadata;
  final List<FrameRequest> frameRequests;

  bool get isSuccess => status == ParseStatus.success || status == ParseStatus.partial;
}

extension CourseImportMessageX on CourseImportMessage {
  @visibleForTesting
  bool get isWarning => severity == ParserMessageSeverity.warning;

  @visibleForTesting
  bool get isError => severity == ParserMessageSeverity.error;
}
