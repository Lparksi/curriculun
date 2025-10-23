# 课程表应用测试任务清单

> 📅 创建时间: 2025-10-21
> 📊 总任务数: 125个测试用例
> ⏱️ 预计工作量: 5-8天

---

## 📈 测试进度总览

| 优先级 | 模块数量 | 测试用例数 | 已完成 | 进度 |
|-------|---------|-----------|--------|------|
| **P0 (必须)** | 3 | 48 | 0 | 0% |
| **P1 (强烈建议)** | 3 | 25 | 7 | 28% |
| **P2 (建议)** | 4 | 36 | 0 | 0% |
| **P3 (可选)** | 3 | 16 | 0 | 0% |
| **总计** | 13 | **125** | **7** | **5.6%** |

**当前状态**:
- ✅ 已完成: ExportService 部分测试 (7个用例)
- ✅ 已完成: CourseHtmlImportService 测试 (5个用例)
- 🔄 进行中: 无
- ⏳ 待开始: 113个用例

---

## 🔴 P0 - 最高优先级 (必须完成)

### 1. CourseService 测试 ⭐⭐⭐⭐⭐
**文件**: `test/course_service_test.dart`
**重要性**: 核心CRUD + 冲突检测算法
**预计工作量**: 1天
**状态**: ⏳ 未开始

#### 数据加载 (5个测试用例)
- [ ] `loadAllCourses` - 首次加载返回空列表
- [ ] `loadAllCourses` - 从本地存储加载已保存课程
- [ ] `loadAllCourses` - 加载失败返回空列表
- [ ] `loadCoursesBySemester` - 按学期筛选课程
- [ ] `loadCoursesFromAssets` - 从assets加载课程

#### 数据保存 (3个测试用例)
- [ ] `saveCourses` - 成功保存课程到本地
- [ ] `saveCourses` - 保存失败不崩溃
- [ ] `saveCourses` - 保存后能正确读取

#### CRUD操作 (4个测试用例)
- [ ] `addCourse` - 成功添加课程
- [ ] `updateCourse` - 更新指定索引的课程
- [ ] `deleteCourse` - 删除指定索引的课程
- [ ] `resetToDefault` - 重置清空数据

#### 时间冲突检测 🔥 核心算法 (7个测试用例)
- [ ] `hasTimeConflict` - 同一天同一时间冲突
- [ ] `hasTimeConflict` - 不同天不冲突
- [ ] `hasTimeConflict` - 周次不重叠不冲突
- [ ] `hasTimeConflict` - 节次不重叠不冲突
- [ ] `hasTimeConflict` - 排除自身索引（更新场景）
- [ ] `getConflictingCourses` - 返回所有冲突课程
- [ ] `getConflictingCourses` - 无冲突返回空列表

---

### 2. SettingsService 测试 ⭐⭐⭐⭐⭐
**文件**: `test/settings_service_test.dart`
**重要性**: 学期配置 + 数据迁移
**预计工作量**: 1天
**状态**: ⏳ 未开始

#### 学期管理 (6个测试用例)
- [ ] `getAllSemesters` - 首次加载返回默认学期
- [ ] `getAllSemesters` - 加载已保存的学期列表
- [ ] `addSemester` - 成功添加新学期
- [ ] `updateSemester` - 更新学期信息
- [ ] `deleteSemester` - 删除学期
- [ ] `deleteSemester` - 不允许删除唯一的学期

#### 激活学期 (4个测试用例)
- [ ] `getActiveSemester` - 返回当前激活的学期
- [ ] `setActiveSemesterId` - 设置激活学期
- [ ] `getActiveSemester` - 无激活学期时返回第一个
- [ ] `deleteSemester` - 删除激活学期时自动切换

#### 数据迁移 🔥 关键功能 (3个测试用例)
- [ ] `_migrateOldSettings` - 成功迁移旧版单学期数据
- [ ] `_migrateOldSettings` - 迁移后删除旧数据
- [ ] `_migrateOldSettings` - 迁移失败返回null

#### 学期复制 (2个测试用例)
- [ ] `duplicateSemester` - 成功复制学期
- [ ] `duplicateSemester` - 源学期不存在时抛出异常

---

### 3. TimeTableService 测试 ⭐⭐⭐⭐⭐
**文件**: `test/time_table_service_test.dart`
**重要性**: 时间表核心配置
**预计工作量**: 0.5-1天
**状态**: ⏳ 未开始

#### 时间表管理 (7个测试用例)
- [ ] `loadTimeTables` - 首次加载返回默认时间表
- [ ] `loadTimeTables` - 加载已保存的时间表列表
- [ ] `saveTimeTables` - 成功保存时间表
- [ ] `addTimeTable` - 成功添加新时间表
- [ ] `addTimeTable` - ID重复时抛出异常
- [ ] `updateTimeTable` - 更新时间表
- [ ] `deleteTimeTable` - 删除时间表

#### 激活时间表 (3个测试用例)
- [ ] `getActiveTimeTable` - 返回当前激活的时间表
- [ ] `setActiveTimeTableId` - 设置激活时间表
- [ ] `deleteTimeTable` - 删除激活时间表时自动切换

#### 时间验证 🔥 关键算法 (4个测试用例)
- [ ] `isValidTimeFormat` - 有效的时间格式 (HH:mm)
- [ ] `isValidTimeFormat` - 无效的时间格式
- [ ] `isTimeRangeValid` - 开始时间早于结束时间
- [ ] `isTimeRangeValid` - 开始时间晚于结束时间

---

## 🟠 P1 - 高优先级 (强烈建议)

### 4. ExportService 测试增强 ⭐⭐⭐⭐☆
**文件**: `test/export_service_test.dart` (已存在)
**重要性**: 数据导入导出 + 版本管理
**预计工作量**: 0.5天
**状态**: 🔄 部分完成 (7/12)

#### 已完成测试 ✅ (7个)
- [x] `exportAllData` - 返回有效JSON
- [x] `exportCourses` - 仅导出课程
- [x] `importAllData` - 导入有效数据
- [x] `importAllData` - 验证数据格式
- [x] `importAllData` - 合并模式保留现有数据
- [x] `ImportResult.getSummary` - 摘要信息正确
- [x] 基础导入导出流程

#### 待补充测试 🆕 (5个)
- [ ] `importAllData` - 版本升级 (1.0.0 → 1.1.0)
- [ ] `importAllData` - 版本不兼容时提示错误
- [ ] `importAllData` - 迁移报告生成正确
- [ ] `exportSemesters` - 仅导出学期数据
- [ ] `exportTimeTables` - 仅导出时间表数据

---

### 5. WebDavService 测试 ⭐⭐⭐⭐☆
**文件**: `test/webdav_service_test.dart`
**重要性**: 云端备份恢复
**预计工作量**: 1天 (需Mock WebDAV客户端)
**状态**: ⏳ 未开始

#### 连接测试 (2个测试用例)
- [ ] `testConnection` - 成功连接
- [ ] `testConnection` - 连接失败

#### 备份功能 (4个测试用例)
- [ ] `backupToWebDav` - 成功备份并返回路径
- [ ] `backupToWebDav` - 备份失败抛出异常
- [ ] `listBackupFiles` - 列出所有备份文件
- [ ] `deleteBackupFile` - 删除指定备份文件

#### 恢复功能 🔥 关键功能 (4个测试用例)
- [ ] `restoreFromWebDav` - 成功恢复（覆盖模式）
- [ ] `restoreFromWebDav` - 成功恢复（合并模式）
- [ ] `restoreFromWebDav` - 文件不存在时抛出异常
- [ ] `previewBackupFile` - 预览备份文件内容

#### 配置管理 (2个测试用例)
- [ ] `WebDavConfigService.saveConfig` - 保存配置
- [ ] `WebDavConfigService.loadConfig` - 加载配置

---

### 6. ConfigVersionManager 测试 ⭐⭐⭐⭐☆
**文件**: `test/config_version_manager_test.dart`
**重要性**: 配置版本管理
**预计工作量**: 0.5天
**状态**: ⏳ 未开始

#### 版本解析 (3个测试用例)
- [ ] `parseVersion` - 解析有效版本号
- [ ] `parseVersion` - 无效版本号返回null
- [ ] `compareVersions` - 版本比较正确

#### 版本升级 🔥 核心逻辑 (5个测试用例)
- [ ] `needsUpgrade` - 需要升级
- [ ] `needsUpgrade` - 不需要升级
- [ ] `upgradeConfig` - 1.0.0 → 1.1.0 升级成功
- [ ] `upgradeConfig` - 不支持的版本抛出异常
- [ ] `generateMigrationReport` - 迁移报告格式正确

---

## 🟡 P2 - 中优先级 (建议完成)

### 7. Models 序列化测试 ⭐⭐⭐⭐☆
**预计工作量**: 1天

#### 7.1 Course Model 测试
**文件**: `test/models/course_test.dart`
**状态**: ⏳ 未开始

##### JSON序列化 (4个测试用例)
- [ ] `fromJson` - 完整数据反序列化
- [ ] `fromJson` - 缺少可选字段使用默认值
- [ ] `toJson` - 完整数据序列化
- [ ] `toJson` - 可选字段条件序列化

##### 业务方法 (4个测试用例)
- [ ] `getTimeRangeText` - 正确格式化时间范围
- [ ] `copyWith` - 正确复制和修改
- [ ] `colorToHex` - 颜色转换正确
- [ ] `hexToColor` - 十六进制转颜色正确

#### 7.2 SemesterSettings Model 测试
**文件**: `test/models/semester_settings_test.dart`
**状态**: ⏳ 未开始

##### JSON序列化 (3个测试用例)
- [ ] `fromJson` - 完整数据反序列化
- [ ] `toJson` - 完整数据序列化
- [ ] `defaultSettings` - 默认值正确

##### 业务方法 (3个测试用例)
- [ ] `copyWith` - 正确复制和修改
- [ ] `calculateWeekNumber` - 周次计算正确
- [ ] `isWeekInRange` - 周次范围判断正确

#### 7.3 TimeTable Model 测试
**文件**: `test/models/time_table_test.dart`
**状态**: ⏳ 未开始

##### JSON序列化 (3个测试用例)
- [ ] `TimeTable.fromJson` - 完整数据反序列化
- [ ] `TimeTable.toJson` - 完整数据序列化
- [ ] `SectionTime` JSON序列化

##### 业务方法 (4个测试用例)
- [ ] `defaultTimeTable` - 默认值正确
- [ ] `getSectionTime` - 获取节次时间
- [ ] `copyWith` - 正确复制和修改
- [ ] 节次排序正确

---

### 8. FirebaseConsentService 测试 ⭐⭐⭐☆☆
**文件**: `test/firebase_consent_service_test.dart`
**预计工作量**: 0.5天
**状态**: ⏳ 未开始

#### 配置管理 (4个测试用例)
- [ ] `loadConsent` - 首次加载返回默认配置
- [ ] `saveConsent` - 成功保存配置
- [ ] `loadConsent` - 读取已保存配置
- [ ] `saveConsent` - hasShown标记正确更新

#### 功能开关 (2个测试用例)
- [ ] `FirebaseConsent` 默认值 - 所有功能默认关闭
- [ ] `FirebaseConsent.fromJson` - 正确解析配置

---

### 9. AppThemeService 测试 ⭐⭐⭐☆☆
**文件**: `test/app_theme_service_test.dart`
**预计工作量**: 0.25天
**状态**: ⏳ 未开始

#### 主题管理 (5个测试用例)
- [ ] `loadThemeMode` - 首次加载返回system
- [ ] `saveThemeMode` - 保存light模式
- [ ] `saveThemeMode` - 保存dark模式
- [ ] `saveThemeMode` - 保存system模式
- [ ] `loadThemeMode` - 读取已保存的主题

---

### 10. DisplayPreferencesService 测试 ⭐⭐⭐☆☆
**文件**: `test/display_preferences_service_test.dart`
**预计工作量**: 0.25天
**状态**: ⏳ 未开始

#### 显示偏好 (4个测试用例)
- [ ] `loadShowHiddenCourses` - 默认返回false
- [ ] `saveShowHiddenCourses` - 保存true
- [ ] `saveShowHiddenCourses` - 保存false
- [ ] `loadShowHiddenCourses` - 读取已保存的值

---

## 🟢 P3 - 低优先级 (可选)

### 11. CourseColorManager 测试 ⭐⭐⭐☆☆
**文件**: `test/utils/course_colors_test.dart`
**预计工作量**: 0.5天
**状态**: ⏳ 未开始

#### 颜色分配 (5个测试用例)
- [ ] `getColorForCourse` - 同名课程返回相同颜色
- [ ] `getColorForCourse` - 不同课程返回不同颜色
- [ ] `getColorForCourse` - 18色循环分配
- [ ] `reset` - 重置后重新分配
- [ ] 所有颜色符合WCAG AA级对比度

---

### 12. PerformanceTracker 测试 ⭐⭐☆☆☆
**文件**: `test/utils/performance_tracker_test.dart`
**预计工作量**: 0.25天
**状态**: ⏳ 未开始

#### 性能跟踪 (4个测试用例)
- [ ] `traceAsync` - 成功跟踪异步操作
- [ ] `addMetric` - 添加指标
- [ ] `addAttribute` - 添加属性
- [ ] Firebase未启用时不崩溃

---

### 13. Widget 测试 ⭐⭐☆☆☆
**预计工作量**: 0.5天
**状态**: ⏳ 未开始
**注意**: 需在Web平台运行

#### CourseEditDialog 测试
**文件**: `test/widgets/course_edit_dialog_test.dart`
- [ ] 显示冲突提示
- [ ] 表单验证
- [ ] 保存按钮功能

#### SemesterEditDialog 测试
**文件**: `test/widgets/semester_edit_dialog_test.dart`
- [ ] 日期选择器
- [ ] 表单验证

#### TimeTableEditDialog 测试
**文件**: `test/widgets/time_table_edit_dialog_test.dart`
- [ ] 节次添加/删除
- [ ] 时间验证

---

## 📅 推荐实施计划

### 阶段1: P0 核心业务 (第1-3天)
**目标**: 核心业务逻辑测试覆盖率 > 80%

- **第1天**: CourseService (19个用例)
  - 上午: 数据加载 + 保存 (8个)
  - 下午: CRUD操作 (4个)
  - 晚上: 冲突检测算法 (7个)

- **第2天**: SettingsService (15个用例)
  - 上午: 学期管理 (6个)
  - 下午: 激活学期 + 数据迁移 (7个)
  - 晚上: 学期复制 (2个)

- **第3天**: TimeTableService (14个用例)
  - 上午: 时间表管理 (7个)
  - 下午: 激活时间表 + 时间验证 (7个)

### 阶段2: P1 数据安全 (第4-5天)
**目标**: 数据安全功能测试覆盖率 100%

- **第4天**:
  - 上午: ExportService 增强 (5个新用例)
  - 下午: ConfigVersionManager (8个用例)

- **第5天**: WebDavService (12个用例)
  - 上午: Mock WebDAV客户端 + 连接测试 (2个)
  - 下午: 备份功能 (4个)
  - 晚上: 恢复功能 + 配置管理 (6个)

### 阶段3: P2 辅助功能 (第6-7天)
**目标**: 整体测试覆盖率 > 70%

- **第6天**: Models 序列化 (21个用例)
  - 上午: Course Model (8个)
  - 下午: SemesterSettings + TimeTable (13个)

- **第7天**: 服务类测试
  - 上午: FirebaseConsentService (6个)
  - 下午: AppThemeService + DisplayPreferencesService (9个)

### 阶段4: P3 可选 (第8天)
**目标**: 全面测试覆盖

- **第8天**:
  - 上午: CourseColorManager (5个)
  - 下午: PerformanceTracker (4个)
  - 晚上: Widget 测试 (7个)

---

## 🎯 里程碑

- [ ] **里程碑1**: P0测试完成 (48个用例) - 第3天结束
- [ ] **里程碑2**: P1测试完成 (25个用例) - 第5天结束
- [ ] **里程碑3**: P2测试完成 (36个用例) - 第7天结束
- [ ] **里程碑4**: 全部测试完成 (125个用例) - 第8天结束

---

## 📝 开发规范

### 测试文件命名
- 服务测试: `test/服务名_test.dart`
- 模型测试: `test/models/模型名_test.dart`
- 工具测试: `test/utils/工具名_test.dart`
- Widget测试: `test/widgets/组件名_test.dart`

### 测试结构
```dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('服务/类名', () {
    setUp(() async {
      // 重置测试环境
      SharedPreferences.setMockInitialValues({});
    });

    group('功能模块1', () {
      test('测试用例1', () async {
        // Given (准备)
        // When (执行)
        // Then (断言)
      });
    });
  });
}
```

### 测试原则
1. **隔离性**: 每个测试独立运行,使用 setUp 重置环境
2. **可重复**: 测试结果稳定,不依赖外部状态
3. **清晰性**: 使用描述性测试名称
4. **完整性**: 覆盖正常和异常场景

---

## 🔧 常用命令

```bash
# 运行所有测试
flutter test

# 运行单个测试文件
flutter test test/course_service_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage

# 查看覆盖率报告
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# 运行代码分析
flutter analyze
```

---

## 📊 测试覆盖率目标

| 模块 | 目标覆盖率 | 当前覆盖率 |
|------|----------|-----------|
| Services | 90% | 未测量 |
| Models | 95% | 未测量 |
| Utils | 80% | 未测量 |
| Widgets | 60% | 未测量 |
| **整体** | **80%** | **未测量** |

---

**最后更新**: 2025-10-21
**维护者**: 开发团队
**相关文档**: [CLAUDE.md](CLAUDE.md)
