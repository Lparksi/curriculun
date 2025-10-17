/// WebDAV 配置模型
/// 存储 WebDAV 服务器连接信息
class WebDavConfig {
  /// 配置版本号
  final String version;

  /// 服务器地址（例如：https://dav.example.com）
  final String serverUrl;

  /// 用户名
  final String username;

  /// 密码
  final String password;

  /// 备份目录路径（相对于 WebDAV 根目录）
  final String backupPath;

  /// 是否启用 WebDAV 备份
  final bool enabled;

  const WebDavConfig({
    this.version = '1.1.0',
    required this.serverUrl,
    required this.username,
    required this.password,
    this.backupPath = '/curriculum_backup',
    this.enabled = false,
  });

  /// 从 JSON 创建配置
  factory WebDavConfig.fromJson(Map<String, dynamic> json) {
    return WebDavConfig(
      version: json['version'] as String? ?? '1.1.0',
      serverUrl: json['serverUrl'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      backupPath: json['backupPath'] as String? ?? '/curriculum_backup',
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'backupPath': backupPath,
      'enabled': enabled,
    };
  }

  /// 创建默认配置
  factory WebDavConfig.defaultConfig() {
    return const WebDavConfig(
      version: '1.1.0',
      serverUrl: '',
      username: '',
      password: '',
      backupPath: '/curriculum_backup',
      enabled: false,
    );
  }

  /// 复制并修改部分字段
  WebDavConfig copyWith({
    String? version,
    String? serverUrl,
    String? username,
    String? password,
    String? backupPath,
    bool? enabled,
  }) {
    return WebDavConfig(
      version: version ?? this.version,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      backupPath: backupPath ?? this.backupPath,
      enabled: enabled ?? this.enabled,
    );
  }

  /// 验证配置是否有效
  bool get isValid {
    return serverUrl.isNotEmpty &&
        username.isNotEmpty &&
        password.isNotEmpty &&
        backupPath.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WebDavConfig &&
        other.version == version &&
        other.serverUrl == serverUrl &&
        other.username == username &&
        other.password == password &&
        other.backupPath == backupPath &&
        other.enabled == enabled;
  }

  @override
  int get hashCode {
    return version.hashCode ^
        serverUrl.hashCode ^
        username.hashCode ^
        password.hashCode ^
        backupPath.hashCode ^
        enabled.hashCode;
  }

  @override
  String toString() {
    return 'WebDavConfig(version: $version, serverUrl: $serverUrl, username: $username, '
        'backupPath: $backupPath, enabled: $enabled)';
  }
}
