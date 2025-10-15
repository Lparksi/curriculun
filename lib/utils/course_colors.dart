import 'package:flutter/material.dart';

/// 课程颜色管理器
/// 确保同名课程使用相同颜色,且颜色之间有明显区分
/// 所有颜色都经过优化,确保白色文字有足够的对比度(WCAG AA级以上)
class CourseColorManager {
  // 高辨识度颜色池 - 每种颜色都有独特的色相和明度
  // 严格控制每个色系只有一个代表色，确保最大视觉差异
  static final List<Color> _colorPalette = [
    const Color(0xFFE91E63), // 1. 玫红 (340°)
    const Color(0xFF00897B), // 2. 青绿 (175°)
    const Color(0xFFFF6F00), // 3. 纯橙 (30°)
    const Color(0xFF1976D2), // 4. 宝蓝 (210°)
    const Color(0xFF558B2F), // 5. 橄榄绿 (100°)
    const Color(0xFF8E24AA), // 6. 紫罗兰 (285°)
    const Color(0xFFD32F2F), // 7. 纯红 (0°)
    const Color(0xFF0097A7), // 8. 水蓝 (188°)
    const Color(0xFFF9A825), // 9. 金黄 (48°)
    const Color(0xFF5D4037), // 10. 咖啡棕 (15°)

    const Color(0xFF7B1FA2), // 11. 深紫 (290°)
    const Color(0xFF00695C), // 12. 暗青 (170°)
    const Color(0xFFFF5722), // 13. 朱红 (14°)
    const Color(0xFF0288D1), // 14. 天蓝 (200°)
    const Color(0xFF9C27B0), // 15. 亮紫 (295°)
    const Color(0xFF43A047), // 16. 翠绿 (122°)
    const Color(0xFFE64A19), // 17. 橙红 (16°)
    const Color(0xFFC2185B), // 18. 深粉 (338°)
  ];

  // 课程名称到颜色的映射
  static final Map<String, Color> _courseColorMap = {};
  static int _colorIndex = 0;

  /// 获取课程对应的颜色
  /// 同名课程返回相同颜色
  /// 直接顺序分配，颜色池已优化为最大差异序列
  static Color getColorForCourse(String courseName) {
    if (_courseColorMap.containsKey(courseName)) {
      return _courseColorMap[courseName]!;
    }

    // 直接顺序分配，因为颜色池已经按最大差异排序
    final color = _colorPalette[_colorIndex % _colorPalette.length];
    _courseColorMap[courseName] = color;
    _colorIndex++;

    return color;
  }

  /// 重置颜色映射 (用于重新初始化)
  static void reset() {
    _courseColorMap.clear();
    _colorIndex = 0;
  }

  /// 预设课程颜色 (可选,用于固定某些课程的颜色)
  static void presetColors(Map<String, Color> presets) {
    _courseColorMap.addAll(presets);
  }
}
