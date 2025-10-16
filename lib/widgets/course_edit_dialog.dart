import 'package:flutter/material.dart';
import '../models/course.dart';

/// 课程编辑对话框
class CourseEditDialog extends StatefulWidget {
  final Course? course; // 如果为null则是新增，否则是编辑
  final int? courseIndex; // 课程在列表中的索引
  final List<Course> allCourses; // 用于时间冲突检测
  final String? semesterId; // 学期ID（新增课程时使用）

  const CourseEditDialog({
    super.key,
    this.course,
    this.courseIndex,
    required this.allCourses,
    this.semesterId,
  });

  @override
  State<CourseEditDialog> createState() => _CourseEditDialogState();
}

class _CourseEditDialogState extends State<CourseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _teacherController;

  late int _weekday;
  late int _startSection;
  late int _duration;
  late int _startWeek;
  late int _endWeek;
  late Color _color;

  @override
  void initState() {
    super.initState();

    // 初始化表单数据
    final course = widget.course;
    _nameController = TextEditingController(text: course?.name ?? '');
    _locationController = TextEditingController(text: course?.location ?? '');
    _teacherController = TextEditingController(text: course?.teacher ?? '');

    _weekday = course?.weekday ?? 1;
    _startSection = course?.startSection ?? 1;
    _duration = course?.duration ?? 2;
    _startWeek = course?.startWeek ?? 1;
    _endWeek = course?.endWeek ?? 20;
    _color = course?.color ?? const Color(0xFFE91E63);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  /// 保存课程
  void _saveCourse() {
    if (_formKey.currentState!.validate()) {
      final course = Course(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        teacher: _teacherController.text.trim(),
        weekday: _weekday,
        startSection: _startSection,
        duration: _duration,
        color: _color,
        startWeek: _startWeek,
        endWeek: _endWeek,
        semesterId:
            widget.course?.semesterId ?? widget.semesterId, // 保持原学期ID或使用新的学期ID
      );

      Navigator.pop(context, course);
    }
  }

  /// 删除课程
  Future<void> _deleteCourse() async {
    final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
    final weekdayText = '星期${weekdayNames[_weekday - 1]}';
    final timeText = '第$_startSection-${_startSection + _duration - 1}节';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除以下课程吗？\n\n'
          '课程名称：${_nameController.text}\n'
          '上课时间：$weekdayText $timeText\n'
          '上课地点：${_locationController.text}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // 返回特殊标记表示删除
      Navigator.pop(context, 'DELETE');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.course != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? '编辑课程' : '新增课程',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // 表单内容
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 课程名称
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '课程名称',
                        prefixIcon: Icon(Icons.book),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入课程名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 上课地点
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: '上课地点',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入上课地点';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 教师姓名
                    TextFormField(
                      controller: _teacherController,
                      decoration: const InputDecoration(
                        labelText: '教师姓名',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        hintText: '选填',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 星期选择
                    _buildDropdownField(
                      label: '星期',
                      icon: Icons.calendar_today,
                      value: _weekday,
                      items: List.generate(7, (index) {
                        final day = index + 1;
                        return DropdownMenuItem(
                          value: day,
                          child: Text('星期${'一二三四五六日'[index]}'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _weekday = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 开始节次和持续节数
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: '开始节次',
                            icon: Icons.access_time,
                            value: _startSection,
                            items: List.generate(10, (index) {
                              final section = index + 1;
                              return DropdownMenuItem(
                                value: section,
                                child: Text('第$section节'),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _startSection = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField(
                            label: '持续节数',
                            icon: Icons.timelapse,
                            value: _duration,
                            items: List.generate(5, (index) {
                              final dur = index + 1;
                              return DropdownMenuItem(
                                value: dur,
                                child: Text('$dur节'),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _duration = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 周次范围
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: '开始周次',
                            icon: Icons.event_note,
                            value: _startWeek,
                            items: List.generate(30, (index) {
                              final week = index + 1;
                              return DropdownMenuItem(
                                value: week,
                                child: Text('第$week周'),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _startWeek = value!;
                                if (_endWeek < _startWeek) {
                                  _endWeek = _startWeek;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField(
                            label: '结束周次',
                            icon: Icons.event_available,
                            value: _endWeek,
                            items: List.generate(30, (index) {
                              final week = index + 1;
                              return DropdownMenuItem(
                                value: week,
                                enabled: week >= _startWeek,
                                child: Text('第$week周'),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _endWeek = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 颜色选择
                    _buildColorPicker(),
                  ],
                ),
              ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
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
                  // 删除按钮（仅编辑模式显示）
                  if (isEditing) ...[
                    TextButton.icon(
                      onPressed: _deleteCourse,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('删除'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // 取消和保存按钮
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _saveCourse, child: const Text('保存')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建下拉选择字段
  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  /// 构建颜色选择器
  Widget _buildColorPicker() {
    // 可用颜色列表
    final availableColors = [
      const Color(0xFFE91E63), // 玫红
      const Color(0xFF00897B), // 青绿
      const Color(0xFFFF6F00), // 纯橙
      const Color(0xFF1976D2), // 宝蓝
      const Color(0xFF558B2F), // 橄榄绿
      const Color(0xFF8E24AA), // 紫罗兰
      const Color(0xFFD32F2F), // 纯红
      const Color(0xFF0097A7), // 水蓝
      const Color(0xFFF9A825), // 金黄
      const Color(0xFF5D4037), // 咖啡棕
      const Color(0xFF7B1FA2), // 深紫
      const Color(0xFF00695C), // 暗青
      const Color(0xFFFF5722), // 朱红
      const Color(0xFF0288D1), // 天蓝
      const Color(0xFF9C27B0), // 亮紫
      const Color(0xFF43A047), // 翠绿
      const Color(0xFFE64A19), // 橙红
      const Color(0xFFC2185B), // 深粉
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.palette, size: 20),
            const SizedBox(width: 8),
            Text('课程颜色', style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableColors.map((color) {
            final isSelected = _color.toARGB32() == color.toARGB32();
            return InkWell(
              onTap: () {
                setState(() {
                  _color = color;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
