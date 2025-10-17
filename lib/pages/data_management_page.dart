import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/export_service.dart';
import '../utils/web_file_utils.dart';

/// 数据管理页面
/// 提供数据导出和导入功能
class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 导出部分
          _buildSectionTitle('导出数据'),
          const SizedBox(height: 8),
          _buildExportCard(
            title: '导出所有数据',
            subtitle: '包括课程、学期设置和时间表',
            icon: Icons.cloud_download,
            onTap: _exportAllData,
          ),
          const SizedBox(height: 8),
          _buildExportCard(
            title: '仅导出课程',
            subtitle: '仅导出课程数据',
            icon: Icons.school,
            onTap: _exportCourses,
          ),
          const SizedBox(height: 8),
          _buildExportCard(
            title: '仅导出学期设置',
            subtitle: '仅导出学期配置',
            icon: Icons.calendar_today,
            onTap: _exportSemesters,
          ),
          const SizedBox(height: 8),
          _buildExportCard(
            title: '仅导出时间表',
            subtitle: '仅导出时间表配置',
            icon: Icons.access_time,
            onTap: _exportTimeTables,
          ),

          const SizedBox(height: 32),

          // 导入部分
          _buildSectionTitle('导入数据'),
          const SizedBox(height: 8),
          _buildImportCard(
            title: '导入数据（覆盖）',
            subtitle: '替换现有数据',
            icon: Icons.cloud_upload,
            color: Colors.orange,
            onTap: () => _importData(merge: false),
          ),
          const SizedBox(height: 8),
          _buildImportCard(
            title: '导入数据（合并）',
            subtitle: '与现有数据合并',
            icon: Icons.merge_type,
            color: Colors.blue,
            onTap: () => _importData(merge: true),
          ),

          const SizedBox(height: 32),

          // 说明文字
          _buildInfoCard(),
        ],
      ),
    );
  }

  /// 构建节标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建导出卡片
  Widget _buildExportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _isLoading ? null : onTap,
      ),
    );
  }

  /// 构建导入卡片
  Widget _buildImportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _isLoading ? null : onTap,
      ),
    );
  }

  /// 构建信息卡片
  Widget _buildInfoCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.primaryContainer.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '使用说明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              kIsWeb
                  ? '• Web 端：导出将下载 JSON 文件到本地'
                  : '• 移动端：导出将生成 JSON 文件并打开分享',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              kIsWeb
                  ? '• Web 端：导入需上传 JSON 配置文件'
                  : '• 移动端：导入需选择本地 JSON 文件',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '• 覆盖模式会替换所有现有数据',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '• 合并模式会保留现有数据并添加新数据',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '• 建议定期备份数据',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  /// 导出所有数据
  Future<void> _exportAllData() async {
    setState(() => _isLoading = true);

    try {
      final jsonString = await ExportService.exportAllData();
      await _saveAndShareFile(jsonString, 'curriculum_all_data');

      if (mounted) {
        _showSuccessSnackBar('所有数据导出成功');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('导出失败: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 导出课程
  Future<void> _exportCourses() async {
    setState(() => _isLoading = true);

    try {
      final jsonString = await ExportService.exportCourses();
      await _saveAndShareFile(jsonString, 'curriculum_courses');

      if (mounted) {
        _showSuccessSnackBar('课程数据导出成功');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('导出失败: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 导出学期设置
  Future<void> _exportSemesters() async {
    setState(() => _isLoading = true);

    try {
      final jsonString = await ExportService.exportSemesters();
      await _saveAndShareFile(jsonString, 'curriculum_semesters');

      if (mounted) {
        _showSuccessSnackBar('学期设置导出成功');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('导出失败: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 导出时间表
  Future<void> _exportTimeTables() async {
    setState(() => _isLoading = true);

    try {
      final jsonString = await ExportService.exportTimeTables();
      await _saveAndShareFile(jsonString, 'curriculum_timetables');

      if (mounted) {
        _showSuccessSnackBar('时间表导出成功');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('导出失败: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 保存并分享文件
  Future<void> _saveAndShareFile(String content, String fileNamePrefix) async {
    try {
      // 生成文件名（带时间戳）
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final fileName = '${fileNamePrefix}_$timestamp.json';

      if (kIsWeb) {
        // Web 平台：触发浏览器下载
        WebFileUtils.downloadFile(content, fileName);
      } else {
        // 移动/桌面平台：先保存为临时文件，然后分享文件
        final directory = await Directory.systemTemp.createTemp('curriculum_export_');
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsString(content);

        // 使用 XFile 分享文件
        final xFile = XFile(filePath);
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            subject: '课程表数据导出',
          ),
        );

        // 清理临时文件（延迟清理以确保分享完成）
        Future.delayed(const Duration(seconds: 5), () {
          try {
            directory.deleteSync(recursive: true);
          } catch (e) {
            debugPrint('清理临时文件失败: $e');
          }
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 导入数据
  Future<void> _importData({required bool merge}) async {
    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: kIsWeb, // Web 平台需要读取字节数据
      );

      if (result == null || result.files.isEmpty) {
        return; // 用户取消选择
      }

      setState(() => _isLoading = true);

      // 读取文件内容
      String jsonString;
      if (kIsWeb) {
        // Web 平台：从字节数组读取
        final bytes = result.files.single.bytes;
        if (bytes == null) {
          throw Exception('无法读取文件内容');
        }
        jsonString = WebFileUtils.readFileAsString(bytes);
      } else {
        // 移动/桌面平台：从文件路径读取
        final path = result.files.single.path;
        if (path == null) {
          throw Exception('无法获取文件路径');
        }
        final file = File(path);
        jsonString = await file.readAsString();
      }

      // 导入数据
      final importResult = await ExportService.importAllData(
        jsonString,
        merge: merge,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (importResult.success) {
        _showSuccessDialog(importResult);
      } else {
        _showErrorSnackBar(importResult.error ?? '导入失败');
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        _showErrorSnackBar('导入失败: $e');
      }
    }
  }

  /// 显示成功对话框
  void _showSuccessDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('导入成功'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.getSummary()),
            const SizedBox(height: 16),
            const Text(
              '请重启应用以查看导入的数据',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 返回主页
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
