import 'package:flutter/material.dart';
import '../models/time_table.dart';
import '../services/time_table_service.dart';

/// 时间表编辑对话框
class TimeTableEditDialog extends StatefulWidget {
  final TimeTable? timeTable; // null 表示新建,非 null 表示编辑

  const TimeTableEditDialog({super.key, this.timeTable});

  @override
  State<TimeTableEditDialog> createState() => _TimeTableEditDialogState();
}

class _TimeTableEditDialogState extends State<TimeTableEditDialog> {
  late TextEditingController _nameController;
  late List<SectionTime> _sections;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.timeTable != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.timeTable?.name ?? '');

    // 初始化节次列表
    if (widget.timeTable != null) {
      _sections = List.from(widget.timeTable!.sections);
    } else {
      // 新建时默认 10 节课
      _sections = TimeTable.defaultTimeTable().sections.toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 保存时间表
  Future<void> _saveTimeTable() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 验证所有节次时间
    for (final section in _sections) {
      if (!TimeTableService.isTimeRangeValid(
        section.startTime,
        section.endTime,
      )) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('第${section.section}节的时间设置无效')));
        return;
      }
    }

    try {
      final now = DateTime.now();
      final timeTable = TimeTable(
        id: widget.timeTable?.id ?? TimeTableService.generateTimeTableId(),
        name: _nameController.text.trim(),
        sections: _sections,
        createdAt: widget.timeTable?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditing) {
        await TimeTableService.updateTimeTable(timeTable);
      } else {
        await TimeTableService.addTimeTable(timeTable);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // 返回 true 表示保存成功
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  /// 显示时间选择器
  Future<void> _selectTime(
    BuildContext context,
    int index,
    bool isStartTime,
  ) async {
    final section = _sections[index];
    final currentTime = isStartTime ? section.startTime : section.endTime;

    // 解析当前时间
    final timeParts = currentTime.split(':');
    final initialHour = int.tryParse(timeParts[0]) ?? 8;
    final initialMinute = int.tryParse(timeParts[1]) ?? 0;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      setState(() {
        if (isStartTime) {
          _sections[index] = section.copyWith(startTime: timeString);
        } else {
          _sections[index] = section.copyWith(endTime: timeString);
        }
      });
    }
  }

  /// 添加新节次
  void _addSection() {
    setState(() {
      final newSectionNumber = _sections.length + 1;
      // 使用上一节的结束时间作为新节次的开始时间参考
      final lastSection = _sections.isNotEmpty ? _sections.last : null;
      final defaultStartTime = lastSection?.endTime ?? '08:00';

      _sections.add(
        SectionTime(
          section: newSectionNumber,
          startTime: defaultStartTime,
          endTime: _calculateEndTime(defaultStartTime, 45), // 默认45分钟
        ),
      );
    });
  }

  /// 删除节次
  void _removeSection(int index) {
    if (_sections.length <= 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('至少需要保留一个节次')));
      return;
    }

    setState(() {
      _sections.removeAt(index);
      // 重新编号
      for (int i = 0; i < _sections.length; i++) {
        _sections[i] = _sections[i].copyWith(section: i + 1);
      }
    });
  }

  /// 计算结束时间 (给定开始时间和持续分钟数)
  String _calculateEndTime(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    final startHour = int.tryParse(parts[0]) ?? 8;
    final startMinute = int.tryParse(parts[1]) ?? 0;

    final totalMinutes = startHour * 60 + startMinute + durationMinutes;
    final endHour = (totalMinutes ~/ 60) % 24;
    final endMinute = totalMinutes % 60;

    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  /// 构建节次编辑项
  Widget _buildSectionItem(int index) {
    final section = _sections[index];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 节次编号
            SizedBox(
              width: 50,
              child: Text(
                '第${section.section}节',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 开始时间
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(context, index, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '开始',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    suffixIcon: Icon(Icons.access_time, size: 18),
                  ),
                  child: Text(
                    section.startTime,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 结束时间
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(context, index, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '结束',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    suffixIcon: Icon(Icons.access_time, size: 18),
                  ),
                  child: Text(
                    section.endTime,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 删除按钮
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Theme.of(context).colorScheme.error,
              tooltip: '删除节次',
              onPressed: () => _removeSection(index),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑时间表' : '新建时间表'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 添加节次按钮
          TextButton.icon(
            onPressed: _addSection,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加节次'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 表单
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间表名称
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '时间表名称',
                      hintText: '请输入时间表名称',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入时间表名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 说明文字
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '共 ${_sections.length} 节课 · 点击时间字段打开时间选择器 (24小时制)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 节次列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sections.length,
              itemBuilder: (context, index) => _buildSectionItem(index),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 取消按钮
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              // 保存按钮
              Expanded(
                child: FilledButton(
                  onPressed: _saveTimeTable,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
