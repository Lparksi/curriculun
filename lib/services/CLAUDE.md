# lib/services/ - 业务逻辑服务层

> 📍 **导航**: [← 返回根文档](../../CLAUDE.md) | **当前位置**: lib/services/

## 模块概述

**职责**: 封装业务逻辑、数据处理、外部资源交互

**设计原则**:
- **静态方法**: 所有服务使用静态方法,无需实例化
- **单一职责**: 每个服务类专注于一个业务领域
- **异步优先**: 所有I/O操作使用 `async`/`await`
- **错误容错**: 提供降级方案,避免崩溃

**依赖关系**:
- ✅ 依赖: `models/`, `utils/`, `package:shared_preferences`, `package:flutter/services.dart`
- ❌ 不依赖: `pages/`, `widgets/`

---

## 文件清单

### 📄 course_service.dart

**职责**: 课程数据的 CRUD 操作与业务逻辑

**核心功能**:
1. 从 assets 加载默认课程数据
2. 从本地存储加载/保存课程数据
3. 课程的增删改查操作
4. 课程时间冲突检测
5. JSON 序列化/反序列化

**常量定义**:
```dart
static const String _coursesKey = 'saved_courses';  // SharedPreferences 键
```

**方法清单**:

| 方法签名 | 功能描述 | 返回类型 |
|---------|---------|---------|
| `loadCoursesFromAssets({String?})` | 从 assets/courses.json 加载课程 | `Future<List<Course>>` |
| `exportCoursesToJson(List<Course>)` | 将课程列表导出为 JSON 字符串 | `String` |
| `loadCourses()` | 加载课程(优先本地存储) | `Future<List<Course>>` |
| `saveCourses(List<Course>)` | 保存课程到本地存储 | `Future<void>` |
| `addCourse(Course)` | 添加新课程 | `Future<void>` |
| `updateCourse(int, Course)` | 更新指定索引的课程 | `Future<void>` |
| `deleteCourse(int)` | 删除指定索引的课程 | `Future<void>` |
| `resetToDefault()` | 重置为默认数据 | `Future<void>` |
| `hasTimeConflict(List, Course, {int?})` | 检查时间冲突 | `bool` |

**核心逻辑剖析**:

#### 1. 数据加载策略 (loadCourses)

```dart
static Future<List<Course>> loadCourses() async {
  // 策略:本地存储优先,不存在则加载 assets
  final prefs = await SharedPreferences.getInstance();
  final savedJson = prefs.getString(_coursesKey);

  if (savedJson != null && savedJson.isNotEmpty) {
    // 从本地存储加载
    return parseSavedJson(savedJson);
  } else {
    // 首次使用,从 assets 加载并保存
    final courses = await loadCoursesFromAssets();
    await saveCourses(courses);
    return courses;
  }
}
```

**设计亮点**:
- **首次启动自动初始化**: 自动从 assets 加载默认数据
- **懒加载**: 仅在首次需要时加载
- **缓存机制**: 后续访问从本地存储读取

#### 2. 颜色自动分配机制

```dart
// 重置颜色管理器
CourseColorManager.reset();

return coursesJson.map((courseJson) {
  final course = courseJson as Map<String, dynamic>;

  // 如果 JSON 中没有提供颜色,自动分配
  if (course['color'] == null || (course['color'] as String).isEmpty) {
    final courseName = course['name'] as String;
    course['color'] = Course.colorToHex(
      CourseColorManager.getColorForCourse(courseName),
    );
  }

  return Course.fromJson(course);
}).toList();
```

**设计亮点**:
- **同名课程同色**: 相同课程名称使用相同颜色
- **高辨识度**: 使用预优化的18色色盘
- **兼容手动配色**: 手动指定的颜色优先

#### 3. 时间冲突检测算法

```dart
static bool hasTimeConflict(
  List<Course> courses,
  Course newCourse, {
  int? excludeIndex,  // 更新时排除自身
}) {
  for (int i = 0; i < courses.length; i++) {
    if (excludeIndex != null && i == excludeIndex) continue;

    final course = courses[i];

    // 检查 1: 同一天?
    if (course.weekday != newCourse.weekday) continue;

    // 检查 2: 周次有重叠?
    final weekOverlap = !(newCourse.endWeek < course.startWeek ||
        newCourse.startWeek > course.endWeek);
    if (!weekOverlap) continue;

    // 检查 3: 节次有重叠?
    final newEndSection = newCourse.startSection + newCourse.duration - 1;
    final existingEndSection = course.startSection + course.duration - 1;

    final sectionOverlap = !(newEndSection < course.startSection ||
        newCourse.startSection > existingEndSection);

    if (sectionOverlap) {
      return true;  // 冲突
    }
  }
  return false;  // 无冲突
}
```

**算法复杂度**: O(n) - 线性扫描所有课程

**使用示例**:

```dart
// 添加课程前检查冲突
final newCourse = Course(...);
if (CourseService.hasTimeConflict(existingCourses, newCourse)) {
  // 显示错误提示
  showDialog(...);
} else {
  await CourseService.addCourse(newCourse);
}

// 更新课程时排除自身
if (CourseService.hasTimeConflict(
  existingCourses,
  updatedCourse,
  excludeIndex: courseIndex,
)) {
  // 显示错误提示
}
```

**错误处理策略**:

```dart
// ✅ 正确:捕获异常并提供降级方案
try {
  final jsonString = await rootBundle.loadString(assetPath);
  // ...解析逻辑
} catch (e) {
  debugPrint('加载课程数据失败: $e');
  return [];  // 返回空列表,不崩溃
}
```

---

### 📄 settings_service.dart

**职责**: 学期设置的本地存储管理

**核心功能**:
1. 保存学期设置到本地存储
2. 从本地存储读取学期设置
3. 重置为默认设置
4. 清除所有设置

**常量定义**:
```dart
static const String _settingsKey = 'semester_settings';  // SharedPreferences 键
```

**方法清单**:

| 方法签名 | 功能描述 | 返回类型 |
|---------|---------|---------|
| `saveSemesterSettings(SemesterSettings)` | 保存学期设置 | `Future<void>` |
| `loadSemesterSettings()` | 加载学期设置 | `Future<SemesterSettings>` |
| `resetToDefault()` | 重置为默认设置 | `Future<void>` |
| `clearSettings()` | 清除所有设置 | `Future<void>` |

**核心逻辑剖析**:

#### 加载设置逻辑

```dart
static Future<SemesterSettings> loadSemesterSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString(_settingsKey);

  if (jsonString == null) {
    // 没有保存过设置,返回默认值
    return SemesterSettings.defaultSettings();
  }

  try {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return SemesterSettings.fromJson(json);
  } catch (e) {
    // 解析失败,返回默认值
    return SemesterSettings.defaultSettings();
  }
}
```

**设计亮点**:
- **多重降级**: 未保存或解析失败都返回默认值
- **永不崩溃**: 异常情况下使用默认配置

**使用示例**:

```dart
// 加载设置
final settings = await SettingsService.loadSemesterSettings();

// 保存设置
await SettingsService.saveSemesterSettings(
  SemesterSettings(
    startDate: DateTime(2025, 9, 1),
    totalWeeks: 20,
  ),
);

// 重置为默认值
await SettingsService.resetToDefault();
```

---

### 📂 course_import/ - HTML 课程导入子模块

**职责**: 从 HTML 页面（如教务系统课表）解析并导入课程数据

**子模块文档**: [📄 lib/services/course_import/CLAUDE.md](course_import/CLAUDE.md)

**核心组件**:

1. **course_html_import_service.dart** - 导入服务入口
   - 解析 HTML 并返回 `CourseImportResult`
   - 持久化解析结果到本地存储
   - 自动分配课程颜色

2. **parsers/** - 解析器集合
   - `course_html_parser.dart` - 解析器接口
   - `course_html_parser_registry.dart` - 解析器注册表
   - `kingosoft_course_parser.dart` - 金格教务系统解析器

3. **models/course_import_models.dart** - 导入数据模型
   - `CourseImportSource` - 导入源封装
   - `ParsedCourse` - 解析后的课程
   - `CourseImportResult` - 解析结果
   - `ParseStatus` - 解析状态枚举

4. **utils/html_normalizer.dart** - HTML 标准化工具
   - 处理 JSON 字符串包装
   - 还原 Unicode 转义
   - 清理转义符

**使用示例**:

```dart
// 创建导入服务
final importService = CourseHtmlImportService();

// 解析并导入
final source = CourseImportSource(rawContent: htmlContent);
final result = await importService.importAndPersist(source);

if (result.isSuccess) {
  print('成功导入 ${result.courses.length} 门课程');
} else {
  print('导入失败: ${result.status}');
}
```

**扩展性**: 支持通过实现 `CourseHtmlParser` 接口添加新的教务系统解析器

---

## 服务层最佳实践

### ✅ 推荐做法

**1. 使用 try-catch 包裹所有 I/O 操作**
```dart
static Future<List<Course>> loadCourses() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    // ...
  } catch (e) {
    debugPrint('加载失败: $e');
    return [];
  }
}
```

**2. 提供清晰的错误日志**
```dart
catch (e) {
  debugPrint('加载课程数据失败: $e');  // 描述性错误信息
  return [];
}
```

**3. 使用常量定义存储键**
```dart
// ✅ 正确
static const String _coursesKey = 'saved_courses';

// ❌ 错误
prefs.setString('courses', data);  // 硬编码
```

**4. 并行加载多个资源**
```dart
// ✅ 正确
final results = await Future.wait([
  SettingsService.loadSemesterSettings(),
  CourseService.loadCourses(),
]);

// ❌ 错误 (串行加载)
final settings = await SettingsService.loadSemesterSettings();
final courses = await CourseService.loadCourses();
```

### ❌ 避免的做法

**1. 不处理异常**
```dart
// ❌ 错误
static Future<List<Course>> loadCourses() async {
  final jsonString = await rootBundle.loadString('assets/courses.json');
  return parseJson(jsonString);  // 异常会传播到 UI 层
}
```

**2. 在服务层包含 UI 逻辑**
```dart
// ❌ 错误
static Future<void> addCourse(Course course, BuildContext context) {
  // ...
  ScaffoldMessenger.of(context).showSnackBar(...);  // UI 逻辑
}
```

**3. 混合多个业务领域**
```dart
// ❌ 错误
class DataService {
  static Future<List<Course>> loadCourses() { ... }
  static Future<SemesterSettings> loadSettings() { ... }
  static Future<User> loadUser() { ... }  // 应该单独一个 UserService
}
```

---

## 扩展建议

### 1. 添加数据导入/导出功能

```dart
class CourseService {
  /// 导入课程数据 (从文件选择器)
  static Future<void> importCourses(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final coursesJson = jsonData['courses'] as List<dynamic>;

      final courses = coursesJson
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList();

      await saveCourses(courses);
    } catch (e) {
      throw FormatException('无效的课程数据格式');
    }
  }

  /// 导出课程数据为文件
  static Future<void> exportToFile(String filePath) async {
    final courses = await loadCourses();
    final jsonString = exportCoursesToJson(courses);

    // 写入文件 (需要文件操作权限)
    final file = File(filePath);
    await file.writeAsString(jsonString);
  }
}
```

### 2. 添加数据同步功能

```dart
class SyncService {
  /// 同步到云端
  static Future<void> syncToCloud(List<Course> courses) async {
    final jsonString = CourseService.exportCoursesToJson(courses);
    // 调用云端 API
  }

  /// 从云端拉取
  static Future<List<Course>> syncFromCloud() async {
    // 调用云端 API 获取数据
  }
}
```

### 3. 添加数据验证服务

```dart
class ValidationService {
  /// 验证课程数据
  static List<String> validateCourse(Course course) {
    final errors = <String>[];

    if (course.name.trim().isEmpty) {
      errors.add('课程名称不能为空');
    }

    if (course.weekday < 1 || course.weekday > 7) {
      errors.add('星期必须在1-7之间');
    }

    if (course.startSection < 1 || course.startSection > 10) {
      errors.add('节次必须在1-10之间');
    }

    return errors;
  }
}
```

---

## 测试建议

### 单元测试用例

```dart
void main() {
  group('CourseService', () {
    test('loadCourses should return empty list on error', () async {
      // 模拟 SharedPreferences 失败
      SharedPreferences.setMockInitialValues({});

      final courses = await CourseService.loadCourses();
      expect(courses, isEmpty);
    });

    test('hasTimeConflict should detect overlapping courses', () {
      final course1 = Course(
        weekday: 1,
        startSection: 1,
        duration: 2,
        startWeek: 1,
        endWeek: 10,
        // ...
      );

      final course2 = Course(
        weekday: 1,
        startSection: 2,  // 与 course1 重叠
        duration: 2,
        startWeek: 5,  // 与 course1 周次重叠
        endWeek: 15,
        // ...
      );

      expect(
        CourseService.hasTimeConflict([course1], course2),
        isTrue,
      );
    });

    test('hasTimeConflict should ignore excluded index', () {
      // 测试更新场景
    });
  });

  group('SettingsService', () {
    test('loadSemesterSettings should return default on first run', () async {
      SharedPreferences.setMockInitialValues({});

      final settings = await SettingsService.loadSemesterSettings();
      expect(settings, SemesterSettings.defaultSettings());
    });

    test('saveSemesterSettings should persist data', () async {
      final newSettings = SemesterSettings(
        startDate: DateTime(2025, 9, 1),
        totalWeeks: 18,
      );

      await SettingsService.saveSemesterSettings(newSettings);
      final loaded = await SettingsService.loadSemesterSettings();

      expect(loaded, newSettings);
    });
  });
}
```

---

## 性能优化建议

### 1. 避免重复加载

```dart
// ❌ 错误:每次都重新加载
class MyWidget extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: CourseService.loadCourses(),  // 每次 rebuild 都加载
      builder: (context, snapshot) { ... },
    );
  }
}

// ✅ 正确:缓存在状态中
class MyWidget extends StatefulWidget {
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();  // 仅加载一次
  }

  Future<void> _loadCourses() async {
    final courses = await CourseService.loadCourses();
    setState(() => _courses = courses);
  }
}
```

### 2. 使用批量操作

```dart
// ✅ 正确:批量保存
await CourseService.saveCourses(updatedCourses);

// ❌ 错误:逐个保存
for (final course in courses) {
  await CourseService.updateCourse(index, course);  // 多次 I/O
}
```

---

**文档更新**: 2025-10-16 | **维护者**: 查看根文档获取项目信息
