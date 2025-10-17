import 'package:flutter/material.dart';
import '../models/webdav_config.dart';
import '../services/export_service.dart';
import '../services/webdav_config_service.dart';
import '../services/webdav_service.dart';

/// WebDAV 备份管理页面
/// 提供 WebDAV 配置、备份、恢复功能
class WebDavBackupPage extends StatefulWidget {
  const WebDavBackupPage({super.key});

  @override
  State<WebDavBackupPage> createState() => _WebDavBackupPageState();
}

class _WebDavBackupPageState extends State<WebDavBackupPage> {
  WebDavConfig _config = WebDavConfig.defaultConfig();
  List<WebDavBackupFile> _backupFiles = [];
  bool _isLoading = false;
  bool _isLoadingFiles = false;
  bool _obscurePassword = true;

  // 表单控制器
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _backupPathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _backupPathController.dispose();
    super.dispose();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    try {
      final config = await WebDavConfigService.loadConfig();
      setState(() {
        _config = config;
        _serverUrlController.text = config.serverUrl;
        _usernameController.text = config.username;
        _passwordController.text = config.password;
        _backupPathController.text = config.backupPath;
      });

      // 如果配置有效，自动加载备份文件列表
      if (config.isValid) {
        await _loadBackupFiles();
      }
    } catch (e) {
      _showErrorSnackBar('加载配置失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);

    try {
      final newConfig = WebDavConfig(
        serverUrl: _serverUrlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        backupPath: _backupPathController.text.trim(),
        enabled: _config.enabled,
      );

      // 验证配置
      if (!newConfig.isValid) {
        _showErrorSnackBar('请填写完整的配置信息');
        return;
      }

      // 测试连接
      final connectionOk = await WebDavService.testConnection(newConfig);
      if (!connectionOk) {
        _showErrorSnackBar('连接失败，请检查配置');
        return;
      }

      // 保存配置
      await WebDavConfigService.saveConfig(newConfig);

      setState(() => _config = newConfig);

      if (mounted) {
        _showSuccessSnackBar('配置保存成功');
        // 加载备份文件列表
        await _loadBackupFiles();
      }
    } catch (e) {
      _showErrorSnackBar('保存配置失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 测试连接
  Future<void> _testConnection() async {
    setState(() => _isLoading = true);

    try {
      final testConfig = WebDavConfig(
        serverUrl: _serverUrlController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        backupPath: _backupPathController.text.trim(),
        enabled: false,
      );

      if (!testConfig.isValid) {
        _showErrorSnackBar('请填写完整的配置信息');
        return;
      }

      final success = await WebDavService.testConnection(testConfig);

      if (mounted) {
        if (success) {
          _showSuccessSnackBar('连接测试成功！');
        } else {
          _showErrorSnackBar('连接失败，请检查配置');
        }
      }
    } catch (e) {
      _showErrorSnackBar('连接测试失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 加载备份文件列表
  Future<void> _loadBackupFiles() async {
    setState(() => _isLoadingFiles = true);

    try {
      final files = await WebDavService.listBackupFiles();
      setState(() => _backupFiles = files);
    } catch (e) {
      _showErrorSnackBar('加载备份文件列表失败: $e');
    } finally {
      setState(() => _isLoadingFiles = false);
    }
  }

  /// 执行备份
  Future<void> _performBackup() async {
    setState(() => _isLoading = true);

    try {
      await WebDavService.backupToWebDav();

      if (mounted) {
        _showSuccessSnackBar('备份成功！');
        // 重新加载备份文件列表
        await _loadBackupFiles();
      }
    } catch (e) {
      _showErrorSnackBar('备份失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 恢复备份
  Future<void> _restoreBackup(WebDavBackupFile file, bool merge) async {
    setState(() => _isLoading = true);

    try {
      final result = await WebDavService.restoreFromWebDav(
        file.path,
        merge: merge,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result.success) {
        _showRestoreSuccessDialog(result);
      } else {
        _showErrorSnackBar(result.error ?? '恢复失败');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('恢复失败: $e');
    }
  }

  /// 删除备份文件
  Future<void> _deleteBackupFile(WebDavBackupFile file) async {
    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除备份文件 "${file.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await WebDavService.deleteBackupFile(file.path);

      if (mounted) {
        _showSuccessSnackBar('删除成功');
        // 重新加载备份文件列表
        await _loadBackupFiles();
      }
    } catch (e) {
      _showErrorSnackBar('删除失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV 备份'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 配置部分
                _buildSectionTitle('服务器配置'),
                _buildConfigSection(),

                const SizedBox(height: 32),

                // 备份操作部分
                if (_config.isValid) ...[
                  _buildSectionTitle('备份操作'),
                  _buildBackupSection(),

                  const SizedBox(height: 32),

                  // 备份文件列表
                  _buildSectionTitle('备份历史'),
                  _buildBackupListSection(),
                ],

                const SizedBox(height: 32),

                // 说明信息
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

  /// 构建配置部分
  Widget _buildConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: '服务器地址 *',
                hintText: 'https://dav.example.com',
                prefixIcon: Icon(Icons.cloud),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名 *',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '密码 *',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _backupPathController,
              decoration: const InputDecoration(
                labelText: '备份目录',
                hintText: '/curriculum_backup',
                prefixIcon: Icon(Icons.folder),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testConnection,
                    icon: const Icon(Icons.network_check),
                    label: const Text('测试连接'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('保存配置'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建备份操作部分
  Widget _buildBackupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _performBackup,
              icon: const Icon(Icons.backup),
              label: const Text('立即备份'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '将当前所有数据备份到 WebDAV 服务器',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建备份文件列表部分
  Widget _buildBackupListSection() {
    if (_isLoadingFiles) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_backupFiles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                '暂无备份文件',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadBackupFiles,
                child: const Text('刷新'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '共 ${_backupFiles.length} 个备份',
                  style: const TextStyle(color: Colors.grey),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadBackupFiles,
                  tooltip: '刷新',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _backupFiles.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final file = _backupFiles[index];
              return ListTile(
                leading: const Icon(Icons.cloud_done, color: Colors.green),
                title: Text(
                  file.name,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '${file.formattedTime} • ${file.formattedSize}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'restore_replace',
                      child: Row(
                        children: [
                          Icon(Icons.restore, size: 20),
                          SizedBox(width: 8),
                          Text('恢复（覆盖）'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'restore_merge',
                      child: Row(
                        children: [
                          Icon(Icons.merge_type, size: 20),
                          SizedBox(width: 8),
                          Text('恢复（合并）'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'restore_replace':
                        _restoreBackup(file, false);
                        break;
                      case 'restore_merge':
                        _restoreBackup(file, true);
                        break;
                      case 'delete':
                        _deleteBackupFile(file);
                        break;
                    }
                  },
                ),
              );
            },
          ),
        ],
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
                Icon(Icons.info_outline, color: colorScheme.primary),
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
              '• WebDAV 是一种基于 HTTP 的文件传输协议',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '• 支持坚果云、NextCloud 等 WebDAV 服务',
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
              '• 建议定期备份数据以防丢失',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Web 平台限制',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '由于浏览器的 CORS 限制，Web 端可能无法连接某些 WebDAV 服务器（如坚果云）。',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '建议：',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1. 使用 Android 应用（无 CORS 限制）',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '2. 使用本地导出/导入功能',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '3. 使用支持 CORS 的 WebDAV 服务器',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示恢复成功对话框
  void _showRestoreSuccessDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('恢复成功'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.getSummary()),
            const SizedBox(height: 16),
            const Text(
              '请重启应用以查看恢复的数据',
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
              Navigator.of(context).pop(); // 返回上一页
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
