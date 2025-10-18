/// 隐私政策数据模型
///
/// 提供隐私政策的中英文内容
class PrivacyPolicy {
  /// 获取隐私政策内容（根据语言代码）
  static String getContent(String languageCode) {
    return languageCode.startsWith('zh') ? contentZh : contentEn;
  }

  /// 中文隐私政策
  static const String contentZh = '''
# 隐私政策

**生效日期：** 2025年10月18日
**最后更新：** 2025年10月18日

## 引言

感谢您使用课程表应用（以下简称"本应用"）。我们非常重视您的隐私权，本隐私政策旨在向您说明我们如何收集、使用、存储和保护您的个人信息。

**重要提示**：本应用默认不收集任何个人信息。所有可选的数据收集功能均需要您的明确同意。

---

## 1. 信息收集与使用

### 1.1 本地存储数据

以下数据**仅存储在您的设备本地**，不会上传到任何服务器：

#### 课程数据
- **收集内容**：课程名称、上课地点、教师姓名、时间安排
- **存储位置**：设备本地存储（SharedPreferences）
- **使用目的**：显示和管理您的课程表
- **数据传输**：不传输到任何服务器

#### 学期设置
- **收集内容**：学期开始日期、学期周数、学期名称
- **存储位置**：设备本地存储
- **使用目的**：计算当前周次和课程安排
- **数据传输**：不传输到任何服务器

#### 时间表配置
- **收集内容**：自定义节次时间表
- **存储位置**：设备本地存储
- **使用目的**：显示准确的上课时间
- **数据传输**：不传输到任何服务器

#### 应用偏好设置
- **收集内容**：主题模式（亮/暗/跟随系统）、Firebase 功能同意状态
- **存储位置**：设备本地存储
- **使用目的**：记住您的应用设置
- **数据传输**：不传输到任何服务器

### 1.2 可选的 Firebase 服务

以下服务需要您的**明确同意**才会启用，您可以随时在设置中更改：

#### Firebase Crashlytics（崩溃报告）
- **收集内容**：
  - 崩溃信息和堆栈跟踪
  - 应用版本号
  - 设备型号和操作系统版本
  - 崩溃发生时间
- **数据接收方**：Google Firebase（美国）
- **使用目的**：帮助我们快速发现和修复应用崩溃问题
- **保留期限**：90天后自动删除
- **第三方隐私政策**：[Firebase 隐私政策](https://firebase.google.com/support/privacy)

#### Firebase Performance Monitoring（性能监控）
- **收集内容**：
  - 应用启动时间
  - 屏幕渲染性能
  - 网络请求性能（仅监控性能，不收集请求内容）
  - 设备型号和操作系统版本
- **数据接收方**：Google Firebase（美国）
- **使用目的**：帮助我们优化应用性能和用户体验
- **保留期限**：90天后自动删除
- **第三方隐私政策**：[Firebase 隐私政策](https://firebase.google.com/support/privacy)

#### Firebase Analytics（数据分析）
- **当前状态**：预留功能，暂未实际实施
- **未来可能收集**：
  - 匿名使用统计（功能使用频率）
  - 应用会话时长
  - 设备类型和操作系统版本
- **数据接收方**：Google Firebase（美国）
- **使用目的**：了解功能使用情况，改进产品设计

**重要说明**：
- 您可以选择禁用所有 Firebase 功能，这不会影响应用的核心功能
- Firebase 服务由 Google 提供，数据处理遵循 Google 的隐私政策
- 您可以随时在"设置 > 隐私与数据"中更改同意选择（需重启应用生效）

### 1.3 可选的 WebDAV 云端备份

如果您启用并配置 WebDAV 备份功能：

- **收集内容**：所有课程、学期、时间表数据
- **传输方式**：通过 HTTPS 加密传输（如果您的服务器支持）
- **存储位置**：您自己配置的 WebDAV 服务器
- **使用目的**：云端备份，方便数据恢复和多设备同步
- **数据控制**：您完全控制备份数据的存储和删除

**WebDAV 配置信息**：
- 服务器地址、用户名、密码存储在设备本地
- 不会发送到我们的服务器或任何第三方

---

## 2. 我们不收集的信息

本应用**不会收集**以下信息：
- ❌ 您的姓名、电子邮件、电话号码等身份信息
- ❌ 您的位置信息
- ❌ 您的通讯录、照片、短信等敏感数据
- ❌ 您的浏览历史或其他应用使用情况
- ❌ 任何可以直接识别您身份的信息

---

## 3. 数据共享与披露

### 3.1 数据共享原则

我们**不会**将您的个人信息出售、出租或以其他方式共享给第三方，除非：

#### Firebase 服务（如果您同意）
- **共享对象**：Google Firebase
- **共享内容**：崩溃报告、性能数据（见 1.2 节）
- **共享目的**：应用质量改进
- **法律依据**：您的明确同意

#### 法律要求
在以下情况下，我们可能会披露您的信息：
- 遵守法律法规、法院命令或政府机关的要求
- 保护本应用、我们的用户或公众的合法权益
- 防止、检测或应对欺诈、安全或技术问题

### 3.2 不共享的数据

- **本地存储数据**：永远不会共享到任何服务器
- **WebDAV 配置**：仅存储在您的设备本地

---

## 4. 数据安全

我们采取以下措施保护您的数据：

### 4.1 技术措施
- **本地加密**：SharedPreferences 由操作系统加密存储
- **HTTPS 传输**：与 Firebase 和 WebDAV 的通信使用加密连接
- **最小化原则**：仅收集必要的数据

### 4.2 访问控制
- 您的本地数据仅限本应用访问
- 其他应用无法读取您的课程数据

### 4.3 数据安全风险提示
- 如果您的设备丢失或被他人访问，本地数据可能会被读取
- 建议您启用设备锁屏密码
- 如果使用 WebDAV 备份，请确保服务器的安全性

---

## 5. 您的权利

根据适用的隐私法律，您享有以下权利：

### 5.1 访问权
- 您可以随时查看应用内存储的所有数据

### 5.2 删除权
- **课程数据**：在应用内删除课程
- **所有数据**：卸载应用将删除所有本地数据
- **Firebase 数据**：禁用 Firebase 功能后，新数据不再上传；历史数据将在 90 天后自动删除

### 5.3 修改权
- 您可以随时修改课程、学期、时间表等数据

### 5.4 撤回同意权
- 您可以随时在"设置 > 隐私与数据"中禁用 Firebase 功能

### 5.5 数据导出权
- 使用"设置 > 数据管理 > 导出数据"功能，导出所有课程数据为 JSON 文件

### 5.6 投诉权
- 如对我们的数据处理有疑问，请联系我们（见第 8 节）

---

## 6. 儿童隐私

本应用不针对 13 岁以下儿童。我们不会故意收集 13 岁以下儿童的个人信息。如果您发现我们收集了儿童的个人信息，请联系我们，我们将及时删除。

---

## 7. 隐私政策的变更

我们可能会不时更新本隐私政策。如有重大变更，我们将通过以下方式通知您：
- 在应用内显示通知
- 更新本页面的"最后更新"日期

继续使用本应用即表示您接受更新后的隐私政策。

---

## 8. 联系我们

如果您对本隐私政策或数据处理有任何疑问、意见或投诉，请通过以下方式联系我们：

- **GitHub Issues**: [https://github.com/lparksi/curriculum/issues](https://github.com/lparksi/curriculum/issues)
- **电子邮件**: [请在 GitHub 项目页面查看]

我们将在 **7 个工作日内**回复您的请求。

---

## 9. 法律适用

本隐私政策的解释、执行和争议解决适用中华人民共和国法律（不包括冲突法规则）。

---

## 10. 附录：第三方服务

### Firebase（Google LLC）
- **服务提供商**：Google LLC（美国）
- **隐私政策**：https://firebase.google.com/support/privacy
- **数据传输**：您的数据可能被传输到美国或其他国家/地区
- **法律依据**：您的明确同意

---

**感谢您信任课程表应用！**

如有任何疑问，请随时联系我们。
''';

  /// 英文隐私政策
  static const String contentEn = '''
# Privacy Policy

**Effective Date:** October 18, 2025
**Last Updated:** October 18, 2025

## Introduction

Thank you for using the Curriculum App (hereinafter referred to as "the App"). We take your privacy seriously. This Privacy Policy explains how we collect, use, store, and protect your personal information.

**Important Notice**: The App does not collect any personal information by default. All optional data collection features require your explicit consent.

---

## 1. Information Collection and Use

### 1.1 Local Storage Data

The following data is **stored only on your device** and is never uploaded to any server:

#### Course Data
- **Content**: Course names, locations, teacher names, schedules
- **Storage Location**: Local device storage (SharedPreferences)
- **Purpose**: Display and manage your course schedule
- **Data Transfer**: Not transmitted to any server

#### Semester Settings
- **Content**: Semester start date, total weeks, semester name
- **Storage Location**: Local device storage
- **Purpose**: Calculate current week and course schedules
- **Data Transfer**: Not transmitted to any server

#### Timetable Configuration
- **Content**: Custom class time schedules
- **Storage Location**: Local device storage
- **Purpose**: Display accurate class times
- **Data Transfer**: Not transmitted to any server

#### App Preferences
- **Content**: Theme mode (light/dark/system), Firebase consent status
- **Storage Location**: Local device storage
- **Purpose**: Remember your app settings
- **Data Transfer**: Not transmitted to any server

### 1.2 Optional Firebase Services

The following services require your **explicit consent** to be enabled. You can change these settings at any time:

#### Firebase Crashlytics (Crash Reporting)
- **Content Collected**:
  - Crash information and stack traces
  - App version number
  - Device model and OS version
  - Crash timestamp
- **Data Recipient**: Google Firebase (United States)
- **Purpose**: Help us quickly identify and fix app crashes
- **Retention Period**: Automatically deleted after 90 days
- **Third-Party Privacy Policy**: [Firebase Privacy Policy](https://firebase.google.com/support/privacy)

#### Firebase Performance Monitoring
- **Content Collected**:
  - App startup time
  - Screen rendering performance
  - Network request performance (only monitors performance, does not collect request content)
  - Device model and OS version
- **Data Recipient**: Google Firebase (United States)
- **Purpose**: Help us optimize app performance and user experience
- **Retention Period**: Automatically deleted after 90 days
- **Third-Party Privacy Policy**: [Firebase Privacy Policy](https://firebase.google.com/support/privacy)

#### Firebase Analytics (Data Analysis)
- **Current Status**: Reserved feature, not yet implemented
- **May Collect in Future**:
  - Anonymous usage statistics (feature usage frequency)
  - App session duration
  - Device type and OS version
- **Data Recipient**: Google Firebase (United States)
- **Purpose**: Understand feature usage to improve product design

**Important Notes**:
- You can disable all Firebase features without affecting the app's core functionality
- Firebase services are provided by Google, and data processing follows Google's privacy policy
- You can change your consent choices at any time in "Settings > Privacy & Data" (requires app restart)

### 1.3 Optional WebDAV Cloud Backup

If you enable and configure WebDAV backup:

- **Content**: All course, semester, and timetable data
- **Transfer Method**: Encrypted via HTTPS (if your server supports it)
- **Storage Location**: Your own configured WebDAV server
- **Purpose**: Cloud backup for data recovery and multi-device sync
- **Data Control**: You have full control over backup data storage and deletion

**WebDAV Configuration**:
- Server address, username, and password are stored locally on your device
- Not sent to our servers or any third parties

---

## 2. Information We Do Not Collect

The App **does not collect** the following information:
- ❌ Your name, email, phone number, or other identifying information
- ❌ Your location information
- ❌ Your contacts, photos, messages, or other sensitive data
- ❌ Your browsing history or other app usage
- ❌ Any information that can directly identify you

---

## 3. Data Sharing and Disclosure

### 3.1 Data Sharing Principles

We **will not** sell, rent, or otherwise share your personal information with third parties, except:

#### Firebase Services (If You Consent)
- **Shared With**: Google Firebase
- **Shared Content**: Crash reports, performance data (see Section 1.2)
- **Sharing Purpose**: App quality improvement
- **Legal Basis**: Your explicit consent

#### Legal Requirements
We may disclose your information in the following situations:
- Comply with laws, regulations, court orders, or government requests
- Protect the legitimate rights of the App, our users, or the public
- Prevent, detect, or respond to fraud, security, or technical issues

### 3.2 Data Not Shared

- **Local Storage Data**: Never shared with any server
- **WebDAV Configuration**: Only stored on your local device

---

## 4. Data Security

We take the following measures to protect your data:

### 4.1 Technical Measures
- **Local Encryption**: SharedPreferences is encrypted by the operating system
- **HTTPS Transfer**: Communications with Firebase and WebDAV use encrypted connections
- **Minimization Principle**: Only collect necessary data

### 4.2 Access Control
- Your local data is only accessible by this app
- Other apps cannot read your course data

### 4.3 Data Security Risk Warning
- If your device is lost or accessed by others, local data may be read
- We recommend enabling device lock screen password
- If using WebDAV backup, ensure your server's security

---

## 5. Your Rights

Under applicable privacy laws, you have the following rights:

### 5.1 Right to Access
- You can view all data stored in the app at any time

### 5.2 Right to Delete
- **Course Data**: Delete courses within the app
- **All Data**: Uninstalling the app will delete all local data
- **Firebase Data**: After disabling Firebase features, new data will not be uploaded; historical data will be automatically deleted after 90 days

### 5.3 Right to Modify
- You can modify course, semester, and timetable data at any time

### 5.4 Right to Withdraw Consent
- You can disable Firebase features at any time in "Settings > Privacy & Data"

### 5.5 Right to Data Portability
- Use "Settings > Data Management > Export Data" to export all course data as a JSON file

### 5.6 Right to Complain
- If you have questions about our data processing, please contact us (see Section 8)

---

## 6. Children's Privacy

This app is not directed at children under 13. We do not knowingly collect personal information from children under 13. If you discover that we have collected personal information from a child, please contact us, and we will promptly delete it.

---

## 7. Changes to Privacy Policy

We may update this Privacy Policy from time to time. If there are significant changes, we will notify you through:
- In-app notifications
- Updating the "Last Updated" date on this page

Continued use of the App indicates your acceptance of the updated Privacy Policy.

---

## 8. Contact Us

If you have any questions, comments, or complaints about this Privacy Policy or data processing, please contact us:

- **GitHub Issues**: [https://github.com/lparksi/curriculum/issues](https://github.com/lparksi/curriculum/issues)
- **Email**: [Please see GitHub project page]

We will respond to your request within **7 business days**.

---

## 9. Governing Law

The interpretation, execution, and dispute resolution of this Privacy Policy shall be governed by the laws of the People's Republic of China (excluding conflict of law rules).

---

## 10. Appendix: Third-Party Services

### Firebase (Google LLC)
- **Service Provider**: Google LLC (United States)
- **Privacy Policy**: https://firebase.google.com/support/privacy
- **Data Transfer**: Your data may be transferred to the United States or other countries/regions
- **Legal Basis**: Your explicit consent

---

**Thank you for trusting the Curriculum App!**

If you have any questions, please feel free to contact us.
''';
}
