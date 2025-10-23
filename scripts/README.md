# 📋 版本管理脚本

本目录包含用于管理应用版本号的实用脚本。

## 📁 脚本列表

### 1. `check_version.sh` - 版本号检查

检查 `pubspec.yaml` 和 `android/version_code.txt` 是否同步。

**用法：**
```bash
./scripts/check_version.sh
```

**输出示例：**
```
========================================
📋 版本号同步检查
========================================

📄 pubspec.yaml:
  完整版本: 1.0.0+12
  版本名称: 1.0.0
  版本代码: 12

📄 android/version_code.txt:
  版本代码: 12

🔍 同步检查:
✅ 版本号同步正常

🚀 下次构建版本:
  版本名称: 1.0.0
  版本代码: 13
  完整版本: 1.0.0+13
```

### 2. `sync_version.sh` - 版本号同步

自动同步 `pubspec.yaml` 和 `android/version_code.txt` 的版本号。

**用法：**
```bash
./scripts/sync_version.sh
```

**功能：**
- 读取两个文件的版本号
- 选择较大的版本号作为统一版本
- 更新两个文件
- 显示 Git 提交建议

---

## 🔄 版本管理工作流

### GitHub Actions 自动化（推荐）

**触发时机：**
- 推送到 `main` 或 `develop` 分支
- 创建 `v*` 标签
- 手动触发

**自动化流程：**
1. ✅ 读取 `pubspec.yaml` 和 `version_code.txt`
2. ✅ 自动递增版本号（取最大值 +1）
3. ✅ 使用新版本号构建 APK
4. ✅ 构建成功后自动更新两个文件
5. ✅ 自动提交更新到仓库

**下次构建时：**
- 版本号会自动从 13 递增到 14
- 无需手动干预

### 本地开发工作流

#### 场景 1：日常开发（不需要版本号）
```bash
# 正常开发，无需关心版本号
flutter run
```

#### 场景 2：本地测试构建
```bash
# 检查当前版本
./scripts/check_version.sh

# 构建 APK（使用当前版本）
flutter build apk --release
```

#### 场景 3：手动更新版本号
```bash
# 方式 1：自动同步（推荐）
./scripts/sync_version.sh

# 方式 2：手动编辑
# 编辑 pubspec.yaml: version: 1.0.0+12
# 编辑 android/version_code.txt: 12
vim pubspec.yaml
vim android/version_code.txt

# 验证同步
./scripts/check_version.sh
```

#### 场景 4：准备发布新版本
```bash
# 1. 更新版本名称和代码
# 编辑 pubspec.yaml
# 从: version: 1.0.0+12
# 到: version: 1.0.1+13  # 修复版本
# 或: version: 1.1.0+13  # 新功能版本

# 2. 同步到 version_code.txt
./scripts/sync_version.sh

# 3. 提交更改
git add pubspec.yaml android/version_code.txt
git commit -m "chore: bump version to 1.0.1+13"

# 4. 创建标签（可选，触发 Release 构建）
git tag v1.0.1
git push origin v1.0.1
```

---

## 📊 版本号规则

### 语义化版本（Version Name）

格式：`MAJOR.MINOR.PATCH`

- **MAJOR（主版本）**：不兼容的 API 变更
  - 例：`1.0.0` → `2.0.0`
- **MINOR（次版本）**：向后兼容的新功能
  - 例：`1.0.0` → `1.1.0`
- **PATCH（修订版）**：向后兼容的 Bug 修复
  - 例：`1.0.0` → `1.0.1`

### Android 版本代码（Version Code）

- **整数**，必须单调递增
- 用于 Android 系统判断版本新旧
- 每次发布必须 +1

### 完整示例

| 版本名称 | 版本代码 | pubspec.yaml | version_code.txt | 说明 |
|---------|---------|--------------|------------------|------|
| 1.0.0 | 1 | `version: 1.0.0+1` | `1` | 首次发布 |
| 1.0.1 | 2 | `version: 1.0.1+2` | `2` | Bug 修复 |
| 1.0.2 | 3 | `version: 1.0.2+3` | `3` | Bug 修复 |
| 1.1.0 | 4 | `version: 1.1.0+4` | `4` | 新功能 |
| 2.0.0 | 5 | `version: 2.0.0+5` | `5` | 重大更新 |

---

## ⚠️ 常见问题

### Q1: 版本号不同步怎么办？

**答：** 运行同步脚本
```bash
./scripts/sync_version.sh
```

### Q2: GitHub Actions 构建后本地版本过期？

**答：** 拉取最新代码
```bash
git pull origin develop
./scripts/check_version.sh  # 验证同步
```

### Q3: 如何跳过版本号递增？

**答：** 不推荐，但可以在 GitHub Actions 触发前手动调整：
```bash
# 设置固定版本号
echo "100" > android/version_code.txt
sed -i 's/^version:.*/version: 2.0.0+100/' pubspec.yaml
git add . && git commit -m "chore: set version to 2.0.0+100"
```

### Q4: 如何查看构建历史版本？

**答：** 查看 Git 提交历史
```bash
git log --oneline --grep="ci: update version code"
```

---

## 🛠️ 故障排查

### 问题：无法安装新 APK

**可能原因：** 新 APK 的 versionCode 小于已安装版本

**解决方案：**
1. 检查版本号：`./scripts/check_version.sh`
2. 确保新版本号大于已安装版本
3. 同步版本号：`./scripts/sync_version.sh`

### 问题：GitHub Actions 构建失败

**可能原因：** Git 推送权限问题

**解决方案：**
1. 检查仓库设置 → Actions → General
2. 确保 "Workflow permissions" 设置为 "Read and write permissions"
3. 启用 "Allow GitHub Actions to create and approve pull requests"

---

## 📚 相关文档

- [Android 版本管理](https://developer.android.com/studio/publish/versioning)
- [语义化版本 2.0.0](https://semver.org/lang/zh-CN/)
- [Flutter 构建配置](https://docs.flutter.dev/deployment/android#build-an-apk)

---

**最后更新：** 2025-10-23
**维护者：** GitHub Actions & Development Team
