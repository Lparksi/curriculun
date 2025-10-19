import 'dart:math';

import 'package:html/dom.dart';

import '../models/course_import_models.dart';
import 'course_html_parser.dart';

class KingosoftCourseParser implements CourseHtmlParser {
  @override
  String get id => 'kingosoft.course_table';

  @override
  String get description => '青果教务系统课表页面解析器';

  @override
  bool canHandle(CourseHtmlParsingContext context) {
    final document = context.document;
    final title = document.querySelector('title')?.text ?? '';
    final hasBrand = title.contains('KINGOSOFT') ||
        context.normalizedHtml.contains('KINGOSOFT高校教学综合管理服务平台');
    final hasTable = document.querySelector('#kbtable') != null ||
        document.querySelector('.kbtable') != null;
    final hasFrame = document.querySelector('iframe#frmDesk') != null;
    return hasTable || (hasBrand && hasFrame);
  }

  @override
  CourseImportParseResult parse(CourseHtmlParsingContext context) {
    final document = context.document;
    final kbTable = document.querySelector('#kbtable') ??
        document.querySelector('table.kbtable');
    if (kbTable != null) {
      final courses = _parseCourseTable(kbTable);
      if (courses.isEmpty) {
        return CourseImportParseResult(
          parserId: id,
          status: ParseStatus.partial,
          courses: const <ParsedCourse>[],
          messages: const <CourseImportMessage>[
            CourseImportMessage(
              severity: ParserMessageSeverity.warning,
              message: '检测到课表表格，但未解析出任何课程信息',
            ),
          ],
        );
      }

      return CourseImportParseResult(
        parserId: id,
        status: ParseStatus.success,
        courses: courses,
        messages: [
          CourseImportMessage(
            severity: ParserMessageSeverity.info,
            message: '成功解析 ${courses.length} 门课程',
          ),
        ],
      );
    }

    final iframe = document.querySelector('iframe#frmDesk');
    if (iframe != null) {
      final src = iframe.attributes['src'] ?? '';
      return CourseImportParseResult(
        parserId: id,
        status: ParseStatus.needAdditionalInput,
        frameRequests: [
          FrameRequest(
            src: src,
            description: '学生课表 iframe 内容',
          ),
        ],
        messages: [
          CourseImportMessage(
            severity: ParserMessageSeverity.warning,
            message: '页面为门户框架，需要同时抓取 iframe 中的课表页面',
            detail:
                '请在 WebView 中执行 document.getElementById("frmDesk").contentWindow.document.documentElement.outerHTML 以获取课表 HTML。',
          ),
        ],
      );
    }

    return CourseImportParseResult(
      parserId: id,
      status: ParseStatus.unsupported,
      messages: const <CourseImportMessage>[
        CourseImportMessage(
          severity: ParserMessageSeverity.warning,
          message: '未检测到课表表格或 iframe，无法解析',
        ),
      ],
    );
  }

  List<ParsedCourse> _parseCourseTable(Element table) {
    final rows = table.querySelectorAll('tr');
    if (rows.length <= 1) {
      return const <ParsedCourse>[];
    }

    final headerCells =
        rows.first.children.where((element) => _isDataCell(element)).toList();
    final weekdayCount = headerCells.length;
    if (weekdayCount == 0) {
      return const <ParsedCourse>[];
    }

    final courses = <ParsedCourse>[];
    final rowSpanTracker = List<int>.filled(weekdayCount, 0);
    var inferredSection = 0;

    for (final row in rows.skip(1)) {
      final sectionNumber =
          _extractSectionNumber(row) ?? _fallbackSectionNumber(++inferredSection);
      final occupied = <int>{};

      for (var col = 0; col < weekdayCount; col++) {
        if (rowSpanTracker[col] > 0) {
          rowSpanTracker[col] -= 1;
          occupied.add(col);
        }
      }

      var cells =
          row.children.where((element) => _isDataCell(element)).toList();
      if (cells.isEmpty) {
        continue;
      }
      if (cells.length == weekdayCount + 1 ||
          _looksLikeSectionHeader(cells.first.text)) {
        cells = cells.sublist(1);
      }
      if (cells.isEmpty) {
        continue;
      }

      var dataCellIndex = 0;
      for (var columnIndex = 0;
          columnIndex < weekdayCount && dataCellIndex < cells.length;
          columnIndex++) {
        if (occupied.contains(columnIndex)) {
          continue;
        }

        final cell = cells[dataCellIndex];
        dataCellIndex++;

        final rowspan =
            int.tryParse(cell.attributes['rowspan'] ?? '1') ?? 1;
        if (rowspan > 1) {
          rowSpanTracker[columnIndex] = rowspan - 1;
        }

        final weekday = columnIndex + 1;
        final parsedCourses = _parseCourseCell(
          cell,
          weekday: weekday,
          startSection: sectionNumber,
          duration: rowspan,
        );
        courses.addAll(parsedCourses);
      }
    }

    return courses;
  }

  int? _extractSectionNumber(Element row) {
    if (row.children.isEmpty) return null;
    final firstCell = row.children.first;
    final text = firstCell.text.trim();
    final match =
        RegExp(r'第\s*(\d+)\s*节').firstMatch(text.replaceAll('\n', ' '));
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    final numeric = RegExp(r'^\d+$').firstMatch(text);
    if (numeric != null) {
      return int.tryParse(numeric.group(0)!);
    }
    return null;
  }

  int _fallbackSectionNumber(int candidate) => max(candidate, 1);

  bool _isDataCell(Element element) {
    final localName = element.localName;
    if (localName == null) return false;
    return localName == 'td' || localName == 'th';
  }

  bool _looksLikeSectionHeader(String? text) {
    if (text == null) return false;
    final content = text.trim();
    if (content.isEmpty) return false;
    if (RegExp(r'第\s*\d+\s*节').hasMatch(content)) {
      return true;
    }
    const separators = ['上午', '下午', '晚上', '节次'];
    return separators.any(content.contains);
  }

  List<ParsedCourse> _parseCourseCell(
    Element cell, {
    required int weekday,
    required int startSection,
    required int duration,
  }) {
    final courseNodes = cell.getElementsByClassName('kbcontent');
    if (courseNodes.isEmpty) {
      final lines = _extractLines(cell);
      final course = _parseCourseLines(
        lines,
        weekday: weekday,
        startSection: startSection,
        duration: duration,
      );
      return course != null ? <ParsedCourse>[course] : const <ParsedCourse>[];
    }

    final courses = <ParsedCourse>[];
    for (final node in courseNodes) {
      final lines = _extractLines(node);
      final course = _parseCourseLines(
        lines,
        weekday: weekday,
        startSection: startSection,
        duration: duration,
      );
      if (course != null) {
        courses.add(course);
      }
    }
    return courses;
  }

  List<String> _extractLines(Element element) {
    final buffer = StringBuffer();
    void writeNode(Node node) {
      if (node is Text) {
        buffer.write(node.text);
      } else if (node is Element) {
        if (node.localName == 'br') {
          buffer.write('\n');
        } else {
          for (final child in node.nodes) {
            writeNode(child);
          }
          if (node.localName == 'p') {
            buffer.write('\n');
          }
        }
      }
    }

    for (final node in element.nodes) {
      writeNode(node);
    }

    return buffer
        .toString()
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  ParsedCourse? _parseCourseLines(
    List<String> lines, {
    required int weekday,
    required int startSection,
    required int duration,
  }) {
    if (lines.isEmpty) return null;

    final name = lines.first;
    if (name.isEmpty || name == '&nbsp;') {
      return null;
    }

    String teacher = '';
    String location = '';
    var parsedStartWeek = 1;
    var parsedEndWeek = 20;
    var parsedStartSection = startSection;
    var parsedDuration = duration;
    String? rawWeekInfo;
    final notes = <String>[];

    for (final line in lines.skip(1)) {
      if (teacher.isEmpty && _looksLikeTeacher(line)) {
        teacher = _cleanupTeacher(line);
        continue;
      }

      final sectionMatch = RegExp(r'(\d+)(?:-(\d+))?节').firstMatch(line);
      final weekMatch = RegExp(r'(\d+)(?:-(\d+))?周').firstMatch(line);
      if (sectionMatch != null || weekMatch != null || line.contains('周')) {
        rawWeekInfo = line;
        if (weekMatch != null) {
          final startWeekStr = weekMatch.group(1)!;
          final endWeekStr = weekMatch.group(2) ?? startWeekStr;
          parsedStartWeek = int.tryParse(startWeekStr) ?? parsedStartWeek;
          parsedEndWeek = int.tryParse(endWeekStr) ?? parsedEndWeek;
        }
        if (sectionMatch != null) {
          final startSectionStr = sectionMatch.group(1)!;
          final endSectionStr = sectionMatch.group(2) ?? startSectionStr;
          final start = int.tryParse(startSectionStr) ?? parsedStartSection;
          final end = int.tryParse(endSectionStr) ?? start;
          parsedStartSection = start;
          parsedDuration = max(1, end - start + 1);
        }
        continue;
      }

      if (location.isEmpty) {
        location = line;
      } else {
        notes.add(line);
      }
    }

    return ParsedCourse(
      name: name,
      location: location,
      teacher: teacher,
      weekday: weekday,
      startSection: parsedStartSection,
      duration: parsedDuration,
      startWeek: parsedStartWeek,
      endWeek: parsedEndWeek,
      rawWeeks: rawWeekInfo,
      notes: notes,
    );
  }

  bool _looksLikeTeacher(String text) {
    return text.contains('教师') ||
        text.contains('老师') ||
        text.contains('任课');
  }

  String _cleanupTeacher(String text) {
    return text
        .replaceAll(RegExp(r'(任课)?教师[:：]?'), '')
        .replaceAll('老师', '')
        .trim();
  }
}
