import 'dart:math';

import 'package:html/dom.dart';

import '../models/course_import_models.dart';
import 'course_html_parser.dart';

class KingosoftCourseParser implements CourseHtmlParser {
  static const List<String> _weekdayKeywords = <String>[
    '星期一',
    '星期二',
    '星期三',
    '星期四',
    '星期五',
    '星期六',
    '星期日',
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  @override
  String get id => 'kingosoft.course_table';

  @override
  String get description => '青果教务系统课表页面解析器';

  @override
  bool canHandle(CourseHtmlParsingContext context) {
    final document = context.document;
    final title = document.querySelector('title')?.text ?? '';
    final normalized = context.normalizedHtml;
    final host = context.source.origin?.host ?? '';
    final bodyText = document.body?.text ?? '';

    final hasBrandKeyword = <String>[
      'KINGOSOFT',
      '教学综合管理服务平台',
      '教务综合管理服务平台',
    ].any((keyword) => title.contains(keyword) || normalized.contains(keyword));

    final isKingosoftDomain =
        host.contains('jwgl') ||
        host.contains('kingosoft') ||
        normalized.contains('KINGOSOFT高校教学综合管理服务平台');

    final hasTable = _findTimetableTable(document) != null;

    final hasPortalFrame =
        document.querySelector('iframe#frmDesk') != null ||
        document.querySelector('iframe[name="frmDesk"]') != null ||
        document.querySelector('iframe[src*="kbcx"]') != null ||
        document.querySelector('iframe[src*="wdkb"]') != null;

    final hasCourseText =
        bodyText.contains('学生个人课表') ||
        bodyText.contains('学生课表') ||
        bodyText.contains('课表查询');

    return hasTable ||
        (hasPortalFrame && (hasBrandKeyword || isKingosoftDomain)) ||
        ((hasBrandKeyword || isKingosoftDomain) && hasCourseText);
  }

  @override
  CourseImportParseResult parse(CourseHtmlParsingContext context) {
    final document = context.document;
    final kbTable = _findTimetableTable(document);
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

    // 查找常见的课表 iframe
    final iframe =
        document.querySelector('iframe#frmDesk') ??
        document.querySelector('iframe[name="frmDesk"]') ??
        document.querySelector('iframe[src*="kbcx"]') ??
        document.querySelector('iframe[src*="wdkb"]');
    if (iframe != null) {
      final src = iframe.attributes['src'] ?? '';
      return CourseImportParseResult(
        parserId: id,
        status: ParseStatus.needAdditionalInput,
        frameRequests: [FrameRequest(src: src, description: '学生课表 iframe 内容')],
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

    // 如果是青果系统但没有找到课表表格和特定iframe，尝试查找所有iframe
    final title = document.querySelector('title')?.text ?? '';
    final normalized = context.normalizedHtml;
    final hasBrandKeyword = <String>[
      'KINGOSOFT',
      '教学综合管理服务平台',
      '教务综合管理服务平台',
    ].any((keyword) => title.contains(keyword) || normalized.contains(keyword));

    if (hasBrandKeyword) {
      final allIframes = document.querySelectorAll('iframe');
      if (allIframes.isNotEmpty) {
        // 返回所有iframe的请求，让应用尝试抓取
        final frameRequests = allIframes
            .map((iframe) => FrameRequest(
                  src: iframe.attributes['src'] ?? '',
                  description: 'iframe 内容',
                ))
            .where((request) => request.src.isNotEmpty)
            .toList();
        
        if (frameRequests.isNotEmpty) {
          return CourseImportParseResult(
            parserId: id,
            status: ParseStatus.needAdditionalInput,
            frameRequests: frameRequests,
            messages: [
              CourseImportMessage(
                severity: ParserMessageSeverity.info,
                message: '检测到 ${frameRequests.length} 个 iframe，将尝试自动抓取课表内容',
              ),
            ],
          );
        }
      }
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

  Element? _findTimetableTable(Document document) {
    // 直接查找常见的课表表格ID和类名
    final direct =
        document.querySelector('#kbtable') ??
        document.querySelector('table.kbtable') ??
        document.querySelector('#mytable') ??  // 安阳师范学院等系统
        document.querySelector('table#mytable');
    if (direct != null) {
      return direct;
    }

    Element? bestMatch;
    var bestScore = 0;
    for (final table in document.getElementsByTagName('table')) {
      final text = table.text;
      if (text.trim().isEmpty) {
        continue;
      }
      final hits = _weekdayKeywords
          .where((keyword) => text.contains(keyword))
          .length;
      
      // 扩展节次提示的检测，支持更多格式
      final hasSectionHints =
          text.contains('节次') ||
          RegExp(r'第\s*\d+\s*节').hasMatch(text) ||
          // 支持"上午"、"下午"、"晚上"这种时间段标记
          (text.contains('上午') || text.contains('下午') || text.contains('晚上'));
      
      if (hits >= 2 && hasSectionHints && hits >= bestScore) {
        bestMatch = table;
        bestScore = hits;
      }
    }
    return bestMatch;
  }

  List<ParsedCourse> _parseCourseTable(Element table) {
    final rows = table.querySelectorAll('tr');
    if (rows.length <= 1) {
      return const <ParsedCourse>[];
    }

    final headerCells = rows.first.children
        .where((element) => _isDataCell(element))
        .toList();
    final weekdayCount = headerCells.length;
    if (weekdayCount == 0) {
      return const <ParsedCourse>[];
    }

    final courses = <ParsedCourse>[];
    final rowSpanTracker = List<int>.filled(weekdayCount, 0);
    var inferredSection = 0;

    for (final row in rows.skip(1)) {
      final sectionNumber =
          _extractSectionNumber(row) ??
          _fallbackSectionNumber(++inferredSection);
      final occupied = <int>{};

      for (var col = 0; col < weekdayCount; col++) {
        if (rowSpanTracker[col] > 0) {
          rowSpanTracker[col] -= 1;
          occupied.add(col);
        }
      }

      var cells = row.children
          .where((element) => _isDataCell(element))
          .toList();
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
      for (
        var columnIndex = 0;
        columnIndex < weekdayCount && dataCellIndex < cells.length;
        columnIndex++
      ) {
        if (occupied.contains(columnIndex)) {
          continue;
        }

        final cell = cells[dataCellIndex];
        dataCellIndex++;

        final rowspan = int.tryParse(cell.attributes['rowspan'] ?? '1') ?? 1;
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
    final match = RegExp(
      r'第\s*(\d+)\s*节',
    ).firstMatch(text.replaceAll('\n', ' '));
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
    // 跳过节次标记单元格（通常有 td1 类）
    final cellClass = cell.attributes['class'] ?? '';
    if (cellClass.contains('td1')) {
      return const <ParsedCourse>[];
    }

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
    String? rawSectionInfo;
    final notes = <String>[];

    for (final rawLine in lines.skip(1)) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      if (teacher.isEmpty && _looksLikeTeacher(line)) {
        teacher = _cleanupTeacher(line);
        if (teacher.isNotEmpty) {
          continue;
        }
      }

      final schedule = _parseScheduleLine(line);
      if (schedule != null) {
        if (schedule.startWeek != null) {
          parsedStartWeek = schedule.startWeek!;
        }
        if (schedule.endWeek != null) {
          parsedEndWeek = schedule.endWeek!;
        }
        if (schedule.startSection != null) {
          parsedStartSection = schedule.startSection!;
        }
        if (schedule.endSection != null) {
          final end = schedule.endSection!;
          parsedDuration = max(1, end - parsedStartSection + 1);
        }
        rawWeekInfo ??= schedule.weekRaw;
        rawSectionInfo ??= schedule.sectionRaw;
        if (schedule.extraNote != null) {
          notes.add(schedule.extraNote!);
        }
        continue;
      }

      if (teacher.isEmpty && _looksLikePlainTeacher(line)) {
        teacher = line;
        continue;
      }

      if (location.isEmpty ||
          (!_looksLikeLocation(location) && _looksLikeLocation(line))) {
        if (location.isEmpty) {
          location = line;
        } else if (_looksLikeLocation(line)) {
          notes.add(location);
          location = line;
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
      rawSections: rawSectionInfo,
      notes: notes,
    );
  }

  bool _looksLikeTeacher(String text) {
    return text.contains('教师') || text.contains('老师') || text.contains('任课');
  }

  String _cleanupTeacher(String text) {
    return text
        .replaceAll(RegExp(r'(任课)?教师[:：]?'), '')
        .replaceAll('老师', '')
        .trim();
  }

  bool _looksLikePlainTeacher(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (RegExp(r'[0-9０-９]').hasMatch(trimmed)) {
      return false;
    }
    if (_looksLikeLocation(trimmed)) {
      return false;
    }
    return RegExp(r'^[\u4e00-\u9fa5·]{2,6}$').hasMatch(trimmed);
  }

  bool _looksLikeLocation(String text) {
    if (RegExp(r'[0-9０-９]').hasMatch(text)) {
      return true;
    }
    const keywords = ['楼', '室', '馆', '中心', '厅', '场', '院', '实验'];
    return keywords.any(text.contains);
  }

  _ScheduleParseResult? _parseScheduleLine(String line) {
    final normalized = line.replaceAll(RegExp(r'\s+'), '');
    if (!(normalized.contains('周') ||
        normalized.contains('节') ||
        normalized.contains('['))) {
      return null;
    }

    int? startWeek;
    int? endWeek;
    int? startSection;
    int? endSection;
    String? weekRaw;
    String? sectionRaw;
    String? extraNote;

    final bracketMatch = RegExp(
      r'^([0-9,，、\-]+)\[([0-9,，、\-]+)\]',
    ).firstMatch(normalized);
    if (bracketMatch != null) {
      final weeksSpec = bracketMatch.group(1)!;
      final sectionsSpec = bracketMatch.group(2)!;
      final weekRange = _parseNumberRangeSpec(weeksSpec);
      if (weekRange != null) {
        startWeek = weekRange.start;
        endWeek = weekRange.end;
        weekRaw = line;
        if (!weekRange.isContinuous) {
          extraNote ??= '原始周次：$weeksSpec';
        }
      }
      final sectionRange = _parseNumberRangeSpec(sectionsSpec);
      if (sectionRange != null) {
        startSection = sectionRange.start;
        endSection = sectionRange.end;
        sectionRaw = line;
        if (!sectionRange.isContinuous) {
          extraNote ??= '原始节次：$sectionsSpec';
        }
      }
    }

    final weekMatch = RegExp(r'(\d+)(?:-(\d+))?周').firstMatch(line);
    if (weekMatch != null) {
      final startWeekStr = weekMatch.group(1)!;
      final endWeekStr = weekMatch.group(2) ?? startWeekStr;
      final parsedStart = int.tryParse(startWeekStr);
      final parsedEnd = int.tryParse(endWeekStr);
      if (parsedStart != null) {
        startWeek = parsedStart;
        endWeek = parsedEnd ?? parsedStart;
        weekRaw ??= line;
      }
    }

    final sectionMatch = RegExp(r'(?:第)?(\d+)(?:-(\d+))?节').firstMatch(line);
    if (sectionMatch != null) {
      final startSectionStr = sectionMatch.group(1)!;
      final endSectionStr = sectionMatch.group(2) ?? startSectionStr;
      final parsedStart = int.tryParse(startSectionStr);
      final parsedEnd = int.tryParse(endSectionStr);
      if (parsedStart != null) {
        startSection = parsedStart;
        endSection = parsedEnd ?? parsedStart;
        sectionRaw ??= line;
      }
    }

    if (startWeek == null &&
        endWeek == null &&
        startSection == null &&
        endSection == null) {
      return null;
    }

    return _ScheduleParseResult(
      startWeek: startWeek,
      endWeek: endWeek,
      startSection: startSection,
      endSection: endSection,
      weekRaw: weekRaw,
      sectionRaw: sectionRaw,
      extraNote: extraNote,
    );
  }

  _NumberRange? _parseNumberRangeSpec(String spec) {
    final cleaned = spec.replaceAll(RegExp(r'[^0-9,，、\-]'), '');
    if (cleaned.isEmpty) {
      return null;
    }
    final tokens = cleaned
        .split(RegExp(r'[，,、]'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) {
      return null;
    }

    int? minValue;
    int? maxValue;
    for (final token in tokens) {
      if (token.contains('-')) {
        final parts = token
            .split('-')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
        if (parts.isEmpty) {
          continue;
        }
        final start = int.tryParse(parts.first);
        final end = int.tryParse(parts.length > 1 ? parts.last : parts.first);
        if (start == null) {
          continue;
        }
        final normalizedStart = start;
        final normalizedEnd = end ?? start;
        minValue = minValue == null
            ? min(normalizedStart, normalizedEnd)
            : min(minValue, min(normalizedStart, normalizedEnd));
        maxValue = maxValue == null
            ? max(normalizedStart, normalizedEnd)
            : max(maxValue, max(normalizedStart, normalizedEnd));
      } else {
        final value = int.tryParse(token);
        if (value == null) {
          continue;
        }
        minValue = minValue == null ? value : min(minValue, value);
        maxValue = maxValue == null ? value : max(maxValue, value);
      }
    }

    if (minValue == null || maxValue == null) {
      return null;
    }

    final isContinuous =
        !(spec.contains(',') || spec.contains('，') || spec.contains('、'));

    return _NumberRange(
      start: minValue,
      end: maxValue,
      isContinuous: isContinuous,
    );
  }
}

class _ScheduleParseResult {
  const _ScheduleParseResult({
    this.startWeek,
    this.endWeek,
    this.startSection,
    this.endSection,
    this.weekRaw,
    this.sectionRaw,
    this.extraNote,
  });

  final int? startWeek;
  final int? endWeek;
  final int? startSection;
  final int? endSection;
  final String? weekRaw;
  final String? sectionRaw;
  final String? extraNote;
}

class _NumberRange {
  const _NumberRange({
    required this.start,
    required this.end,
    required this.isContinuous,
  });

  final int start;
  final int end;
  final bool isContinuous;
}
