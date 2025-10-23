# lib/services/course_import/ - HTML 课程导入子模块

> 📍 **导航**: [← 返回根文档](../../../CLAUDE.md) | [← 返回 services](../CLAUDE.md) | **当前位置**: lib/services/course_import/

## 模块概述

**职责**: 从 HTML 页面（如教务系统课表）解析并导入课程数据

**设计原则**:
- **可扩展性**: 插件式解析器架构，支持多个教务系统
- **容错性**: 完善的错误处理和降级策略
- **可测试性**: 解析逻辑与 UI 完全分离
- **标准化**: HTML 预处理确保解析器输入一致

**依赖关系**:
- ✅ 依赖: `models/course.dart`, `utils/course_colors.dart`, `package:html`
- ✅ 被依赖: `pages/course_import_webview_page.dart`

---

## 架构设计

### 处理流程图

```
用户输入 HTML
    ↓
[HtmlNormalizer] 标准化处理
    ↓
[CourseHtmlImportService] 入口服务
    ↓
[CourseHtmlParserRegistry] 选择解析器
    ↓
[具体解析器] (如 KingosoftCourseParser)
    ↓
[ParsedCourse] 列表
    ↓
[CourseColorManager] 分配颜色
    ↓
[CourseService] 持久化存储
```

### 模块结构

```
lib/services/course_import/
├── course_html_import_service.dart  # 入口服务
├── models/
│   └── course_import_models.dart    # 导入相关数据模型
├── parsers/
│   ├── course_html_parser.dart      # 解析器接口
│   ├── course_html_parser_registry.dart  # 解析器注册表
│   └── kingosoft_course_parser.dart # 金格教务系统解析器
└── utils/
    └── html_normalizer.dart         # HTML 标准化工具
```

---

## 核心组件

### 📄 course_html_import_service.dart

**职责**: 解析入口，协调各组件完成从 HTML 到持久化的完整流程

**核心类**: `CourseHtmlImportService`

**关键方法**:

| 方法签名 | 功能描述 | 返回类型 |
|---------|---------|---------|
| `parseHtml(CourseImportSource)` | 解析 HTML，不持久化 | `CourseImportResult` |
| `importAndPersist(CourseImportSource)` | 解析并保存到本地 | `Future<CourseImportResult>` |
| `persistParsedCourses(List<ParsedCourse>, {bool append})` | 持久化解析结果 | `Future<void>` |

**使用示例**:

```dart
// 创建服务实例
final importService = CourseHtmlImportService();

// 解析 HTML
final source = CourseImportSource(
  rawContent: htmlContent,
  origin: Uri.parse('https://jwgl.example.edu.cn'),
);

final result = await importService.importAndPersist(source);

// 检查结果
if (result.isSuccess) {
  print('成功导入 ${result.courses.length} 门课程');
  print('使用解析器: ${result.parserId}');
} else {
  print('解析失败: ${result.status}');
  for (final msg in result.messages) {
    print('[${msg.severity}] ${msg.message}');
  }
}
```

**设计亮点**:
1. **颜色预设**: 导入时保留现有课程颜色，避免重复导入时颜色变化
2. **增量导入**: 支持追加模式和覆盖模式
3. **解耦设计**: 解析与持久化分离，方便单元测试

---

### 📄 models/course_import_models.dart

**职责**: 定义导入流程中的数据结构

**核心模型**:

#### 1. CourseImportSource

导入源数据封装：

```dart
class CourseImportSource {
  final String rawContent;  // 原始 HTML 内容
  final Uri? origin;         // 来源地址（可选）
}
```

#### 2. ParsedCourse

解析出的课程实体（尚未分配颜色）：

```dart
class ParsedCourse {
  final String name;          // 课程名称
  final String location;      // 上课地点
  final String teacher;       // 教师姓名
  final int weekday;          // 星期几 (1-7)
  final int startSection;     // 开始节次
  final int duration;         // 持续节数
  final int startWeek;        // 开始周次
  final int endWeek;          // 结束周次
  final String? rawWeeks;     // 原始周次字符串（用于调试）
  final String? rawSections;  // 原始节次字符串（用于调试）
  final List<String> notes;   // 附加说明
}
```

**设计亮点**:
- **保留原始数据**: `rawWeeks` 和 `rawSections` 便于诊断解析问题
- **附加说明**: `notes` 字段记录解析过程中的警告或特殊情况
- **断言验证**: weekday 范围检查 (1-7)

#### 3. CourseImportResult

解析结果封装：

```dart
class CourseImportResult {
  final ParseStatus status;               // 解析状态
  final List<ParsedCourse> courses;       // 解析出的课程列表
  final List<CourseImportMessage> messages; // 消息列表
  final String? parserId;                 // 使用的解析器 ID
  final Map<String, dynamic>? metadata;   // 元数据
  final List<FrameRequest>? frameRequests; // 需要的额外 frame（用于 iframe 页面）
}
```

#### 4. 枚举类型

**ParseStatus**:
- `success`: 完全成功
- `partial`: 部分成功（有课程但可能有错误）
- `unsupported`: 不支持的页面格式
- `needAdditionalInput`: 需要额外输入（如多 frame）
- `failed`: 完全失败

**ParserMessageSeverity**:
- `info`: 信息提示
- `warning`: 警告
- `error`: 错误

---

### 📄 parsers/course_html_parser.dart

**职责**: 定义解析器接口

**抽象类**: `CourseHtmlParser`

```dart
abstract class CourseHtmlParser {
  /// 唯一解析器 ID
  String get id;
  
  /// 解析器描述
  String get description;
  
  /// 判定是否可处理给定上下文
  bool canHandle(CourseHtmlParsingContext context);
  
  /// 执行解析
  CourseImportParseResult parse(CourseHtmlParsingContext context);
}
```

**解析上下文**: `CourseHtmlParsingContext`

```dart
class CourseHtmlParsingContext {
  final CourseImportSource source;   // 原始数据源
  final String normalizedHtml;        // 标准化后的 HTML
  final Document document;            // 解析后的 DOM 树
}
```

---

### 📄 parsers/course_html_parser_registry.dart

**职责**: 解析器注册与管理

**核心类**: `CourseHtmlParserRegistry`

**关键方法**:

| 方法签名 | 功能描述 | 返回类型 |
|---------|---------|---------|
| `register(CourseHtmlParser)` | 注册新解析器 | `void` |
| `tryParse(CourseHtmlParsingContext)` | 尝试解析（遍历所有解析器） | `CourseImportParseResult?` |
| `get parsers` | 获取已注册解析器列表 | `List<CourseHtmlParser>` |

**使用示例**:

```dart
// 创建注册表并注册解析器
final registry = CourseHtmlParserRegistry(
  parsers: [
    KingosoftCourseParser(),
    // 可添加更多解析器...
  ],
);

// 动态注册
registry.register(MyCustomParser());

// 尝试解析
final result = registry.tryParse(context);
if (result == null) {
  print('没有可用的解析器');
}
```

**设计特性**:
- **顺序匹配**: 按注册顺序尝试，返回首个 `canHandle` 为 true 的结果
- **ID 唯一性**: 注册时检查解析器 ID 冲突
- **不可变列表**: `parsers` getter 返回不可变视图

---

### 📄 parsers/kingosoft_course_parser.dart

**职责**: 解析金格教务系统课表 HTML

**核心类**: `KingosoftCourseParser implements CourseHtmlParser`

**识别特征**:
```dart
bool canHandle(CourseHtmlParsingContext context) {
  // 检查特征 DOM 结构
  final rows = context.document.querySelectorAll('tr');
  return rows.any((row) => 
    row.querySelector('td[rowspan]') != null &&
    row.text.contains('星期')
  );
}
```

**解析策略**:
1. **表格结构识别**: 定位 `<table>` 和表头行
2. **单元格合并处理**: 处理 `rowspan` / `colspan` 属性
3. **文本提取**: 从 `<td>` 中提取课程信息
4. **模式匹配**: 正则解析周次和节次范围
5. **冲突检测**: 同一时段多门课程拆分为多条记录

**关键正则表达式**:

```dart
// 周次范围: "1-16周" 或 "1,3,5周"
final weekPattern = RegExp(r'(\d+)(?:-(\d+))?周');

// 节次范围: "1-2节" 或 "第1-2节"
final sectionPattern = RegExp(r'第?(\d+)-(\d+)节');
```

**数据提取示例**:

输入 HTML 片段：
```html
<td rowspan="2">
  大学物理<br/>
  教学楼210<br/>
  牛富全<br/>
  1-16周<br/>
  1-2节
</td>
```

输出 `ParsedCourse`：
```dart
ParsedCourse(
  name: '大学物理',
  location: '教学楼210',
  teacher: '牛富全',
  weekday: 1,  // 根据列位置判断
  startSection: 1,
  duration: 2,
  startWeek: 1,
  endWeek: 16,
  rawWeeks: '1-16周',
  rawSections: '1-2节',
)
```

**错误处理**:
- 单元格格式异常 → 添加 warning 消息，跳过该课程
- 时间范围解析失败 → 使用默认值 (1-20周)
- 多门课程冲突 → 分别创建，添加 info 消息

---

### 📄 utils/html_normalizer.dart

**职责**: 标准化 HTML 输入，处理常见编码问题

**核心函数**: `String normalizeHtml(String raw)`

**处理步骤**:

1. **JSON 字符串包装解析**
   ```dart
   // 输入: "\"<html>...</html>\""
   // 输出: "<html>...</html>"
   ```

2. **Unicode 转义还原**
   ```dart
   // \u003C → <
   // \u003E → >
   // \u0026 → &
   // \u0027 → '
   // \u0022 → "
   ```

3. **转义符清理**
   ```dart
   // \" → "
   // \' → '
   ```

**使用场景**:
- WebView 导出的 HTML 可能被 JSON 编码
- 某些教务系统返回的 HTML 包含 Unicode 转义
- 确保解析器接收到干净的 HTML 文本

**示例**:

```dart
final raw = r'"\u003Chtml\u003E\u003Cbody\u003E课表\u003C/body\u003E\u003C/html\u003E"';
final normalized = normalizeHtml(raw);
print(normalized);
// 输出: <html><body>课表</body></html>
```

---

## 扩展新解析器

### 步骤 1: 实现解析器类

```dart
class MyUniversityParser implements CourseHtmlParser {
  @override
  String get id => 'my_university_v1';
  
  @override
  String get description => '我的大学教务系统解析器';
  
  @override
  bool canHandle(CourseHtmlParsingContext context) {
    // 检查特征（如特定 class、id、meta 标签等）
    return context.document.querySelector('.my-university-marker') != null;
  }
  
  @override
  CourseImportParseResult parse(CourseHtmlParsingContext context) {
    final courses = <ParsedCourse>[];
    final messages = <CourseImportMessage>[];
    
    // 实现解析逻辑
    // ...
    
    return CourseImportParseResult(
      parserId: id,
      status: courses.isEmpty ? ParseStatus.failed : ParseStatus.success,
      courses: courses,
      messages: messages,
    );
  }
}
```

### 步骤 2: 注册到系统

修改 `course_html_import_service.dart`:

```dart
CourseHtmlImportService({
  CourseHtmlParserRegistry? registry,
}) : _registry = registry ??
          CourseHtmlParserRegistry(
            parsers: <CourseHtmlParser>[
              KingosoftCourseParser(),
              MyUniversityParser(),  // ← 添加新解析器
            ],
          );
```

### 步骤 3: 编写测试

```dart
void main() {
  test('MyUniversityParser can parse sample HTML', () {
    final parser = MyUniversityParser();
    final html = '''<html>...</html>''';
    final source = CourseImportSource(rawContent: html);
    final context = CourseHtmlParsingContext(
      source: source,
      normalizedHtml: normalizeHtml(html),
      document: html_parser.parse(normalizeHtml(html)),
    );
    
    expect(parser.canHandle(context), isTrue);
    final result = parser.parse(context);
    expect(result.status, ParseStatus.success);
    expect(result.courses, isNotEmpty);
  });
}
```

---

## 数据流图

### 导入流程详解

```
┌─────────────────────────────────────────────┐
│ 用户在 WebView 中访问教务系统课表页面           │
└───────────────┬─────────────────────────────┘
                ↓
┌───────────────────────────────────────────────┐
│ JavaScript 提取页面 HTML                        │
│ window.document.documentElement.outerHTML      │
└───────────────┬───────────────────────────────┘
                ↓
┌───────────────────────────────────────────────┐
│ [HtmlNormalizer.normalizeHtml]                 │
│ - 去除 JSON 字符串包装                          │
│ - 还原 Unicode 转义 (\u003C → <)               │
│ - 清理转义符 (\" → ")                          │
└───────────────┬───────────────────────────────┘
                ↓
┌───────────────────────────────────────────────┐
│ [html_parser.parse]                            │
│ 解析为 DOM 树                                   │
└───────────────┬───────────────────────────────┘
                ↓
┌───────────────────────────────────────────────┐
│ [CourseHtmlParserRegistry.tryParse]            │
│ 遍历所有解析器调用 canHandle()                   │
└───────────────┬───────────────────────────────┘
                ↓
        ┌───────┴────────┐
        │ canHandle?      │
        └───┬────────┬───┘
          No│        │Yes
            ↓        ↓
    ┌──────────┐  ┌──────────────────────────┐
    │ 尝试下一个 │  │ [Parser.parse]            │
    │ 解析器    │  │ 提取课程数据                │
    └──────────┘  └──────────┬────────────────┘
                            ↓
                ┌────────────────────────────┐
                │ 返回 CourseImportParseResult │
                │ - status: ParseStatus       │
                │ - courses: List<ParsedCourse>│
                │ - messages: 警告/错误列表     │
                └────────────┬────────────────┘
                            ↓
                ┌────────────────────────────┐
                │ [persistParsedCourses]      │
                │ 1. 加载现有课程              │
                │ 2. 预设已有课程颜色          │
                │ 3. 为新课程分配颜色          │
                │ 4. 合并/覆盖并保存           │
                └────────────┬────────────────┘
                            ↓
                ┌────────────────────────────┐
                │ [CourseService.saveCourses] │
                │ 持久化到 SharedPreferences   │
                └────────────────────────────┘
```

---

## 最佳实践

### ✅ 推荐做法

1. **增量测试**: 先用小样本 HTML 测试解析器，再测试完整页面
   ```dart
   test('parse single course cell', () {
     final html = '<td>课程名<br/>地点<br/>教师<br/>1-16周<br/>1-2节</td>';
     // ...
   });
   ```

2. **容错处理**: 解析异常时返回 partial 状态，而非直接失败
   ```dart
   try {
     final course = parseCourseCell(cell);
     courses.add(course);
   } catch (e) {
     messages.add(CourseImportMessage(
       severity: ParserMessageSeverity.warning,
       message: '课程解析失败',
       detail: e.toString(),
     ));
   }
   ```

3. **保留原始数据**: 用 `rawWeeks` / `rawSections` 记录原始字符串
   ```dart
   ParsedCourse(
     // ...
     rawWeeks: '1-16周(单)',  // 保留原始格式
     notes: ['仅单周上课'],    // 附加说明
   )
   ```

### ❌ 避免的做法

1. **不检查 null**: DOM 查询可能返回 null
   ```dart
   // ❌ 错误
   final text = cell.querySelector('.name').text;
   
   // ✅ 正确
   final nameElement = cell.querySelector('.name');
   final text = nameElement?.text ?? '';
   ```

2. **硬编码索引**: 表格结构可能变化
   ```dart
   // ❌ 错误
   final courseName = cells[0].text;
   
   // ✅ 正确
   final nameCell = row.querySelector('td.course-name');
   ```

3. **忽略消息**: 即使部分成功也应记录警告
   ```dart
   // ✅ 正确
   if (parsedWeeks == null) {
     messages.add(CourseImportMessage(
       severity: ParserMessageSeverity.warning,
       message: '周次解析失败，使用默认值 1-20',
     ));
     startWeek = 1;
     endWeek = 20;
   }
   ```

---

## 测试建议

### 单元测试用例

参考 `test/course_html_import_service_test.dart`:

```dart
void main() {
  group('CourseHtmlImportService', () {
    test('should parse valid HTML', () async {
      final service = CourseHtmlImportService();
      final html = loadTestHtmlFixture('kingosoft_sample.html');
      final source = CourseImportSource(rawContent: html);
      
      final result = service.parseHtml(source);
      
      expect(result.status, ParseStatus.success);
      expect(result.courses.length, greaterThan(0));
      expect(result.parserId, 'kingosoft_v1');
    });
    
    test('should handle unsupported HTML', () {
      final service = CourseHtmlImportService();
      final source = CourseImportSource(rawContent: '<html></html>');
      
      final result = service.parseHtml(source);
      
      expect(result.status, ParseStatus.unsupported);
      expect(result.messages, isNotEmpty);
    });
  });
}
```

### 测试数据准备

1. **从真实教务系统导出 HTML**
2. **脱敏处理** (移除学号、姓名等敏感信息)
3. **保存为测试 fixture**
4. **文档化数据来源和特征**

---

## 故障排查

### 常见问题

#### 1. 解析器不工作 (canHandle 返回 false)

**原因**: HTML 结构与预期不符

**解决**:
- 打印 `context.normalizedHtml` 检查标准化结果
- 检查 DOM 选择器是否正确 (`querySelector` 结果)
- 更新 `canHandle` 逻辑以匹配新结构

#### 2. 课程数据缺失或错误

**原因**: 正则表达式不匹配或单元格格式变化

**解决**:
- 打印解析过程中的中间变量
- 检查正则表达式是否覆盖所有格式
- 添加日志记录解析失败的原始文本

#### 3. 导入后颜色变化

**原因**: 未正确预设颜色

**解决**:
- 确保 `persistParsedCourses` 中调用了 `CourseColorManager.presetColors`
- 检查课程名称是否完全一致（区分大小写、空格）

---

## 性能优化建议

1. **缓存 DOM 查询结果**: 避免重复 `querySelector`
   ```dart
   final rows = document.querySelectorAll('tr');
   for (final row in rows) {
     final cells = row.querySelectorAll('td'); // 只查询一次
     // ...
   }
   ```

2. **提前终止**: 识别到解析器后立即返回
   ```dart
   bool canHandle(CourseHtmlParsingContext context) {
     // 快速检查明显特征
     if (!context.normalizedHtml.contains('金格教务')) {
       return false; // 提前返回
     }
     // 详细检查
     return context.document.querySelector('.kingosoft-table') != null;
   }
   ```

3. **避免不必要的对象创建**: 复用正则表达式
   ```dart
   // ✅ 类级别定义
   static final _weekPattern = RegExp(r'(\d+)-(\d+)周');
   
   // ❌ 方法内重复创建
   final pattern = RegExp(r'(\d+)-(\d+)周');
   ```

---

**文档更新**: 2025-10-23 | **维护者**: 查看根文档获取项目信息

