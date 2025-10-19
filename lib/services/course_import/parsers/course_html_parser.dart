import 'package:html/dom.dart';

import '../models/course_import_models.dart';

/// 解析器执行时的上下文，包含原始 HTML、标准化后的 HTML 以及已解析的 DOM。
class CourseHtmlParsingContext {
  CourseHtmlParsingContext({
    required this.source,
    required this.normalizedHtml,
    required this.document,
  });

  final CourseImportSource source;
  final String normalizedHtml;
  final Document document;
}

/// HTML 解析器公共接口。
abstract class CourseHtmlParser {
  /// 唯一解析器 ID，用于日志与诊断。
  String get id;

  /// 用于描述解析器适用场景。
  String get description;

  /// 判定当前解析器是否适合处理给定上下文。
  bool canHandle(CourseHtmlParsingContext context);

  /// 执行解析并返回结果。
  CourseImportParseResult parse(CourseHtmlParsingContext context);
}
