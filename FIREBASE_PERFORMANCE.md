# Firebase Performance Monitoring 配置指南

## 📊 概述

本应用已集成 Firebase Performance Monitoring，用于监控应用的性能表现，包括：

- ✅ **自动监控**：应用启动时间、界面渲染、网络请求
- ✅ **自定义跟踪**：关键业务操作的性能（数据加载、保存等）
- ✅ **性能指标**：自定义指标（如课程数量、操作耗时）
- ✅ **属性过滤**：按不同条件过滤性能数据

---

## 🚀 快速开始

### 1. 自动收集的数据

Firebase Performance Monitoring 自动收集以下数据（无需额外代码）：

#### 应用启动时间
- 测量从应用启动到首次渲染的时间
- 包括冷启动和热启动

#### 界面渲染性能
- 监控 UI 渲染帧率
- 检测卡顿和掉帧
- 慢速渲染和冻结帧

#### HTTP/HTTPS 网络请求
- 自动监控所有网络请求
- 记录请求时长、响应大小、成功率

---

## 🎯 已添加的自定义跟踪

### 课程数据操作

| 跟踪名称 | 触发时机 | 监控指标 |
|---------|---------|---------|
| `load_courses` | 加载课程列表 | 课程数量 |
| `save_courses` | 保存课程数据 | 课程数量 |
| `add_course` | 添加新课程 | - |
| `update_course` | 更新课程 | - |
| `delete_course` | 删除课程 | - |

### 学期设置操作

| 跟踪名称 | 触发时机 | 监控指标 |
|---------|---------|---------|
| `load_semester_settings` | 加载学期设置 | - |
| `save_semester_settings` | 保存学期设置 | - |

### 时间表操作

| 跟踪名称 | 触发时机 | 监控指标 |
|---------|---------|---------|
| `load_time_tables` | 加载时间表列表 | 时间表数量 |
| `get_active_time_table` | 获取激活时间表 | - |

---

## 💻 使用 PerformanceTracker

### 基本用法

```dart
import 'package:curriculum/utils/performance_tracker.dart';

// 方法 1: 简单跟踪异步操作
await PerformanceTracker.instance.traceAsync(
  traceName: 'my_operation',
  operation: () async {
    // 你的异步代码
    return await someAsyncOperation();
  },
);

// 方法 2: 跟踪同步操作
await PerformanceTracker.instance.traceSync(
  traceName: 'my_sync_operation',
  operation: () {
    // 你的同步代码
    return someResult;
  },
);
```

### 添加自定义属性

自定义属性用于过滤和分组性能数据：

```dart
await PerformanceTracker.instance.traceAsync(
  traceName: 'load_courses',
  operation: () async {
    return await CourseService.loadAllCourses();
  },
  attributes: {
    'source': 'local_storage',  // 数据来源
    'semester_id': semesterId,   // 学期ID
  },
);
```

### 添加自定义指标

自定义指标用于记录数值数据：

```dart
await PerformanceTracker.instance.traceAsync(
  traceName: 'load_courses',
  operation: () async {
    return await CourseService.loadAllCourses();
  },
  onComplete: (trace, result) {
    // 记录加载的课程数量
    PerformanceTracker.instance.addMetric(
      trace,
      'course_count',
      result.length,
    );
  },
);
```

### 手动控制跟踪

对于更复杂的场景，可以手动控制跟踪的开始和停止：

```dart
// 开始跟踪
final trace = await PerformanceTracker.instance.startTrace('complex_operation');

try {
  // 步骤 1
  await step1();
  PerformanceTracker.instance.addAttribute(trace, 'step1', 'completed');

  // 步骤 2
  await step2();
  PerformanceTracker.instance.addAttribute(trace, 'step2', 'completed');

  // 添加指标
  PerformanceTracker.instance.addMetric(trace, 'total_items', itemCount);

} catch (e) {
  // 记录错误
  PerformanceTracker.instance.addAttribute(trace, 'error', e.toString());
} finally {
  // 停止跟踪
  await PerformanceTracker.instance.stopTrace(trace);
}
```

---

## 📈 在 Firebase 控制台查看数据

### 访问 Performance 面板

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 选择你的项目
3. 点击左侧菜单的 **Performance Monitoring**

### 查看数据类型

#### 1. 概览 (Overview)
- 应用启动时间趋势
- 网络请求成功率
- 界面渲染性能

#### 2. 自定义跟踪 (Custom traces)
- 查看所有自定义跟踪的性能数据
- 按时间范围、设备、版本过滤
- 查看自定义属性和指标

#### 3. 网络请求 (Network requests)
- 所有 HTTP/HTTPS 请求的统计
- 按 URL 分组
- 查看请求时长、成功率、载荷大小

#### 4. 屏幕渲染 (Screen rendering)
- 慢速渲染帧
- 冻结帧
- 按屏幕分组

---

## 🔍 常见使用场景

### 场景 1：监控数据加载性能

```dart
// 在数据加载操作中添加跟踪
Future<List<Course>> loadCourses() async {
  return PerformanceTracker.instance.traceAsync(
    traceName: PerformanceTraces.loadCourses,
    operation: () async {
      final courses = await CourseService.loadAllCourses();
      return courses;
    },
    attributes: {
      'source': 'local_storage',
    },
    onComplete: (trace, courses) {
      // 记录加载的课程数量
      PerformanceTracker.instance.addMetric(
        trace,
        'course_count',
        courses.length,
      );
    },
  );
}
```

### 场景 2：监控页面渲染性能

```dart
class MyPage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _trackPageLoad();
  }

  Future<void> _trackPageLoad() async {
    final trace = await PerformanceTracker.instance.startTrace(
      'page_${widget.runtimeType}_load',
    );

    // 页面加载完成后停止跟踪
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PerformanceTracker.instance.stopTrace(trace);
    });
  }
}
```

### 场景 3：监控网络请求

```dart
// 使用 PerformanceTracker 包装网络请求
Future<Response> fetchData() async {
  return PerformanceTracker.instance.traceHttpRequest(
    url: 'https://api.example.com/data',
    method: HttpMethod.Get,
    request: () async {
      // 你的网络请求代码
      return await http.get(Uri.parse('https://api.example.com/data'));
    },
    attributes: {
      'endpoint': '/data',
    },
  );
}
```

---

## ⚙️ 配置选项

### 启用/禁用性能监控

默认情况下，性能监控仅在 Release 模式下启用。如需手动控制：

```dart
// 启用性能监控
await PerformanceTracker.instance.setPerformanceCollectionEnabled(true);

// 禁用性能监控
await PerformanceTracker.instance.setPerformanceCollectionEnabled(false);
```

### Debug 模式行为

在 Debug 模式下：
- 跟踪代码仍会执行，但不会发送数据到 Firebase
- 在控制台会打印跟踪日志（以 `⏱️ [Performance]` 开头）
- 这样可以在开发时测试跟踪代码，而不影响生产数据

---

## 🎯 最佳实践

### ✅ 推荐做法

1. **使用有意义的跟踪名称**
   ```dart
   // ✅ 正确：清晰描述操作
   'load_courses'
   'save_semester_settings'

   // ❌ 错误：模糊不清
   'operation1'
   'function'
   ```

2. **添加有用的属性和指标**
   ```dart
   // ✅ 正确：提供上下文信息
   attributes: {
     'source': 'local_storage',
     'semester_id': semesterId,
   }

   // ✅ 正确：记录有意义的数值
   addMetric(trace, 'course_count', courses.length);
   ```

3. **跟踪关键业务操作**
   - 数据加载/保存
   - 复杂计算
   - 用户交互响应
   - 页面切换

4. **使用常量管理跟踪名称**
   ```dart
   // 使用预定义常量
   PerformanceTraces.loadCourses
   PerformanceTraces.saveCourses
   ```

### ❌ 避免的做法

1. **不要过度跟踪**
   - 避免跟踪每个微小操作
   - 专注于关键性能瓶颈

2. **不要在跟踪中包含敏感信息**
   ```dart
   // ❌ 错误：包含敏感数据
   attributes: {
     'user_password': password,  // 永远不要这样做！
     'credit_card': cardNumber,
   }
   ```

3. **不要忘记停止跟踪**
   ```dart
   // ❌ 错误：开始了但没有停止
   final trace = await startTrace('my_op');
   await doSomething();
   // 忘记调用 stopTrace(trace)
   ```

---

## 📊 性能优化建议

根据 Performance Monitoring 数据，可以进行以下优化：

### 如果数据加载慢
1. 实现数据缓存
2. 使用懒加载
3. 优化 JSON 解析
4. 并行加载多个资源

### 如果界面渲染慢
1. 减少 Widget 重建次数
2. 使用 `const` 构造函数
3. 使用 `ListView.builder` 而非 `ListView`
4. 避免在 build 方法中进行复杂计算

### 如果网络请求慢
1. 使用 HTTP 缓存
2. 压缩请求/响应数据
3. 实现请求重试机制
4. 使用 CDN 加速

---

## 🐛 调试技巧

### 在 Debug 模式下查看跟踪日志

运行应用时，在控制台查找以下日志：

```
⏱️ [Performance] 开始跟踪: load_courses
📊 [Performance] 添加指标: course_count = 19
✅ [Performance] 停止跟踪: load_courses
```

### 启用详细日志

如需在 Release 模式下查看日志，可以修改 `PerformanceTracker`：

```dart
// 临时启用日志（仅用于调试）
final trace = await startTrace('my_operation');
debugPrint('Trace started: ${trace.name}');
```

---

## 📖 参考资源

- [Firebase Performance Monitoring 官方文档](https://firebase.google.com/docs/perf-mon)
- [Flutter 性能优化指南](https://docs.flutter.dev/perf)
- [性能监控最佳实践](https://firebase.google.com/docs/perf-mon/best-practices)

---

## ⚡ 性能跟踪清单

### 已实现的跟踪
- [x] 课程数据加载
- [x] 课程数据保存
- [x] 学期设置加载
- [ ] 页面渲染性能
- [ ] 数据导入/导出操作
- [ ] WebDAV 云备份操作

### 待添加的跟踪
- [ ] 课程表页面加载时间
- [ ] 课程编辑对话框打开时间
- [ ] 配置导出性能
- [ ] 配置导入性能
- [ ] WebDAV 上传/下载速度

---

**最后更新**: 2025-10-17
**维护者**: 查看项目 README 获取联系信息
