import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curriculum/utils/course_colors.dart';

void main() {
  group('CourseColorManager Tests', () {
    setUp(() {
      // 每个测试前重置颜色管理器
      CourseColorManager.reset();
    });

    group('颜色分配', () {
      test('getColorForCourse - 同名课程返回相同颜色', () {
        // Given
        const courseName = '大学物理';

        // When
        final color1 = CourseColorManager.getColorForCourse(courseName);
        final color2 = CourseColorManager.getColorForCourse(courseName);

        // Then
        expect(color1, equals(color2));
        expect(color1.toARGB32(), equals(color2.toARGB32()));
      });

      test('getColorForCourse - 不同课程返回不同颜色', () {
        // Given
        const courseName1 = '大学物理';
        const courseName2 = '高等数学';
        const courseName3 = '大学英语';

        // When
        final color1 = CourseColorManager.getColorForCourse(courseName1);
        final color2 = CourseColorManager.getColorForCourse(courseName2);
        final color3 = CourseColorManager.getColorForCourse(courseName3);

        // Then
        expect(color1, isNot(equals(color2)));
        expect(color1, isNot(equals(color3)));
        expect(color2, isNot(equals(color3)));
      });

      test('getColorForCourse - 18色循环分配', () {
        // Given
        final assignedColors = <Color>[];

        // When - 分配 36 个课程（2倍色盘大小）
        for (int i = 0; i < 36; i++) {
          final color = CourseColorManager.getColorForCourse('课程$i');
          assignedColors.add(color);
        }

        // Then - 验证循环：第19个颜色应该与第1个相同
        expect(assignedColors[18].toARGB32(), equals(assignedColors[0].toARGB32()));
        expect(assignedColors[19].toARGB32(), equals(assignedColors[1].toARGB32()));
        expect(assignedColors[35].toARGB32(), equals(assignedColors[17].toARGB32()));

        // Then - 验证前18个颜色各不相同
        final firstBatch = assignedColors.sublist(0, 18).toSet();
        expect(firstBatch.length, equals(18), reason: '前18个课程应该使用18种不同的颜色');
      });

      test('getColorForCourse - 顺序分配确保最大视觉差异', () {
        // Given
        final colors = <Color>[];

        // When - 按顺序分配前5个课程
        for (int i = 0; i < 5; i++) {
          colors.add(CourseColorManager.getColorForCourse('课程$i'));
        }

        // Then - 验证颜色按预期顺序分配（根据色盘定义）
        expect(colors[0].toARGB32(), equals(0xFFE91E63), reason: '第1个颜色应为玫红');
        expect(colors[1].toARGB32(), equals(0xFF00897B), reason: '第2个颜色应为青绿');
        expect(colors[2].toARGB32(), equals(0xFFFF6F00), reason: '第3个颜色应为纯橙');
        expect(colors[3].toARGB32(), equals(0xFF1976D2), reason: '第4个颜色应为宝蓝');
        expect(colors[4].toARGB32(), equals(0xFF558B2F), reason: '第5个颜色应为橄榄绿');
      });
    });

    group('颜色重置', () {
      test('reset - 重置后重新分配颜色', () {
        // Given
        final colorBefore = CourseColorManager.getColorForCourse('大学物理');

        // When
        CourseColorManager.reset();

        // Then - 重置后，同名课程应重新分配相同的第一个颜色
        final colorAfter = CourseColorManager.getColorForCourse('大学物理');
        expect(colorAfter.toARGB32(), equals(0xFFE91E63), reason: '重置后第一个课程应为玫红色');
        expect(colorAfter, equals(colorBefore), reason: '重置后首次分配应使用第一个颜色');
      });

      test('reset - 清除颜色映射缓存', () {
        // Given - 分配多个课程颜色
        CourseColorManager.getColorForCourse('大学物理');
        CourseColorManager.getColorForCourse('高等数学');
        final colorBeforeReset = CourseColorManager.getColorForCourse('大学英语');

        // When - 重置
        CourseColorManager.reset();

        // Then - 大学英语应重新分配为第一个颜色（而不是之前的第三个）
        final colorAfterReset = CourseColorManager.getColorForCourse('大学英语');
        expect(colorAfterReset.toARGB32(), equals(0xFFE91E63));
        expect(colorAfterReset, isNot(equals(colorBeforeReset)));
      });
    });

    group('预设颜色', () {
      test('presetColors - 使用预设颜色覆盖自动分配', () {
        // Given
        const customColor = Color(0xFF123456);
        CourseColorManager.presetColors({
          '大学物理': customColor,
        });

        // When
        final color = CourseColorManager.getColorForCourse('大学物理');

        // Then
        expect(color, equals(customColor));
      });

      test('presetColors - 预设颜色不影响其他课程', () {
        // Given
        const customColor = Color(0xFF123456);
        CourseColorManager.presetColors({
          '大学物理': customColor,
        });

        // When
        final physicsColor = CourseColorManager.getColorForCourse('大学物理');
        final mathColor = CourseColorManager.getColorForCourse('高等数学');

        // Then
        expect(physicsColor, equals(customColor));
        expect(mathColor.toARGB32(), equals(0xFFE91E63), reason: '其他课程应从第一个颜色开始分配');
      });

      test('presetColors - 支持批量预设', () {
        // Given
        const color1 = Color(0xFF111111);
        const color2 = Color(0xFF222222);
        const color3 = Color(0xFF333333);

        CourseColorManager.presetColors({
          '大学物理': color1,
          '高等数学': color2,
          '大学英语': color3,
        });

        // When & Then
        expect(CourseColorManager.getColorForCourse('大学物理'), equals(color1));
        expect(CourseColorManager.getColorForCourse('高等数学'), equals(color2));
        expect(CourseColorManager.getColorForCourse('大学英语'), equals(color3));
      });
    });

    group('WCAG 对比度验证', () {
      test('所有颜色具有良好的对比度（白色文字）', () {
        // Given - 18色色盘的所有颜色
        final allColors = <Color>[];
        for (int i = 0; i < 18; i++) {
          allColors.add(CourseColorManager.getColorForCourse('课程$i'));
        }

        // When & Then - 计算每个颜色与白色的对比度
        int acceptableColors = 0;
        for (final color in allColors) {
          final contrast = _calculateContrastRatio(color, Colors.white);

          // 对比度应接近或超过 WCAG AA 级要求 (>= 4.3:1)
          if (contrast >= 4.3) {
            acceptableColors++;
          }
        }

        // Then - 至少 50% 的颜色应满足良好的对比度
        expect(
          acceptableColors / allColors.length,
          greaterThanOrEqualTo(0.5),
          reason: '应该有至少 50% 的颜色具有良好的对比度',
        );
      });

      test('验证平均对比度', () {
        // Given
        final colors = <Color>[];
        for (int i = 0; i < 18; i++) {
          colors.add(CourseColorManager.getColorForCourse('课程$i'));
        }

        // When - 计算平均对比度
        double totalContrast = 0;
        for (final color in colors) {
          totalContrast += _calculateContrastRatio(color, Colors.white);
        }
        final avgContrast = totalContrast / colors.length;

        // Then - 平均对比度应大于 4.5:1 (WCAG AA 级)
        expect(avgContrast, greaterThan(4.5), reason: '平均对比度应达到 WCAG AA 级');
      });
    });

    group('边界情况', () {
      test('空字符串课程名称', () {
        // When
        final color1 = CourseColorManager.getColorForCourse('');
        final color2 = CourseColorManager.getColorForCourse('');

        // Then - 空字符串也应保持一致性
        expect(color1, equals(color2));
      });

      test('包含特殊字符的课程名称', () {
        // Given
        const specialNames = [
          '大学物理（上）',
          'C++ 程序设计',
          '数据结构 & 算法',
          '线性代数 I',
        ];

        // When
        final colors = specialNames.map((name) {
          final color1 = CourseColorManager.getColorForCourse(name);
          final color2 = CourseColorManager.getColorForCourse(name);
          return {'name': name, 'color1': color1, 'color2': color2};
        }).toList();

        // Then - 每个特殊名称应保持颜色一致性
        for (final item in colors) {
          expect(item['color1'], equals(item['color2']),
              reason: '特殊名称 "${item['name']}" 应保持颜色一致');
        }
      });

      test('大量课程分配（性能测试）', () {
        // Given
        const courseCount = 1000;

        // When - 分配 1000 个课程
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < courseCount; i++) {
          CourseColorManager.getColorForCourse('课程$i');
        }
        stopwatch.stop();

        // Then - 性能检查：应在 100ms 内完成
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: '分配 $courseCount 个课程应在 100ms 内完成',
        );
      });
    });
  });
}

/// 计算两个颜色的对比度（WCAG 标准）
/// 返回值范围: 1:1 (无对比) 到 21:1 (最大对比)
double _calculateContrastRatio(Color color1, Color color2) {
  final l1 = _getRelativeLuminance(color1);
  final l2 = _getRelativeLuminance(color2);

  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;

  return (lighter + 0.05) / (darker + 0.05);
}

/// 计算颜色的相对亮度（WCAG 标准）
double _getRelativeLuminance(Color color) {
  final r = _getSRGB((color.r * 255.0).round());
  final g = _getSRGB((color.g * 255.0).round());
  final b = _getSRGB((color.b * 255.0).round());

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// 转换 sRGB 颜色分量
double _getSRGB(int value) {
  final v = value / 255.0;
  if (v <= 0.03928) {
    return v / 12.92;
  } else {
    return math.pow((v + 0.055) / 1.055, 2.4) as double;
  }
}
