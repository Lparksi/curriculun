import 'package:flutter/material.dart';
import '../models/time_table.dart';
import '../services/time_table_service.dart';
import '../widgets/time_table_edit_dialog.dart';

/// 时间表管理页面
class TimeTableManagementPage extends StatefulWidget {
  const TimeTableManagementPage({super.key});

  @override
  State<TimeTableManagementPage> createState() =>
      _TimeTableManagementPageState();
}

class _TimeTableManagementPageState extends State<TimeTableManagementPage> {
  List<TimeTable> _timeTables = [];
  String? _activeTimeTableId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final timeTables = await TimeTableService.loadTimeTables();
      final activeId = await TimeTableService.getActiveTimeTableId();

      setState(() {
        _timeTables = timeTables;
        _activeTimeTableId = activeId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载失败: $e')));
      }
    }
  }

  /// 新建时间表
  Future<void> _createTimeTable() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TimeTableEditDialog(),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('创建成功')));
      }
    }
  }

  /// 编辑时间表
  Future<void> _editTimeTable(TimeTable timeTable) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TimeTableEditDialog(timeTable: timeTable),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存成功')));
      }
    }
  }

  /// 删除时间表
  Future<void> _deleteTimeTable(TimeTable timeTable) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除时间表'),
        content: Text('确定要删除时间表 "${timeTable.name}" 吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await TimeTableService.deleteTimeTable(timeTable.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  /// 复制时间表
  Future<void> _duplicateTimeTable(TimeTable timeTable) async {
    try {
      await TimeTableService.duplicateTimeTable(timeTable.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('复制成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('复制失败: $e')));
      }
    }
  }

  /// 切换激活的时间表
  Future<void> _switchTimeTable(String id) async {
    try {
      await TimeTableService.setActiveTimeTableId(id);
      setState(() => _activeTimeTableId = id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('切换成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('切换失败: $e')));
      }
    }
  }

  /// 构建时间表卡片
  Widget _buildTimeTableCard(TimeTable timeTable) {
    final isActive = timeTable.id == _activeTimeTableId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isActive ? 4 : 1,
      child: InkWell(
        onTap: () => _editTimeTable(timeTable),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  // 激活标识
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
                        '当前使用',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isActive) const SizedBox(width: 12),

                  // 时间表名称
                  Expanded(
                    child: Text(
                      timeTable.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ),

                  // 操作按钮
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'use':
                          _switchTimeTable(timeTable.id);
                          break;
                        case 'duplicate':
                          _duplicateTimeTable(timeTable);
                          break;
                        case 'delete':
                          _deleteTimeTable(timeTable);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isActive)
                        const PopupMenuItem(
                          value: 'use',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text('使用此时间表'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 20),
                            SizedBox(width: 8),
                            Text('复制'),
                          ],
                        ),
                      ),
                      if (timeTable.id != 'default')
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
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 时间信息预览
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.schedule,
                    '${timeTable.sections.length}节课',
                  ),
                  _buildInfoChip(
                    Icons.update,
                    _formatDateTime(timeTable.updatedAt),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 部分节次时间预览 (前3节)
              ...timeTable.sections.take(3).map((section) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '第${section.section}节: ${section.startTime} - ${section.endTime}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }),
              if (timeTable.sections.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... 还有${timeTable.sections.length - 3}节',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建信息芯片
  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('时间表管理'),
        actions: [
          // 当前使用的时间表切换器
          if (!_isLoading && _timeTables.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.schedule),
              tooltip: '切换时间表',
              onSelected: (value) => _switchTimeTable(value),
              itemBuilder: (context) {
                return _timeTables.map((timeTable) {
                  final isActive = timeTable.id == _activeTimeTableId;
                  return PopupMenuItem<String>(
                    value: timeTable.id,
                    child: Row(
                      children: [
                        Icon(
                          isActive
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            timeTable.name,
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '使用中',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timeTables.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无时间表',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _timeTables.length,
              itemBuilder: (context, index) =>
                  _buildTimeTableCard(_timeTables[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTimeTable,
        child: const Icon(Icons.add),
      ),
    );
  }
}
