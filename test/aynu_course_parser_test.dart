import 'package:flutter_test/flutter_test.dart';
import 'package:curriculum/services/course_import/parsers/kingosoft_course_parser.dart';
import 'package:curriculum/services/course_import/parsers/course_html_parser.dart';
import 'package:curriculum/services/course_import/models/course_import_models.dart';
import 'package:html/parser.dart' as html_parser;

void main() {
  group('安阳师范学院课程表解析测试', () {
    test('应该能识别安阳师范学院的课程表', () {
      // 安阳师范学院的实际HTML结构（简化版）
      final html = '''
<html>
<body>
  <table class="table" id="mytable">
    <tbody>
      <tr class="H">
        <td class="td0"></td>
        <td class="td0">星期一</td>
        <td class="td0">星期二</td>
        <td class="td0">星期三</td>
        <td class="td0">星期四</td>
        <td class="td0">星期五</td>
        <td class="td0">星期六</td>
        <td class="td0">星期日</td>
      </tr>
      <tr>
        <td class="td1" rowspan="2">
          <div><b>上<br>午</b></div>
        </td>
        <td class="td1"><b>一</b></td>
        <td class="td">
          <div style="padding-bottom:5px;clear:both;">
            <font style="font-weight: bolder">大学体育（三）</font><br>
            王银晖 <br>
            1-16[1-2]<br>
            篮球场(文明)
          </div>
        </td>
        <td class="td">
          <div style="padding-bottom:5px;clear:both;">
            <font style="font-weight: bolder">大学英语（三）</font><br>
            秦清玲 <br>
            1-12[1-2]<br>
            科技馆213
          </div>
        </td>
        <td class="td">
          <div class="div_nokb" id="k31"></div>
        </td>
        <td class="td">
          <div class="div_nokb" id="k41"></div>
        </td>
        <td class="td">
          <div class="div_nokb" id="k51"></div>
        </td>
        <td class="td">
          <div class="div_nokb" id="k61"></div>
        </td>
        <td class="td">
          <div class="div_nokb" id="k71"></div>
        </td>
      </tr>
    </tbody>
  </table>
</body>
</html>
      ''';

      final document = html_parser.parse(html);
      final parser = KingosoftCourseParser();
      final context = CourseHtmlParsingContext(
        source: CourseImportSource(rawContent: html),
        normalizedHtml: html,
        document: document,
      );

      // 测试是否能识别
      final canHandle = parser.canHandle(context);
      print('canHandle: $canHandle');
      
      // 测试解析结果
      final result = parser.parse(context);
      print('Parse status: ${result.status}');
      print('Courses found: ${result.courses.length}');
      
      for (var course in result.courses) {
        print('Course: ${course.name}, Teacher: ${course.teacher}, Location: ${course.location}');
        print('  Weekday: ${course.weekday}, Section: ${course.startSection}-${course.startSection + course.duration - 1}');
        print('  Weeks: ${course.startWeek}-${course.endWeek}');
      }

      expect(canHandle, isTrue, reason: '应该能识别安阳师范学院的课程表');
      expect(result.status, isNot(ParseStatus.unsupported), reason: '不应该返回不支持状态');
      expect(result.courses.length, greaterThan(0), reason: '应该解析出至少一门课程');
    });
  });
}

