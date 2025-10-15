# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

课程表应用（Curriculum）- 一个使用 Flutter 开发的跨平台课程管理应用。

**包名**: com.lparksi.curriculum
**支持平台**: Android, Web
**Flutter 版本**: 3.35.6
**Dart 版本**: 3.9.2

## 开发命令

### 运行应用
```bash
# 运行在 Android 设备/模拟器
flutter run -d android

# 运行在 Web 浏览器
flutter run -d chrome

# 查看可用设备
flutter devices

# 热重载: 按 'r'
# 热重启: 按 'R'
# 退出: 按 'q'
```

### 构建
```bash
# 构建 Android APK (debug)
flutter build apk

# 构建 Android APK (release)
flutter build apk --release

# 构建 Android App Bundle (用于 Google Play)
flutter build appbundle

# 构建 Web
flutter build web
```

### 测试与代码质量
```bash
# 运行所有测试
flutter test

# 运行单个测试文件
flutter test test/widget_test.dart

# 运行代码分析
flutter analyze

# 格式化代码
dart format .

# 检查代码格式（不修改文件）
dart format --output=none --set-exit-if-changed .
```

### 依赖管理
```bash
# 获取依赖
flutter pub get

# 更新依赖
flutter pub upgrade

# 查看过期的依赖
flutter pub outdated

# 清理构建缓存
flutter clean
```

## 代码架构

### 当前结构
- **lib/main.dart**: 应用入口，包含 `MyApp` (根组件) 和 `MyHomePage` (主页面)
- **test/**: Widget 测试目录
- **android/**: Android 平台特定代码
- **web/**: Web 平台特定代码

### 主题配置
应用使用 Material Design，主题色为青绿色 (Color.fromARGB(255, 80, 180, 182))，配置在 `lib/main.dart:31`。

### 包配置
- 使用 `flutter_lints` 进行代码规范检查
- 遵循 Flutter 推荐的 lint 规则（配置在 `analysis_options.yaml`）

## 平台特定注意事项

### Android
- 包名: com.lparksi.curriculum
- 配置文件: `android/app/src/main/AndroidManifest.xml`
- 应用名称: "curriculum" (可在 AndroidManifest.xml 中修改)
- 最小 SDK 版本和其他配置在 `android/app/build.gradle`

### Web
- 入口文件: `web/index.html`
- Web 资源目录: `web/`

## 开发规范

### 代码风格
- 使用 `const` 构造函数以提升性能
- 遵循 Flutter 官方命名规范
- Widget 命名使用大驼峰 (PascalCase)
- 变量和方法使用小驼峰 (camelCase)
- 私有成员使用下划线前缀

### 状态管理
当前使用 Flutter 内置的 StatefulWidget + setState 模式。随着应用复杂度增加，可能需要引入状态管理方案（如 Provider、Riverpod 或 Bloc）。

### Widget 组织
- StatelessWidget 用于不可变 UI
- StatefulWidget 用于需要维护状态的 UI
- 使用 `const` 构造函数优化不可变 Widget

## 调试技巧

```bash
# 启用 Widget 调试边框（运行时按 'p'）
# 启用性能叠加层（运行时按 'P'）

# 查看 Widget 树
flutter run --observatory-port=8888

# 启用详细日志
flutter run -v
```
