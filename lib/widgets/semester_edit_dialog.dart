import 'package:flutter/material.dart';
import '../models/semester_settings.dart';
import '../services/settings_service.dart';

/// 学期编辑对话框
/// 用于创建新学期或编辑现有学期
class SemesterEditDialog extends StatefulWidget {
  final SemesterSettings? semester; // 如果为null，表示创建新学期

  const SemesterEditDialog({super.key, this.semester});

  @override
  State<SemesterEditDialog> createState() => _SemesterEditDialogState();
}

class _SemesterEditDialogState extends State<SemesterEditDialog> {
  late TextEditingController _nameController;
  late DateTime _startDate;
  late int _totalWeeks;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.semester != null) {
      // 编辑模式：使用现有数据
      _nameController = TextEditingController(text: widget.semester!.name);
      _startDate = widget.semester!.startDate;
      _totalWeeks = widget.semester!.totalWeeks;
    } else {
      // 创建模式：使用默认值
      _nameController = TextEditingController();
      _startDate = DateTime.now();
      _totalWeeks = 20;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 选择开始日期
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  /// 保存学期
  Future<void> _save() async {
    final name = _nameController.text.trim();

    // 验证输入
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入学期名称')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      if (widget.semester != null) {
        // 更新现有学期
        final updatedSemester = widget.semester!.copyWith(
          name: name,
          startDate: _startDate,
          totalWeeks: _totalWeeks,
          updatedAt: now,
        );
        await SettingsService.updateSemester(updatedSemester);
      } else {
        // 创建新学期
        final newSemester = SemesterSettings(
          id: SettingsService.generateSemesterId(),
          name: name,
          startDate: _startDate,
          totalWeeks: _totalWeeks,
          createdAt: now,
          updatedAt: now,
        );
        await SettingsService.addSemester(newSemester);
      }

      if (!mounted) return;

      Navigator.of(context).pop(true); // 返回true表示成功保存
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final endDate = _startDate.add(Duration(days: _totalWeeks * 7));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.semester != null ? '编辑学期' : '新建学期'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学期名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '学期名称',
                hintText: '例如：2025春季学期、大三上学期',
                border: OutlineInputBorder(),
              ),
              autofocus: widget.semester == null,
            ),

            const SizedBox(height: 24),

            // 学期开始日期
            InkWell(
              onTap: _selectStartDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '学期开始日期',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_startDate.year}年${_startDate.month}月${_startDate.day}日',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 学期总周数
            Text(
              '学期总周数',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 32,
                  onPressed: _totalWeeks > 1
                      ? () {
                          setState(() {
                            _totalWeeks--;
                          });
                        }
                      : null,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$_totalWeeks 周',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _totalWeeks.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: '$_totalWeeks 周',
                        onChanged: (value) {
                          setState(() {
                            _totalWeeks = value.round();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 32,
                  onPressed: _totalWeeks < 30
                      ? () {
                          setState(() {
                            _totalWeeks++;
                          });
                        }
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 学期结束日期提示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '学期结束日期',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${endDate.year}年${endDate.month}月${endDate.day}日',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
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
                  onPressed: _isLoading ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
