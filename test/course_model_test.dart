import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curriculum/models/course.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Course Model Serialization Tests', () {
    // ========== JSON 反序列化测试 (2个) ==========
    group('fromJson 反序列化', () {
      test('fromJson - 完整数据解析', () {
        // Given: 完整的 JSON 数据
        final json = {
          'name': '大学物理',
          'location': '教学楼210',
          'teacher': '牛富全',
          'weekday': 3,
          'startSection': 1,
          'duration': 2,
          'startWeek': 1,
          'endWeek': 16,
          'color': '#FF6F00',
          'semesterId': 'semester_2024_fall',
          'isHidden': false,
        };

        // When: 从 JSON 创建课程
        final course = Course.fromJson(json);

        // Then: 所有字段正确解析
        expect(course.name, equals('大学物理'));
        expect(course.location, equals('教学楼210'));
        expect(course.teacher, equals('牛富全'));
        expect(course.weekday, equals(3));
        expect(course.startSection, equals(1));
        expect(course.duration, equals(2));
        expect(course.startWeek, equals(1));
        expect(course.endWeek, equals(16));
        expect(course.semesterId, equals('semester_2024_fall'));
        expect(course.isHidden, isFalse);

        // 验证颜色解析
        expect(course.color, equals(const Color(0xFFFF6F00)));
      });

      test('fromJson - 处理缺失可选字段（使用默认值）', () {
        // Given: 仅包含必需字段的 JSON
        final json = {
          'name': '高等数学',
          'weekday': 1,
          'startSection': 3,
          'duration': 2,
          'color': '#2196F3',
        };

        // When: 从 JSON 创建课程
        final course = Course.fromJson(json);

        // Then: 可选字段使用默认值
        expect(course.name, equals('高等数学'));
        expect(course.location, equals('')); // 默认空字符串
        expect(course.teacher, equals('')); // 默认空字符串
        expect(course.startWeek, equals(1)); // 默认第1周
        expect(course.endWeek, equals(20)); // 默认第20周
        expect(course.semesterId, isNull); // 默认 null
        expect(course.isHidden, isFalse); // 默认不隐藏

        // 验证必需字段
        expect(course.weekday, equals(1));
        expect(course.startSection, equals(3));
        expect(course.duration, equals(2));
      });
    });

    // ========== JSON 序列化测试 (2个) ==========
    group('toJson 序列化', () {
      test('toJson - 完整序列化', () {
        // Given: 完整的课程对象
        final course = Course(
          name: '线性代数',
          location: '第二教学楼301',
          teacher: '张教授',
          weekday: 2,
          startSection: 5,
          duration: 2,
          color: const Color(0xFF4CAF50),
          startWeek: 1,
          endWeek: 18,
          semesterId: 'semester_2025_spring',
          isHidden: false,
        );

        // When: 序列化为 JSON
        final json = course.toJson();

        // Then: 所有字段正确序列化
        expect(json['name'], equals('线性代数'));
        expect(json['location'], equals('第二教学楼301'));
        expect(json['teacher'], equals('张教授'));
        expect(json['weekday'], equals(2));
        expect(json['startSection'], equals(5));
        expect(json['duration'], equals(2));
        expect(json['startWeek'], equals(1));
        expect(json['endWeek'], equals(18));
        expect(json['color'], equals('#4CAF50'));
        expect(json['semesterId'], equals('semester_2025_spring'));
        expect(json['isHidden'], isFalse);
      });

      test('toJson - 条件序列化 semesterId', () {
        // Given: semesterId 为 null 的课程
        final course = Course(
          name: '大学英语',
          location: '外语楼201',
          teacher: '李老师',
          weekday: 4,
          startSection: 1,
          duration: 2,
          color: Colors.orange,
          startWeek: 1,
          endWeek: 16,
          semesterId: null, // null 值
        );

        // When: 序列化为 JSON
        final json = course.toJson();

        // Then: semesterId 不包含在 JSON 中
        expect(json, isNot(contains('semesterId')));

        // 其他字段正常序列化
        expect(json['name'], equals('大学英语'));
        expect(json['isHidden'], isFalse);
      });
    });

    // ========== 颜色转换测试 (4个) ==========
    group('颜色转换', () {
      test('colorFromHex - 带 # 前缀的六位十六进制', () {
        // Given: 带 # 的颜色字符串
        const hexColor = '#FF0000';

        // When: 转换为 Color
        final color = Course.colorFromHex(hexColor);

        // Then: 正确解析为红色
        expect(color, equals(const Color(0xFFFF0000)));
      });

      test('colorFromHex - 不带 # 前缀的六位十六进制', () {
        // Given: 不带 # 的颜色字符串
        const hexColor = '00FF00';

        // When: 转换为 Color
        final color = Course.colorFromHex(hexColor);

        // Then: 正确解析为绿色
        expect(color, equals(const Color(0xFF00FF00)));
      });

      test('colorFromHex - 空字符串或 null 返回默认蓝色', () {
        // Given: 空字符串和 null

        // When & Then: 返回默认蓝色
        expect(Course.colorFromHex(''), equals(Colors.blue));
        expect(Course.colorFromHex(null), equals(Colors.blue));
      });

      test('colorToHex - Color 转换为十六进制字符串', () {
        // Given: 各种颜色
        const redColor = Color(0xFFFF0000);
        const greenColor = Color(0xFF00FF00);
        const blueColor = Color(0xFF0000FF);

        // When: 转换为十六进制字符串

        // Then: 正确转换（带 # 前缀，大写字母）
        expect(Course.colorToHex(redColor), equals('#FF0000'));
        expect(Course.colorToHex(greenColor), equals('#00FF00'));
        expect(Course.colorToHex(blueColor), equals('#0000FF'));
      });
    });

    // ========== 双向转换测试 (1个额外) ==========
    test('JSON 双向转换保持数据一致性', () {
      // Given: 原始课程对象
      final originalCourse = Course(
        name: '数据结构',
        location: '计算机楼401',
        teacher: '王教授',
        weekday: 5,
        startSection: 3,
        duration: 3,
        color: const Color(0xFFE91E63),
        startWeek: 2,
        endWeek: 17,
        semesterId: 'semester_test',
        isHidden: true,
      );

      // When: 序列化再反序列化
      final json = originalCourse.toJson();
      final deserializedCourse = Course.fromJson(json);

      // Then: 数据完全一致
      expect(deserializedCourse.name, equals(originalCourse.name));
      expect(deserializedCourse.location, equals(originalCourse.location));
      expect(deserializedCourse.teacher, equals(originalCourse.teacher));
      expect(deserializedCourse.weekday, equals(originalCourse.weekday));
      expect(
        deserializedCourse.startSection,
        equals(originalCourse.startSection),
      );
      expect(deserializedCourse.duration, equals(originalCourse.duration));
      expect(deserializedCourse.startWeek, equals(originalCourse.startWeek));
      expect(deserializedCourse.endWeek, equals(originalCourse.endWeek));
      expect(deserializedCourse.color, equals(originalCourse.color));
      expect(deserializedCourse.semesterId, equals(originalCourse.semesterId));
      expect(deserializedCourse.isHidden, equals(originalCourse.isHidden));
    });
  });
}
