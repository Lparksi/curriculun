# lib/widgets/ - 可复用组件层

> 📍 **导航**: [← 返回根文档](../../CLAUDE.md) | **当前位置**: lib/widgets/

## 模块概述

**职责**: 可复用的UI组件,Dialog、表单等

**设计原则**:
- **可复用性**: 在多个页面使用
- **封装性**: 隐藏内部实现细节
- **可配置性**: 通过参数自定义行为
- **独立性**: 不依赖特定页面状态

**依赖关系**:
- ✅ 依赖: models、services (仅用于数据操作)
- ✅ 被依赖: pages (页面使用这些组件)

---

## 文件清单

### 📄 course_detail_dialog.dart

**课程详情对话框** - 展示课程完整信息

**核心功能**:
- 显示课程名称、地点、教师
- 显示时间段、周次范围、节次范围
- 使用课程主题色

**静态方法**:
```dart
static void show(BuildContext context, Course course) {
  showDialog(
    context: context,
    builder: (context) => CourseDetailDialog(course: course),
  );
}
```

**使用示例**:
```dart
// 在课程卡片点击时调用
onTap: () => CourseDetailDialog.show(context, course),
```

**参考位置**: [lib/widgets/course_detail_dialog.dart](../widgets/course_detail_dialog.dart)

---

### 📄 course_edit_dialog.dart

**课程编辑对话框** - 添加/编辑课程

**核心功能**:
- 表单输入(课程名、地点、教师)
- 时间选择(星期、节次、持续时长)
- 周次范围选择
- 数据验证
- 时间冲突检测

**构造参数**:
- `course`: 可选,编辑模式时传入
- `existingCourses`: 用于冲突检测
- `onSave`: 保存回调函数

**使用示例**:
```dart
// 添加课程
CourseEditDialog.show(
  context,
  existingCourses: _courses,
  onSave: (course) async {
    await CourseService.addCourse(course);
    _reloadCourses();
  },
);

// 编辑课程
CourseEditDialog.show(
  context,
  course: existingCourse,
  existingCourses: _courses,
  courseIndex: index,
  onSave: (course) async {
    await CourseService.updateCourse(index, course);
    _reloadCourses();
  },
);
```

**验证规则**:
- 课程名称: 不能为空
- 星期: 1-7
- 节次: 1-10
- 持续时长: ≥1
- 周次范围: startWeek ≤ endWeek

**参考位置**: [lib/widgets/course_edit_dialog.dart](../widgets/course_edit_dialog.dart)

---

## 组件使用建议

### ✅ 推荐做法

1. **使用静态方法显示 Dialog**:
   ```dart
   CourseDetailDialog.show(context, course);
   ```

2. **通过回调更新父组件状态**:
   ```dart
   onSave: (course) {
     setState(() {
       _courses.add(course);
     });
   }
   ```

3. **传递必要数据,避免内部访问全局状态**:
   ```dart
   // ✅ 正确
   CourseEditDialog.show(context, existingCourses: _courses);

   // ❌ 错误
   // Dialog 内部访问全局变量
   ```

### ❌ 避免的做法

1. **在 Widget 内部调用 Navigator**:
   ```dart
   // ❌ 错误
   class MyDialog extends StatelessWidget {
     void save() {
       Navigator.pop(context);  // 应该由外部控制
     }
   }
   ```

2. **直接修改传入的数据**:
   ```dart
   // ❌ 错误
   void updateCourse(Course course) {
     course.name = newName;  // course 是 final
   }
   ```

---

**文档更新**: 2025-10-16
