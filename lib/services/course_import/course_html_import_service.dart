import 'package:html/parser.dart' as html_parser;

import '../../models/course.dart';
import '../../utils/course_colors.dart';
import '../course_service.dart';
import 'models/course_import_models.dart';
import 'utils/html_normalizer.dart';
import 'parsers/course_html_parser.dart';
import 'parsers/course_html_parser_registry.dart';
import 'parsers/kingosoft_course_parser.dart';

/// HTML 解析入口服务，负责标准化 HTML、分发至具体解析器并生成 [Course] 列表。
class CourseHtmlImportService {
  CourseHtmlImportService({
    CourseHtmlParserRegistry? registry,
  }) : _registry = registry ??
            CourseHtmlParserRegistry(
              parsers: <CourseHtmlParser>[
                KingosoftCourseParser(),
              ],
            );

  final CourseHtmlParserRegistry _registry;

  /// 解析 HTML 并返回结果，不会写入本地存储。
  CourseImportResult parseHtml(CourseImportSource source) {
    final normalizedHtml = normalizeHtml(source.rawContent);
    if (normalizedHtml.isEmpty) {
      return CourseImportResult(
        status: ParseStatus.failed,
        courses: const <ParsedCourse>[],
        messages: const <CourseImportMessage>[
          CourseImportMessage(
            severity: ParserMessageSeverity.error,
            message: 'HTML 内容为空，无法解析',
          ),
        ],
      );
    }

    final document = html_parser.parse(normalizedHtml);
    final context = CourseHtmlParsingContext(
      source: source,
      normalizedHtml: normalizedHtml,
      document: document,
    );

    final parseResult = _registry.tryParse(context);
    if (parseResult == null) {
    return CourseImportResult(
      status: ParseStatus.unsupported,
      courses: const <ParsedCourse>[],
      messages: const <CourseImportMessage>[
        CourseImportMessage(
            severity: ParserMessageSeverity.warning,
            message: '未找到可处理此页面的解析器',
          ),
        ],
      );
    }

    return CourseImportResult(
      status: parseResult.status,
      courses: parseResult.courses,
      messages: parseResult.messages,
      parserId: parseResult.parserId,
      metadata: parseResult.metadata,
      frameRequests: parseResult.frameRequests,
    );
  }

  /// 将解析出的课程写入 [CourseService]，会自动分配颜色。
  Future<CourseImportResult> importAndPersist(
    CourseImportSource source,
  ) async {
    final result = parseHtml(source);
    if (!result.isSuccess || result.courses.isEmpty) {
      return result;
    }

    await persistParsedCourses(result.courses, append: true);
    return result;
  }

  /// 根据解析结果持久化到本地课程表。
  Future<void> persistParsedCourses(
    List<ParsedCourse> parsedCourses, {
    required bool append,
  }) async {
    if (parsedCourses.isEmpty) {
      return;
    }

    final existingCourses = await CourseService.loadAllCourses();

    CourseColorManager.reset();
    CourseColorManager.presetColors({
      for (final course in existingCourses) course.name: course.color,
    });

    final targetCourses = append
        ? List<Course>.from(existingCourses)
        : <Course>[];

    targetCourses.addAll(
      parsedCourses.map(_mapParsedCourse).whereType<Course>(),
    );

    await CourseService.saveCourses(targetCourses);
  }

  Course? _mapParsedCourse(ParsedCourse parsed) {
    if (parsed.name.isEmpty) {
      return null;
    }
    final duration = parsed.duration < 1 ? 1 : parsed.duration;
    return Course(
      name: parsed.name,
      location: parsed.location,
      teacher: parsed.teacher,
      weekday: parsed.weekday,
      startSection: parsed.startSection,
      duration: duration,
      startWeek: parsed.startWeek,
      endWeek: parsed.endWeek,
      color: CourseColorManager.getColorForCourse(parsed.name),
    );
  }
}
