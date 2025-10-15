import 'package:flutter/material.dart';
import '../models/course.dart';

/// 课程详情弹窗
class CourseDetailDialog extends StatelessWidget {
  final Course course;

  const CourseDetailDialog({
    super.key,
    required this.course,
  });

  /// 显示课程详情对话框
  static void show(BuildContext context, Course course) {
    showDialog(
      context: context,
      builder: (context) => CourseDetailDialog(course: course),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekdayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
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
                          color: course.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          course.name,
                          style: const TextStyle(
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
                    value: course.teacher.isNotEmpty ? course.teacher : '未指定',
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    label: '地点',
                    value: course.location.isNotEmpty ? course.location : '未指定',
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: '时间',
                    value: '${weekdayNames[course.weekday]} ${course.sectionRangeText}',
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    icon: Icons.access_time_outlined,
                    label: '时段',
                    value: course.timeRangeText,
                  ),

                  const SizedBox(height: 16),

                  _buildInfoRow(
                    icon: Icons.date_range_outlined,
                    label: '周次',
                    value: course.weekRangeText,
                  ),

                  const SizedBox(height: 24),

                  // 关闭按钮
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: course.color,
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
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
