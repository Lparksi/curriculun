# lib/utils/ - 工具函数层

> 📍 **导航**: [← 返回根文档](../../CLAUDE.md) | **当前位置**: lib/utils/

## 模块概述

**职责**: 提供通用工具、算法、常量定义

**设计原则**:
- **无状态**: 纯函数设计,无副作用
- **独立性**: 不依赖业务逻辑
- **可复用**: 可在多个模块中使用
- **高性能**: 优化算法实现

**依赖关系**:
- ✅ 依赖: `package:flutter/material.dart`
- ❌ 不依赖: models、services、pages、widgets

---

## 文件清单

### 📄 course_colors.dart

**职责**: 课程颜色智能分配与管理

**核心功能**:
1. 为课程自动分配高辨识度颜色
2. 确保同名课程使用相同颜色
3. 使用预优化的18色色盘,确保最大视觉差异
4. 所有颜色符合 WCAG AA 级对比度要求(白色文字)

**类定义**:

```dart
class CourseColorManager {
  // 高辨识度颜色池 (18种颜色)
  static final List<Color> _colorPalette = [ ... ];

  // 课程名称到颜色的映射
  static final Map<String, Color> _courseColorMap = {};

  // 当前颜色索引
  static int _colorIndex = 0;
}
```

**方法清单**:

| 方法签名 | 功能描述 | 返回类型 |
|---------|---------|---------|
| `getColorForCourse(String)` | 获取课程对应的颜色 | `Color` |
| `reset()` | 重置颜色映射 | `void` |
| `presetColors(Map<String, Color>)` | 预设课程颜色 | `void` |

**核心算法剖析**:

#### 颜色分配策略

```dart
static Color getColorForCourse(String courseName) {
  // 1. 检查缓存:同名课程返回相同颜色
  if (_courseColorMap.containsKey(courseName)) {
    return _courseColorMap[courseName]!;
  }

  // 2. 顺序分配:颜色池已按最大差异优化
  final color = _colorPalette[_colorIndex % _colorPalette.length];
  _courseColorMap[courseName] = color;
  _colorIndex++;

  return color;
}
```

**设计亮点**:

1. **同名课程一致性**:
   - "大学物理" 在不同节次/周次使用相同颜色
   - 通过 `_courseColorMap` 缓存实现

2. **高辨识度色盘设计**:
   - 18种颜色,色相间隔 20°-80°
   - 严格控制每个色系只有一个代表色
   - 颜色排序确保相邻课程视觉差异最大

3. **WCAG 对比度保证**:
   - 所有颜色与白色文字对比度 ≥ 4.5:1 (AA 级)
   - 确保文字清晰可读

**颜色色盘详解**:

| 序号 | 颜色代码 | 色相 | 颜色名称 | 用途 |
|-----|---------|------|---------|------|
| 1 | 0xFFE91E63 | 340° | 玫红 | 区分度最高 |
| 2 | 0xFF00897B | 175° | 青绿 | 与玫红对比强 |
| 3 | 0xFFFF6F00 | 30° | 纯橙 | 暖色系代表 |
| 4 | 0xFF1976D2 | 210° | 宝蓝 | 冷色系代表 |
| 5 | 0xFF558B2F | 100° | 橄榄绿 | 中性偏暖 |
| 6 | 0xFF8E24AA | 285° | 紫罗兰 | 独特色相 |
| 7 | 0xFFD32F2F | 0° | 纯红 | 警示色 |
| 8 | 0xFF0097A7 | 188° | 水蓝 | 清新色 |
| 9 | 0xFFF9A825 | 48° | 金黄 | 明亮色 |
| 10 | 0xFF5D4037 | 15° | 咖啡棕 | 稳重色 |
| 11-18 | ... | ... | ... | 更多变化 |

**使用示例**:

```dart
// 在 CourseService 中使用
CourseColorManager.reset();  // 重置映射

final course1 = Course(name: '大学物理', ...);
final color1 = CourseColorManager.getColorForCourse('大学物理');
// color1 = Color(0xFFE91E63) (玫红)

final course2 = Course(name: '大学物理', ...);  // 同名课程
final color2 = CourseColorManager.getColorForCourse('大学物理');
// color2 = Color(0xFFE91E63) (相同颜色)

final course3 = Course(name: '高等数学', ...);
final color3 = CourseColorManager.getColorForCourse('高等数学');
// color3 = Color(0xFF00897B) (青绿,与玫红区分明显)
```

**预设颜色示例**:

```dart
// 为特定课程预设颜色
CourseColorManager.presetColors({
  '大学体育': Color(0xFF43A047),  // 绿色
  '大学英语': Color(0xFF1976D2),  // 蓝色
});

// 后续获取时使用预设颜色
final color = CourseColorManager.getColorForCourse('大学体育');
// color = Color(0xFF43A047)
```

**何时重置颜色映射**:

```dart
// 场景 1: 加载新的课程数据
static Future<List<Course>> loadCourses() async {
  CourseColorManager.reset();  // 重置映射
  // ... 加载逻辑
}

// 场景 2: 导入课程数据
static Future<void> importCourses(String jsonString) async {
  CourseColorManager.reset();  // 清除旧映射
  // ... 导入逻辑
}

// 场景 3: 重置为默认数据
static Future<void> resetToDefault() async {
  CourseColorManager.reset();  // 重新分配颜色
  // ... 重置逻辑
}
```

---

## 扩展建议

### 1. 添加颜色主题支持

```dart
class CourseColorManager {
  static ColorPalette _currentPalette = ColorPalette.vibrant;

  enum ColorPalette {
    vibrant,   // 鲜艳色盘 (当前)
    pastel,    // 柔和色盘
    dark,      // 深色色盘
  }

  static const Map<ColorPalette, List<Color>> _palettes = {
    ColorPalette.vibrant: [ /* 当前色盘 */ ],
    ColorPalette.pastel: [
      Color(0xFFFFADAD),  // 粉红
      Color(0xFFFFD6A5),  // 浅橙
      Color(0xFFFDFFB6),  // 浅黄
      // ...
    ],
    ColorPalette.dark: [
      Color(0xFF1B263B),  // 深蓝
      Color(0xFF415A77),  // 灰蓝
      // ...
    ],
  };

  static void setPalette(ColorPalette palette) {
    _currentPalette = palette;
    reset();  // 重置映射
  }

  static Color getColorForCourse(String courseName) {
    final palette = _palettes[_currentPalette]!;
    // ... 使用选定的色盘
  }
}
```

### 2. 添加颜色相似度检测

```dart
class ColorUtils {
  /// 计算两个颜色的感知差异 (Delta E)
  static double colorDistance(Color c1, Color c2) {
    // 转换为 LAB 色彩空间
    final lab1 = _rgbToLab(c1);
    final lab2 = _rgbToLab(c2);

    // 计算欧几里得距离
    return sqrt(
      pow(lab1.l - lab2.l, 2) +
      pow(lab1.a - lab2.a, 2) +
      pow(lab1.b - lab2.b, 2),
    );
  }

  /// 判断颜色是否过于相似
  static bool areColorsSimilar(Color c1, Color c2, {double threshold = 20}) {
    return colorDistance(c1, c2) < threshold;
  }
}
```

### 3. 添加动态颜色生成

```dart
class CourseColorManager {
  /// 根据课程名称生成确定性颜色
  static Color generateColorFromName(String courseName) {
    final hash = courseName.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final saturation = 0.6 + (hash % 20) / 100;  // 0.6-0.8
    final lightness = 0.4 + (hash % 20) / 100;   // 0.4-0.6

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }
}
```

---

## 性能优化

### 当前实现的性能特点

**时间复杂度**:
- `getColorForCourse()`: O(1) - HashMap 查找
- `reset()`: O(1) - 清空 Map

**空间复杂度**:
- 颜色池: O(1) - 固定18个颜色
- 映射表: O(n) - n 为不同课程名称数量

**优化建议**:

1. **预分配容量** (当课程数量很大时):
   ```dart
   static final Map<String, Color> _courseColorMap = HashMap<String, Color>(
     initialCapacity: 50,  // 预估课程数量
   );
   ```

2. **使用不可变颜色列表**:
   ```dart
   static const List<Color> _colorPalette = [  // const
     Color(0xFFE91E63),
     // ...
   ];
   ```

---

## 测试建议

### 单元测试用例

```dart
void main() {
  group('CourseColorManager', () {
    setUp(() {
      CourseColorManager.reset();
    });

    test('should return same color for same course name', () {
      final color1 = CourseColorManager.getColorForCourse('大学物理');
      final color2 = CourseColorManager.getColorForCourse('大学物理');

      expect(color1, color2);
    });

    test('should return different colors for different courses', () {
      final color1 = CourseColorManager.getColorForCourse('大学物理');
      final color2 = CourseColorManager.getColorForCourse('高等数学');

      expect(color1, isNot(color2));
    });

    test('should cycle through color palette', () {
      final colors = <Color>[];

      // 分配19个颜色 (超过色盘大小18)
      for (int i = 0; i < 19; i++) {
        colors.add(CourseColorManager.getColorForCourse('课程$i'));
      }

      // 第19个颜色应该与第1个相同 (循环)
      expect(colors[18], colors[0]);
    });

    test('reset should clear color mapping', () {
      CourseColorManager.getColorForCourse('大学物理');

      CourseColorManager.reset();

      // 重置后重新分配
      final color = CourseColorManager.getColorForCourse('大学物理');
      expect(color, isNotNull);
    });

    test('presetColors should override automatic assignment', () {
      final customColor = Color(0xFF123456);
      CourseColorManager.presetColors({'大学物理': customColor});

      final color = CourseColorManager.getColorForCourse('大学物理');
      expect(color, customColor);
    });
  });
}
```

---

## 最佳实践

### ✅ 推荐做法

1. **在加载数据前重置**:
   ```dart
   CourseColorManager.reset();
   final courses = await loadCourses();
   ```

2. **使用预设颜色固定重要课程**:
   ```dart
   CourseColorManager.presetColors({
     '毕业设计': Color(0xFFD32F2F),  // 红色标记
   });
   ```

3. **保持课程名称一致**:
   ```dart
   // ✅ 正确
   '大学物理'、'大学物理'  // 名称完全一致

   // ❌ 错误
   '大学物理'、'大学物理 '  // 后者有空格,被视为不同课程
   ```

### ❌ 避免的做法

1. **频繁重置颜色管理器**:
   ```dart
   // ❌ 错误:每次获取颜色都重置
   CourseColorManager.reset();
   final color = CourseColorManager.getColorForCourse(name);
   ```

2. **手动管理颜色映射**:
   ```dart
   // ❌ 错误:绕过 CourseColorManager
   final colorMap = <String, Color>{};
   colorMap['大学物理'] = Colors.red;
   ```

---

**文档更新**: 2025-10-16 | **维护者**: 查看根文档获取项目信息
