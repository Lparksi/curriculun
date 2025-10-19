import '../models/course_import_models.dart';
import 'course_html_parser.dart';

/// 解析器注册表，顺序遍历已注册解析器并返回首个可处理的结果。
class CourseHtmlParserRegistry {
  CourseHtmlParserRegistry({
    List<CourseHtmlParser>? parsers,
  }) : _parsers = List<CourseHtmlParser>.from(parsers ?? const <CourseHtmlParser>[]);

  final List<CourseHtmlParser> _parsers;

  List<CourseHtmlParser> get parsers => List<CourseHtmlParser>.unmodifiable(_parsers);

  void register(CourseHtmlParser parser) {
    if (_parsers.any((existing) => existing.id == parser.id)) {
      throw ArgumentError('解析器 ID 重复: ${parser.id}');
    }
    _parsers.add(parser);
  }

  /// 顺序尝试解析，返回首个 `canHandle` 为 `true` 的解析结果。
  CourseImportParseResult? tryParse(CourseHtmlParsingContext context) {
    for (final parser in _parsers) {
      if (parser.canHandle(context)) {
        return parser.parse(context);
      }
    }
    return null;
  }
}
