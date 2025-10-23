import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/time_table.dart';
import '../services/time_table_service.dart';
import '../utils/performance_tracker.dart';

/// 课程详情弹窗
class CourseDetailDialog extends StatefulWidget {
  final Course course;

  const CourseDetailDialog({super.key, required this.course});

  /// 显示课程详情对话框
  static Future<void> show(BuildContext context, Course course) {
    return PerformanceTracker.instance.traceAsync(
      traceName: PerformanceTraces.openCourseDetail,
      operation: () => showDialog<void>(
        context: context,
        builder: (context) => CourseDetailDialog(course: course),
      ),
      attributes: {
        'course_name': course.name,
        'weekday': course.weekday.toString(),
        'duration': course.duration.toString(),
      },
    );
  }

  @override
  State<CourseDetailDialog> createState() => _CourseDetailDialogState();
}

class _CourseDetailDialogState extends State<CourseDetailDialog> {
  TimeTable? _timeTable;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeTable();
  }

  Future<void> _loadTimeTable() async {
    try {
      final timeTable = await TimeTableService.getActiveTimeTable();
      setState(() {
        _timeTable = timeTable;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceContainerColor = theme.useMaterial3
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surface;
    final weekdayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    // 如果还在加载时间表，显示加载指示器
    if (_isLoading) {
      return Dialog(
        backgroundColor: surfaceContainerColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // 计算时间段文本
    final timeRangeText = _timeTable != null
        ? widget.course.getTimeRangeText(_timeTable!)
        : '加载中...';

    return Dialog(
      backgroundColor: surfaceContainerColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: surfaceContainerColor,
          boxShadow: kElevationToShadow[3],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 内容区域
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 课程名称
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.course.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.course.name,
                          style:
                              theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ) ??
                              const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 详细信息列表
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: '教师',
                    value: widget.course.teacher.isNotEmpty
                        ? widget.course.teacher
                        : '未指定',
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    label: '地点',
                    value: widget.course.location.isNotEmpty
                        ? widget.course.location
                        : '未指定',
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: '时间',
                    value:
                        '${weekdayNames[widget.course.weekday]} ${widget.course.sectionRangeText}',
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    icon: Icons.access_time_outlined,
                    label: '时段',
                    value: timeRangeText,
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    icon: Icons.date_range_outlined,
                    label: '周次',
                    value: widget.course.weekRangeText,
                  ),

                  const SizedBox(height: 24),

                  // 关闭按钮
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.course.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '关闭',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  /// 构建信息行
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
