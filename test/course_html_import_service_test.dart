import 'dart:io';

import 'package:curriculum/services/course_import/course_html_import_service.dart';
import 'package:curriculum/services/course_import/models/course_import_models.dart';
import 'package:curriculum/services/course_import/parsers/course_html_parser.dart';
import 'package:curriculum/services/course_import/parsers/kingosoft_course_parser.dart';
import 'package:curriculum/services/course_import/utils/html_normalizer.dart';
import 'package:curriculum/services/course_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html_parser;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CourseHtmlImportService', () {
    late CourseHtmlImportService service;

    setUp(() {
      service = CourseHtmlImportService();
    });

    test('normalize and detect Kingosoft portal iframe', () {
      final html = File('codetest/1.html').readAsStringSync();
      final source = CourseImportSource(rawContent: html);

      final result = service.parseHtml(source);

      expect(result.status, ParseStatus.needAdditionalInput);
      expect(result.parserId, 'kingosoft.course_table');
      expect(result.messages, isNotEmpty);
      expect(result.frameRequests, isNotEmpty);
      expect(
        result.frameRequests.first.src,
        contains('/student/xkjg.wdkb.jsp'),
      );
    });

    test('parse Kingosoft timetable table', () async {
      const sampleHtml = '''
      <html>
        <head><title>KINGOSOFT高校教学综合管理服务平台</title></head>
        <body>
          <table id="kbtable">
            <tr>
              <th>节次</th>
              <th>星期一</th>
              <th>星期二</th>
              <th>星期三</th>
              <th>星期四</th>
              <th>星期五</th>
              <th>星期六</th>
              <th>星期日</th>
            </tr>
            <tr>
              <th>第1节</th>
              <td rowspan="2">
                <div class="kbcontent">
                  软件工程导论<br>
                  任课教师：张老师<br>
                  1-16周 第1-2节<br>
                  崇文楼201
                </div>
              </td>
              <td></td>
              <td rowspan="2">
                <div class="kbcontent">
                  数据结构<br>
                  李老师<br>
                  1-16周 第1-2节<br>
                  崇文楼305
                </div>
              </td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <th>第2节</th>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
            <tr>
              <th>第3节</th>
              <td></td>
              <td>
                <div class="kbcontent">
                  大学英语<br>
                  1-8周 第3节<br>
                  第一教学楼101
                </div>
              </td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
              <td></td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final normalized = normalizeHtml(sampleHtml);
      final document = html_parser.parse(normalized);
      final context = CourseHtmlParsingContext(
        source: CourseImportSource(rawContent: sampleHtml),
        normalizedHtml: normalized,
        document: document,
      );
      final parser = KingosoftCourseParser();

      expect(parser.canHandle(context), isTrue);

      final parserResult = parser.parse(context);
      expect(parserResult.status, isNot(ParseStatus.unsupported));
      expect(parserResult.courses.length, 3);

      final result = service.parseHtml(
        CourseImportSource(rawContent: sampleHtml),
      );

      expect(result.status, ParseStatus.success);
      expect(result.courses.length, 3);

      final course1 = result.courses[0];
      expect(course1.name, '软件工程导论');
      expect(course1.teacher, '张');
      expect(course1.location, '崇文楼201');
      expect(course1.weekday, 1);
      expect(course1.startSection, 1);
      expect(course1.duration, 2);
      expect(course1.startWeek, 1);
      expect(course1.endWeek, 16);

      final course3 = result.courses.firstWhere((c) => c.name == '大学英语');
      expect(course3.weekday, 2);
      expect(course3.startSection, 3);
      expect(course3.duration, 1);
      expect(course3.startWeek, 1);
      expect(course3.endWeek, 8);
    });

    test('parse Kingosoft new two-dimensional table format', () {
      const sampleHtml = '''
      <html>
        <head><title>教学综合管理服务平台</title></head>
        <body>
          <h2>学生个人课表</h2>
          <table class="layui-table">
            <tr>
              <th>节次</th>
              <th>星期一</th>
              <th>星期二</th>
            </tr>
            <tr>
              <th>第1节</th>
              <td>
                <div>
                  大学体育（三）<br>
                  王建峰<br>
                  1-16[1-2]<br>
                  篮球场(文明)
                </div>
              </td>
              <td>
                <div>
                  大学英语（三）<br>
                  奚泽洋<br>
                  1-12[3-4]<br>
                  科技楼213
                </div>
              </td>
            </tr>
            <tr>
              <th>第3节</th>
              <td>
                <div>
                  马克思主义基本原理<br>
                  木忆文<br>
                  1-16[5-6]<br>
                  科技楼215
                </div>
              </td>
              <td>
                <div>
                  面向对象程序设计实验<br>
                  郭磊<br>
                  3,5,16[7-8]<br>
                  科技楼214
                </div>
              </td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final normalized = normalizeHtml(sampleHtml);
      final document = html_parser.parse(normalized);
      final context = CourseHtmlParsingContext(
        source: CourseImportSource(rawContent: sampleHtml),
        normalizedHtml: normalized,
        document: document,
      );
      final parser = KingosoftCourseParser();
      final canHandle = parser.canHandle(context);
      expect(canHandle, isTrue);

      final parserResult = parser.parse(context);
      expect(parserResult.status, isNot(ParseStatus.unsupported));
      expect(parserResult.courses.length, 4);

      final result = service.parseHtml(
        CourseImportSource(rawContent: sampleHtml),
      );

      expect(result.status, ParseStatus.success);
      expect(result.courses.length, 4);

      final sportCourse = result.courses.firstWhere(
        (course) => course.name.contains('体育'),
      );
      expect(sportCourse.teacher, '王建峰');
      expect(sportCourse.location, '篮球场(文明)');
      expect(sportCourse.startSection, 1);
      expect(sportCourse.duration, 2);
      expect(sportCourse.startWeek, 1);
      expect(sportCourse.endWeek, 16);
      expect(sportCourse.rawWeeks, contains('1-16'));

      final oopLab = result.courses.firstWhere(
        (course) => course.name.contains('面向对象程序设计实验'),
      );
      expect(oopLab.teacher, '郭磊');
      expect(oopLab.location, '科技楼214');
      expect(oopLab.startSection, 7);
      expect(oopLab.duration, 2);
      expect(oopLab.startWeek, 3);
      expect(oopLab.endWeek, 16);
      expect(oopLab.rawWeeks, contains('3,5,16'));
      expect(oopLab.notes.any((note) => note.contains('原始周次')), isTrue);
    });

    test('import and persist should append parsed courses', () async {
      SharedPreferences.setMockInitialValues({});

      const sampleHtml = '''
      "<html><head><title>KINGOSOFT高校教学综合管理服务平台</title></head><body>
      <table id="kbtable">
        <tr>
          <th>节次</th>
          <th>星期一</th>
        </tr>
        <tr>
          <th>第1节</th>
          <td>
            <div class="kbcontent">
              线性代数<br>
              王老师<br>
              1-16周 第1节<br>
              二教201
            </div>
          </td>
        </tr>
      </table>
      </body></html>"
      ''';

      final result = await service.importAndPersist(
        CourseImportSource(rawContent: sampleHtml),
      );

      expect(result.isSuccess, isTrue);
      expect(result.courses.length, 1);

      final storedCourses = await CourseService.loadAllCourses();
      expect(storedCourses.length, 1);
      expect(storedCourses.first.name, '线性代数');

      // 再次解析，验证颜色映射不报错且不会重复添加。
      final result2 = service.parseHtml(
        CourseImportSource(rawContent: sampleHtml),
      );
      expect(result2.courses.length, 1);
    });

    test('persistParsedCourses supports replace mode', () async {
      SharedPreferences.setMockInitialValues({});

      const firstHtml = '''
      <html>
        <head><title>KINGOSOFT高校教学综合管理服务平台</title></head>
        <body>
          <table id="kbtable">
            <tr>
              <th>节次</th>
              <th>星期一</th>
            </tr>
            <tr>
              <th>第1节</th>
              <td>
                <div class="kbcontent">
                  线性代数<br>
                  张老师<br>
                  1-16周 第1节<br>
                  二教201
                </div>
              </td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      const secondHtml = '''
      <html>
        <head><title>KINGOSOFT高校教学综合管理服务平台</title></head>
        <body>
          <table id="kbtable">
            <tr>
              <th>节次</th>
              <th>星期二</th>
            </tr>
            <tr>
              <th>第3节</th>
              <td>
                <div class="kbcontent">
                  高等数学<br>
                  李老师<br>
                  5-12周 第3-4节<br>
                  一教105
                </div>
              </td>
            </tr>
          </table>
        </body>
      </html>
      ''';

      final firstResult = service.parseHtml(
        CourseImportSource(rawContent: firstHtml),
      );
      expect(firstResult.courses.length, 1);
      await service.persistParsedCourses(firstResult.courses, append: true);

      var stored = await CourseService.loadAllCourses();
      expect(stored.length, 1);
      expect(stored.first.name, '线性代数');

      final secondResult = service.parseHtml(
        CourseImportSource(rawContent: secondHtml),
      );
      expect(secondResult.courses.length, 1);

      await service.persistParsedCourses(secondResult.courses, append: false);

      stored = await CourseService.loadAllCourses();
      expect(stored.length, 1);
      expect(stored.first.name, '高等数学');
      expect(stored.first.startSection, 3);
      expect(stored.first.duration, 2);
    });
  });
}
