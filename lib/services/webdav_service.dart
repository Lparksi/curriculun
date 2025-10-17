import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../models/webdav_config.dart';
import 'export_service.dart';
import 'webdav_config_service.dart';

/// WebDAV 备份文件信息
class WebDavBackupFile {
  final String name;
  final String path;
  final DateTime? modifiedTime;
  final int? size;

  const WebDavBackupFile({
    required this.name,
    required this.path,
    this.modifiedTime,
    this.size,
  });

  /// 格式化文件大小
  String get formattedSize {
    if (size == null) return '未知';
    final kb = size! / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// 格式化修改时间
  String get formattedTime {
    if (modifiedTime == null) return '未知';
    return '${modifiedTime!.year}-${modifiedTime!.month.toString().padLeft(2, '0')}-${modifiedTime!.day.toString().padLeft(2, '0')} '
        '${modifiedTime!.hour.toString().padLeft(2, '0')}:${modifiedTime!.minute.toString().padLeft(2, '0')}';
  }
}

/// WebDAV 服务
/// 提供备份到 WebDAV 服务器和从服务器恢复的功能
class WebDavService {
  /// 创建 WebDAV 客户端
  static webdav.Client _createClient(WebDavConfig config) {
    return webdav.newClient(
      config.serverUrl,
      user: config.username,
      password: config.password,
      debug: kDebugMode,
    );
  }

  /// 测试 WebDAV 连接
  static Future<bool> testConnection(WebDavConfig config) async {
    try {
      if (!config.isValid) {
        debugPrint('WebDAV 配置无效');
        return false;
      }

      final client = _createClient(config);

      // 尝试列出根目录
      await client.readDir('/');

      debugPrint('WebDAV 连接测试成功');
      return true;
    } catch (e) {
      debugPrint('WebDAV 连接测试失败: $e');
      return false;
    }
  }

  /// 确保备份目录存在
  static Future<void> _ensureBackupDirExists(
    webdav.Client client,
    String backupPath,
  ) async {
    try {
      // 检查目录是否存在
      await client.readDir(backupPath);
      debugPrint('备份目录已存在: $backupPath');
    } catch (e) {
      // 目录不存在，创建它
      try {
        await client.mkdir(backupPath);
        debugPrint('创建备份目录: $backupPath');
      } catch (createError) {
        debugPrint('创建备份目录失败: $createError');
        rethrow;
      }
    }
  }

  /// 备份数据到 WebDAV
  /// 返回备份文件路径
  static Future<String> backupToWebDav() async {
    try {
      // 加载配置
      final config = await WebDavConfigService.loadConfig();

      if (!config.isValid) {
        throw Exception('WebDAV 配置无效，请先配置服务器信息');
      }

      if (!config.enabled) {
        throw Exception('WebDAV 备份未启用');
      }

      // 创建客户端
      final client = _createClient(config);

      // 确保备份目录存在
      await _ensureBackupDirExists(client, config.backupPath);

      // 导出所有数据
      final jsonString = await ExportService.exportAllData();
      final bytes = utf8.encode(jsonString);

      // 生成文件名（带时间戳）
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final fileName = 'curriculum_backup_$timestamp.json';
      final remotePath = '${config.backupPath}/$fileName';

      // 上传文件
      await client.write(remotePath, bytes);

      debugPrint('数据已备份到 WebDAV: $remotePath');
      return remotePath;
    } catch (e) {
      debugPrint('备份到 WebDAV 失败: $e');
      rethrow;
    }
  }

  /// 从 WebDAV 恢复数据
  /// [remotePath] 远程文件路径
  /// [merge] 是否合并数据（true=合并，false=覆盖）
  static Future<ImportResult> restoreFromWebDav(
    String remotePath, {
    bool merge = false,
  }) async {
    try {
      // 加载配置
      final config = await WebDavConfigService.loadConfig();

      if (!config.isValid) {
        throw Exception('WebDAV 配置无效，请先配置服务器信息');
      }

      // 创建客户端
      final client = _createClient(config);

      // 下载文件
      final bytes = await client.read(remotePath);

      if (bytes.isEmpty) {
        throw Exception('下载的文件为空');
      }

      // 解码 JSON
      final jsonString = utf8.decode(bytes);

      // 导入数据
      final result = await ExportService.importAllData(
        jsonString,
        merge: merge,
      );

      debugPrint('从 WebDAV 恢复数据成功');
      return result;
    } catch (e) {
      debugPrint('从 WebDAV 恢复数据失败: $e');
      rethrow;
    }
  }

  /// 列出 WebDAV 服务器上的备份文件
  static Future<List<WebDavBackupFile>> listBackupFiles() async {
    try {
      // 加载配置
      final config = await WebDavConfigService.loadConfig();

      if (!config.isValid) {
        throw Exception('WebDAV 配置无效，请先配置服务器信息');
      }

      // 创建客户端
      final client = _createClient(config);

      // 确保备份目录存在
      await _ensureBackupDirExists(client, config.backupPath);

      // 列出目录内容
      final files = await client.readDir(config.backupPath);

      // 过滤并转换为备份文件对象
      final backupFiles = <WebDavBackupFile>[];
      for (final file in files) {
        final name = file.name ?? '';
        // 只显示 .json 文件
        if (name.endsWith('.json') && name.startsWith('curriculum_backup_')) {
          backupFiles.add(WebDavBackupFile(
            name: name,
            path: file.path ?? '',
            modifiedTime: file.mTime,
            size: file.size,
          ));
        }
      }

      // 按修改时间降序排序（最新的在前）
      backupFiles.sort((a, b) {
        if (a.modifiedTime == null && b.modifiedTime == null) return 0;
        if (a.modifiedTime == null) return 1;
        if (b.modifiedTime == null) return -1;
        return b.modifiedTime!.compareTo(a.modifiedTime!);
      });

      debugPrint('找到 ${backupFiles.length} 个备份文件');
      return backupFiles;
    } catch (e) {
      debugPrint('列出备份文件失败: $e');
      rethrow;
    }
  }

  /// 删除 WebDAV 服务器上的备份文件
  static Future<void> deleteBackupFile(String remotePath) async {
    try {
      // 加载配置
      final config = await WebDavConfigService.loadConfig();

      if (!config.isValid) {
        throw Exception('WebDAV 配置无效，请先配置服务器信息');
      }

      // 创建客户端
      final client = _createClient(config);

      // 删除文件
      await client.remove(remotePath);

      debugPrint('已删除备份文件: $remotePath');
    } catch (e) {
      debugPrint('删除备份文件失败: $e');
      rethrow;
    }
  }

  /// 获取备份文件内容预览（不导入）
  static Future<String> previewBackupFile(String remotePath) async {
    try {
      // 加载配置
      final config = await WebDavConfigService.loadConfig();

      if (!config.isValid) {
        throw Exception('WebDAV 配置无效，请先配置服务器信息');
      }

      // 创建客户端
      final client = _createClient(config);

      // 下载文件
      final bytes = await client.read(remotePath);

      if (bytes.isEmpty) {
        throw Exception('文件为空');
      }

      // 解码 JSON
      final jsonString = utf8.decode(bytes);

      // 解析以获取统计信息
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = jsonData['data'] as Map<String, dynamic>;

      final coursesCount = (data['courses'] as List?)?.length ?? 0;
      final semestersCount = (data['semesters'] as List?)?.length ?? 0;
      final timeTablesCount = (data['timeTables'] as List?)?.length ?? 0;

      return '包含: $coursesCount 门课程, $semestersCount 个学期, $timeTablesCount 个时间表';
    } catch (e) {
      debugPrint('预览备份文件失败: $e');
      return '无法预览文件内容';
    }
  }
}
