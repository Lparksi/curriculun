import 'package:flutter/material.dart';
import '../models/semester_settings.dart';
import '../services/settings_service.dart';
import '../widgets/semester_edit_dialog.dart';

/// 学期管理页面
/// 支持查看、创建、编辑、删除、切换学期
class SemesterManagementPage extends StatefulWidget {
  const SemesterManagementPage({super.key});

  @override
  State<SemesterManagementPage> createState() => _SemesterManagementPageState();
}

class _SemesterManagementPageState extends State<SemesterManagementPage> {
  List<SemesterSettings> _semesters = [];
  String? _activeSemesterId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  /// 加载学期列表
  Future<void> _loadSemesters() async {
    setState(() {
      _isLoading = true;
    });

    final results = await Future.wait([
      SettingsService.getAllSemesters(),
      SettingsService.getActiveSemesterId(),
    ]);

    setState(() {
      _semesters = results[0] as List<SemesterSettings>;
      _activeSemesterId = results[1] as String?;
      _isLoading = false;
    });
  }

  /// 切换激活的学期
  Future<void> _switchSemester(String semesterId) async {
    await SettingsService.setActiveSemesterId(semesterId);
    setState(() {
      _activeSemesterId = semesterId;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已切换学期'), duration: Duration(seconds: 2)),
    );

    // 通知父页面学期已切换
    Navigator.of(context).pop(true);
  }

  /// 显示新建/编辑学期对话框
  Future<void> _showEditDialog([SemesterSettings? semester]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SemesterEditDialog(semester: semester),
    );

    if (result == true) {
      await _loadSemesters();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(semester != null ? '学期已更新' : '学期已创建'),
          duration: const Duration(seconds: 2),
        ),
      );

      // 如果是编辑当前激活的学期，通知父页面需要刷新
      if (semester != null && semester.id == _activeSemesterId) {
        // 延迟通知，确保 SnackBar 能够显示
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
    }
  }

  /// 删除学期
  Future<void> _deleteSemester(SemesterSettings semester) async {
    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除学期'),
        content: Text('确定要删除学期"${semester.name}"吗？\n\n该学期下的所有课程也将无法访问。'),
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

    final success = await SettingsService.deleteSemester(semester.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('学期已删除')));
      await _loadSemesters();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法删除唯一的学期')));
    }
  }

  /// 复制学期
  Future<void> _duplicateSemester(SemesterSettings semester) async {
    try {
      await SettingsService.duplicateSemester(semester.id);
      await _loadSemesters();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('学期已复制')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('复制失败: $e')));
    }
  }

  /// 显示帮助信息对话框
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('学期管理说明'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• 点击学期卡片可切换当前激活的学期',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
              SizedBox(height: 8),
              Text(
                '• 每个学期可以有独立的课程安排',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
              SizedBox(height: 8),
              Text(
                '• 复制学期会保留学期设置，但不会复制课程',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 构建学期卡片
  Widget _buildSemesterCard(SemesterSettings semester) {
    final isActive = semester.id == _activeSemesterId;

    return Card(
      elevation: isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isActive ? null : () => _switchSemester(semester.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Expanded(
                    child: Text(
                      semester.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '当前学期',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // 学期信息
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      semester.dateRangeText,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.event_note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '共 ${semester.totalWeeks} 周',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _duplicateSemester(semester),
                    tooltip: '复制学期',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditDialog(semester),
                    tooltip: '编辑学期',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: _semesters.length > 1
                        ? () => _deleteSemester(semester)
                        : null,
                    tooltip: '删除学期',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学期管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: '使用说明',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 学期列表
                if (_semesters.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('暂无学期，点击右下角添加按钮创建学期'),
                    ),
                  )
                else
                  ..._semesters.map(_buildSemesterCard),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('新建学期'),
      ),
    );
  }
}
