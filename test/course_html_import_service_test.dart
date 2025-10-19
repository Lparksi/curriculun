import 'dart:io';

import 'package:curriculum/services/course_import/course_html_import_service.dart';
import 'package:curriculum/services/course_import/models/course_import_models.dart';
import 'package:curriculum/services/course_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

      final course3 =
          result.courses.firstWhere((c) => c.name == '大学英语');
      expect(course3.weekday, 2);
      expect(course3.startSection, 3);
      expect(course3.duration, 1);
      expect(course3.startWeek, 1);
      expect(course3.endWeek, 8);
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
