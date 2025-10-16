# lib/models/ - 数据模型层

> 📍 **导航**: [← 返回根文档](../../CLAUDE.md) | **当前位置**: lib/models/

## 模块概述

**职责**: 定义应用的核心数据结构,提供 JSON 序列化/反序列化支持

**设计原则**:
- **不可变性** (Immutability): 所有字段使用 `final`
- **类型安全**: 使用 Dart 强类型系统
- **自包含**: 无外部业务逻辑依赖
- **纯数据**: 不包含业务逻辑,仅数据建模

**依赖关系**:
- ✅ 依赖: `package:flutter/material.dart` (仅用于 Color 类型)
- ❌ 不依赖: services、pages、widgets、utils

---

## 文件清单

### 📄 course.dart

**核心实体**: 课程数据模型

**类定义**:

1. **Course** - 课程实体
   ```dart
   class Course {
     final String name;           // 课程名称
     final String location;       // 上课地点
     final String teacher;        // 教师姓名
     final int weekday;          // 星期几 (1-7)
     final int startSection;     // 开始节次 (1-10)
     final int duration;         // 持续节数
     final Color color;          // 课程卡片颜色
     final int startWeek;        // 开始周次 (默认 1)
     final int endWeek;          // 结束周次 (默认 20)
   }
   ```

2. **SectionTime** - 节次时间配置
   ```dart
   class SectionTime {
     final int section;        // 节次编号 (1-10)
     final String startTime;   // 开始时间 (HH:mm)
     final String endTime;     // 结束时间 (HH:mm)
   }
   ```

3. **SectionTimeTable** - 节次时间表 (常量)
   - 10个节次的时间配置
   - 上午: 08:00-11:50 (1-4节)
   - 下午: 15:00-17:55 (5-8节)
   - 晚上: 20:00-21:40 (9-10节)

**关键方法**:

| 方法签名 | 功能描述 | 返回类型 |
|---------|---------|---------|
| `Course.fromJson(Map<String, dynamic>)` | 从 JSON 创建课程对象 | `Course` |
| `toJson()` | 转换为 JSON 格式 | `Map<String, dynamic>` |
| `colorFromHex(String?)` | 十六进制字符串转颜色 | `Color` |
| `colorToHex(Color)` | 颜色转十六进制字符串 | `String` |
| `get endSection` | 计算结束节次 | `int` |
| `get timeRangeText` | 获取时间段描述 | `String` |
| `get weekRangeText` | 获取周次范围描述 | `String` |
| `get sectionRangeText` | 获取节次范围描述 | `String` |

**使用示例**:

```dart
// 从 JSON 创建课程
final course = Course.fromJson({
  'name': '大学物理',
  'location': '教学楼210',
  'teacher': '牛富全',
  'weekday': 3,
  'startSection': 1,
  'duration': 2,
  'startWeek': 1,
  'endWeek': 16,
  'color': '#FF6F00',
});

// 访问计算属性
print(course.timeRangeText);      // "08:00-09:40"
print(course.weekRangeText);      // "第1-16周"
print(course.sectionRangeText);   // "第1-2节"

// 序列化为 JSON
final json = course.toJson();
```

**设计亮点**:

1. **颜色处理**: 支持带#或不带#的十六进制颜色字符串
2. **默认值**: 空字符串时返回 `Colors.blue`
3. **类型转换**: 使用 `toARGB32()` 确保完整的 ARGB 颜色值
4. **计算属性**: 使用 getter 提供派生数据,避免重复存储

---

### 📄 semester_settings.dart

**核心实体**: 学期设置数据模型

**类定义**:

```dart
class SemesterSettings {
  final DateTime startDate;  // 学期开始日期
  final int totalWeeks;      // 学期总周数
}
```

**关键方法**:

| 方法签名 | 功能描述 | 返回类型 |
|---------|---------|---------|
| `SemesterSettings.defaultSettings()` | 创建默认设置 | `SemesterSettings` |
| `fromJson(Map<String, dynamic>)` | 从 JSON 创建对象 | `SemesterSettings` |
| `toJson()` | 转换为 JSON 格式 | `Map<String, dynamic>` |
| `copyWith({DateTime?, int?})` | 复制并修改部分字段 | `SemesterSettings` |
| `operator ==` | 相等性比较 | `bool` |
| `get hashCode` | 哈希值计算 | `int` |

**使用示例**:

```dart
// 使用默认设置
final defaultSettings = SemesterSettings.defaultSettings();
// startDate: 2025-09-01, totalWeeks: 20

// 从 JSON 加载
final settings = SemesterSettings.fromJson({
  'startDate': '2025-09-01T00:00:00.000',
  'totalWeeks': 20,
});

// 修改部分字段
final newSettings = settings.copyWith(totalWeeks: 18);

// 相等性比较
if (settings == defaultSettings) {
  print('使用默认设置');
}

// 序列化
final json = settings.toJson();
```

**设计亮点**:

1. **工厂模式**: 提供 `defaultSettings()` 工厂方法
2. **不可变性**: 使用 `copyWith` 实现"修改"
3. **值对象**: 实现 `==` 和 `hashCode` 用于相等性比较
4. **ISO 8601**: 日期序列化使用标准格式

---

## JSON 序列化规范

### 字段映射表

**Course 模型**:

| Dart 字段 | JSON 键 | 类型 | 必需 | 默认值 |
|----------|---------|------|------|-------|
| name | name | String | ✅ | - |
| location | location | String | ❌ | `''` |
| teacher | teacher | String | ❌ | `''` |
| weekday | weekday | int | ✅ | - |
| startSection | startSection | int | ✅ | - |
| duration | duration | int | ✅ | - |
| startWeek | startWeek | int | ❌ | `1` |
| endWeek | endWeek | int | ❌ | `20` |
| color | color | String (hex) | ❌ | `Colors.blue` |

**SemesterSettings 模型**:

| Dart 字段 | JSON 键 | 类型 | 必需 | 默认值 |
|----------|---------|------|------|-------|
| startDate | startDate | String (ISO 8601) | ✅ | - |
| totalWeeks | totalWeeks | int | ✅ | - |

### 错误处理策略

**Course.fromJson**:
```dart
// ✅ 正确:提供默认值
location: json['location'] as String? ?? '',

// ✅ 正确:处理空颜色字符串
color: colorFromHex(json['color'] as String?),
```

**SemesterSettings.fromJson**:
```dart
// ✅ 正确:使用 DateTime.parse 处理 ISO 8601
startDate: DateTime.parse(json['startDate'] as String),
```

---

## 数据验证规则

### Course 验证

| 字段 | 约束条件 | 说明 |
|------|---------|------|
| weekday | 1 ≤ weekday ≤ 7 | 周一到周日 |
| startSection | 1 ≤ startSection ≤ 10 | 最多10节课 |
| duration | duration ≥ 1 | 至少1节课 |
| startWeek | startWeek ≥ 1 | 从第1周开始 |
| endWeek | endWeek ≥ startWeek | 结束周不早于开始周 |

**注意**: 当前模型不包含验证逻辑,验证由 `CourseService` 执行。

### SemesterSettings 验证

| 字段 | 约束条件 | 说明 |
|------|---------|------|
| startDate | 有效日期 | - |
| totalWeeks | totalWeeks > 0 | 至少1周 |

---

## 扩展建议

### 1. 添加验证方法

```dart
class Course {
  // ...现有代码

  /// 验证课程数据有效性
  bool validate() {
    if (weekday < 1 || weekday > 7) return false;
    if (startSection < 1 || startSection > 10) return false;
    if (duration < 1) return false;
    if (endWeek < startWeek) return false;
    return true;
  }
}
```

### 2. 添加课程类型枚举

```dart
enum CourseType {
  lecture,      // 理论课
  experiment,   // 实验课
  practice,     // 实践课
  elective,     // 选修课
}
```

### 3. 添加课程冲突检测方法

```dart
class Course {
  /// 检查与另一门课程是否有时间冲突
  bool conflictsWith(Course other) {
    // 不同星期,不冲突
    if (weekday != other.weekday) return false;

    // 周次无重叠,不冲突
    if (endWeek < other.startWeek || startWeek > other.endWeek) {
      return false;
    }

    // 节次无重叠,不冲突
    final thisEnd = startSection + duration - 1;
    final otherEnd = other.startSection + other.duration - 1;
    if (thisEnd < other.startSection || startSection > otherEnd) {
      return false;
    }

    return true;
  }
}
```

---

## 最佳实践

### ✅ 推荐做法

1. **使用 const 构造函数** (如果可能):
   ```dart
   const course = Course(
     name: '固定课程',
     // ...
   );
   ```

2. **使用工厂方法创建默认对象**:
   ```dart
   final settings = SemesterSettings.defaultSettings();
   ```

3. **使用 copyWith 进行"修改"**:
   ```dart
   final updated = original.copyWith(totalWeeks: 18);
   ```

### ❌ 避免的做法

1. **直接修改字段** (不可能,因为是 final):
   ```dart
   course.name = '新名称'; // ❌ 编译错误
   ```

2. **不处理 null 情况**:
   ```dart
   // ❌ 错误
   location: json['location'] as String,  // 可能抛出异常

   // ✅ 正确
   location: json['location'] as String? ?? '',
   ```

---

## 测试建议

### 单元测试用例

```dart
void main() {
  group('Course Model', () {
    test('fromJson should handle missing optional fields', () {
      final course = Course.fromJson({
        'name': '测试课程',
        'weekday': 1,
        'startSection': 1,
        'duration': 2,
      });

      expect(course.location, '');
      expect(course.teacher, '');
      expect(course.startWeek, 1);
      expect(course.endWeek, 20);
    });

    test('timeRangeText should return correct format', () {
      final course = Course(
        name: '测试',
        weekday: 1,
        startSection: 1,
        duration: 2,
        // ...
      );

      expect(course.timeRangeText, '08:00-09:40');
    });

    test('colorFromHex should handle various formats', () {
      expect(Course.colorFromHex('#FF0000'), Color(0xFFFF0000));
      expect(Course.colorFromHex('FF0000'), Color(0xFFFF0000));
      expect(Course.colorFromHex(''), Colors.blue);
      expect(Course.colorFromHex(null), Colors.blue);
    });
  });

  group('SemesterSettings Model', () {
    test('copyWith should preserve unchanged fields', () {
      final original = SemesterSettings(
        startDate: DateTime(2025, 9, 1),
        totalWeeks: 20,
      );

      final updated = original.copyWith(totalWeeks: 18);

      expect(updated.startDate, original.startDate);
      expect(updated.totalWeeks, 18);
    });

    test('equality should work correctly', () {
      final settings1 = SemesterSettings(
        startDate: DateTime(2025, 9, 1),
        totalWeeks: 20,
      );

      final settings2 = SemesterSettings(
        startDate: DateTime(2025, 9, 1),
        totalWeeks: 20,
      );

      expect(settings1, settings2);
    });
  });
}
```

---

**文档更新**: 2025-10-16 | **维护者**: 查看根文档获取项目信息
