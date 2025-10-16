# lib/pages/ - 页面组件层

> 📍 **导航**: [← 返回根文档](../../CLAUDE.md) | **当前位置**: lib/pages/

## 模块概述

**职责**: 应用的完整页面组件,管理页面级状态和业务流程

**设计原则**:
- **StatefulWidget**: 所有页面都是有状态组件
- **单一职责**: 每个页面专注一个主要功能
- **服务调用**: 通过 services 层访问数据
- **路由管理**: 使用 Navigator 进行页面跳转

**依赖关系**:
- ✅ 依赖: models、services、widgets、utils
- ❌ 不被依赖: 作为应用层,不被其他模块依赖

---

## 文件清单

### 📄 course_table_page.dart

**主页面** - 课程表周历视图

**核心功能**:
- 可视化课程表网格展示
- 周次切换与日期计算
- 课程详情查看
- 导航到其他功能页面

**关键状态**:
- `_currentWeek`: 当前显示的周次
- `_courses`: 课程数据列表
- `_totalWeeks`: 学期总周数
- `_semesterStartDate`: 学期开始日期

**关键方法**:
- `_calculateWeekNumber(DateTime)`: 计算日期所在周次
- `_jumpToCurrentWeek()`: 跳转到本周
- `_reloadCourses()`: 重新加载课程数据
- `_reloadSettings()`: 重新加载学期设置

**布局结构**:
```
CourseTablePage
├── Header (日期 + 功能按钮)
├── WeekSelector (周次选择器)
└── PageView (周次切换)
    └── CourseGrid
        ├── TimeColumn (时间列)
        └── CoursesGrid (课程网格)
```

**参考位置**: [lib/pages/course_table_page.dart](../pages/course_table_page.dart)

---

### 📄 course_management_page.dart

**课程管理页面** - 课程 CRUD 操作

**核心功能**:
- 课程列表展示
- 添加/编辑/删除课程
- 课程时间冲突检测
- 数据持久化

**关键状态**:
- `_courses`: 课程列表
- `_isLoading`: 加载状态

**关键操作**:
- 添加课程: 打开 CourseEditDialog
- 编辑课程: 传递课程数据到 Dialog
- 删除课程: 确认后调用 CourseService.deleteCourse()
- 保存更改: 自动保存到本地存储

**参考位置**: [lib/pages/course_management_page.dart](../pages/course_management_page.dart)

---

### 📄 semester_settings_page.dart

**学期设置页面** - 配置学期参数

**核心功能**:
- 设置学期开始日期
- 设置学期总周数
- 重置为默认设置

**关键状态**:
- `_startDate`: 学期开始日期
- `_totalWeeks`: 学期总周数

**关键方法**:
- `_saveSettings()`: 保存设置到本地存储
- `_resetSettings()`: 恢复默认设置
- `_selectStartDate()`: 打开日期选择器

**参考位置**: [lib/pages/semester_settings_page.dart](../pages/semester_settings_page.dart)

---

## 页面间导航

**导航流程**:

```
CourseTablePage (主页)
├─→ CourseManagementPage (课程管理)
│   └─→ CourseEditDialog (编辑课程)
└─→ SemesterSettingsPage (学期设置)
```

**导航代码示例**:

```dart
// 从主页导航到课程管理
await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CourseManagementPage(),
  ),
);

// 返回时重新加载数据
await _reloadCourses();
```

---

## 状态管理模式

**当前模式**: StatefulWidget + setState

```dart
class _CourseTablePageState extends State<CourseTablePage> {
  List<Course> _courses = [];

  Future<void> _loadCourses() async {
    final courses = await CourseService.loadCourses();
    setState(() {
      _courses = courses;
    });
  }
}
```

**优点**:
- 简单直观
- 适合中小规模应用
- 无需额外依赖

**未来改进建议**:
- 使用 Provider 实现跨页面状态共享
- 使用 Riverpod 实现依赖注入
- 使用 Bloc 处理复杂业务逻辑

---

**文档更新**: 2025-10-16
