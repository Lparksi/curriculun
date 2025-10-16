import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/time_table.dart';
import '../services/share_service.dart';

/// 课程表分享对话框
/// 提供课程表预览和分享功能
class CourseTableShareDialog extends StatefulWidget {
  const CourseTableShareDialog({
    super.key,
    required this.courses,
    required this.timeTable,
    required this.currentWeek,
    required this.weekStartDate,
    required this.showWeekend,
    this.semesterName,
  });

  final List<Course> courses;
  final TimeTable timeTable;
  final int currentWeek;
  final DateTime weekStartDate;
  final bool showWeekend;
  final String? semesterName;

  /// 显示分享对话框
  static Future<void> show(
    BuildContext context, {
    required List<Course> courses,
    required TimeTable timeTable,
    required int currentWeek,
    required DateTime weekStartDate,
    required bool showWeekend,
    String? semesterName,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (context) => CourseTableShareDialog(
        courses: courses,
        timeTable: timeTable,
        currentWeek: currentWeek,
        weekStartDate: weekStartDate,
        showWeekend: showWeekend,
        semesterName: semesterName,
      ),
    );
  }

  @override
  State<CourseTableShareDialog> createState() => _CourseTableShareDialogState();
}

class _CourseTableShareDialogState extends State<CourseTableShareDialog> {
  final GlobalKey _captureKey = GlobalKey();
  bool _isSharing = false;

  List<Course> get _currentWeekCourses {
    return widget.courses.where((course) {
      return widget.currentWeek >= course.startWeek &&
          widget.currentWeek <= course.endWeek;
    }).toList();
  }

  int get _visibleDayCount => widget.showWeekend ? 7 : 5;

  List<int> get _visibleWeekdays =>
      List<int>.generate(_visibleDayCount, (index) => index + 1);

  List<Course> get _visibleCourses {
    return widget.showWeekend
        ? _currentWeekCourses
        : _currentWeekCourses.where((course) => course.weekday <= 5).toList();
  }

  /// 分享或下载课程表
  Future<void> _shareCourseTable() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // 等待一帧以确保 UI 已渲染
      await Future.delayed(const Duration(milliseconds: 100));

      final success = await ShareService.shareCourseTable(
        _captureKey,
        shareText: '我的课程表 - 第${widget.currentWeek}周',
        subject: '课程表分享',
        fileName: 'course_table_week_${widget.currentWeek}.png',
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(kIsWeb ? '下载成功!' : '分享成功!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(kIsWeb ? '下载失败,请重试' : '分享失败,请重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  /// 保存课程表为图片
  Future<void> _saveCourseTable() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // 等待一帧以确保 UI 已渲染
      await Future.delayed(const Duration(milliseconds: 100));

      final filePath = await ShareService.saveCourseTableToGallery(
        _captureKey,
        fileName: 'course_table_week_${widget.currentWeek}.png',
      );

      if (!mounted) return;

      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已保存到:\n$filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败,请重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 对话框标题
            _buildDialogHeader(),
            // 预览区域(可滚动)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildCourseTablePreview(),
              ),
            ),
            // 操作按钮
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 构建对话框标题
  Widget _buildDialogHeader() {
    // Web 端显示"下载课程表",移动端显示"分享课程表"
    final title = kIsWeb ? '下载课程表' : '分享课程表';
    final icon = kIsWeb ? Icons.download : Icons.share;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '第${widget.currentWeek}周',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  /// 构建课程表预览
  Widget _buildCourseTablePreview() {
    return RepaintBoundary(
      key: _captureKey,
      child: Container(
        // 限制宽度以避免布局溢出
        constraints: BoxConstraints(
          maxWidth: widget.showWeekend ? 550 : 450,
          minWidth: widget.showWeekend ? 500 : 400,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 课程表标题
            _buildTableHeader(),
            // 星期标题行
            _buildWeekdayHeader(),
            // 课程网格
            _buildCourseGrid(),
          ],
        ),
      ),
    );
  }

  /// 构建课程表标题
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        children: [
          Text(
            widget.semesterName ?? '课程表',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '第${widget.currentWeek}周',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建星期标题行
  Widget _buildWeekdayHeader() {
    const weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // 左侧空白(对应时间列)
          const SizedBox(width: 50),
          // 星期标题
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _visibleWeekdays.map((weekday) {
                final date = widget.weekStartDate.add(Duration(days: weekday - 1));
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        weekdayNames[weekday - 1],
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.month}/${date.day}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建课程网格
  Widget _buildCourseGrid() {
    const cellHeight = 70.0;

    return SizedBox(
      height: widget.timeTable.sections.length * cellHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 动态计算每列宽度:总宽度减去时间列后平均分配
          final availableWidth = constraints.maxWidth - 50;
          final cellWidth = availableWidth / _visibleDayCount;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间列
              _buildTimeColumn(cellHeight),
              // 课程网格
              Expanded(
                child: Stack(
                  children: [
                    // 背景网格
                    Column(
                      children: List.generate(
                        widget.timeTable.sections.length,
                        (row) => Row(
                          children: _visibleWeekdays
                              .map(
                                (_) => Container(
                                  width: cellWidth,
                                  height: cellHeight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                      right: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    // 课程卡片
                    ..._visibleCourses.map(
                      (course) => _buildCourseCard(course, cellWidth, cellHeight),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建时间列
  Widget _buildTimeColumn(double cellHeight) {
    return Column(
      children: widget.timeTable.sections.map((section) {
        return Container(
          width: 50,
          height: cellHeight,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
              right: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${section.section}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                section.timeRange,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建单个课程卡片
  Widget _buildCourseCard(Course course, double cellWidth, double cellHeight) {
    final left = (course.weekday - 1) * cellWidth;
    final top = (course.startSection - 1) * cellHeight;
    final height = course.duration * cellHeight - 3;

    final isSmallCard = course.duration == 1;
    final nameFontSize = isSmallCard ? 9.0 : 11.0;
    final locationFontSize = isSmallCard ? 7.0 : 8.0;

    return Positioned(
      left: left + 1.5,
      top: top + 1.5,
      width: cellWidth - 3,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: course.color,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              course.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: nameFontSize,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
              maxLines: isSmallCard ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (course.location.isNotEmpty && !isSmallCard) ...[
              const SizedBox(height: 2),
              Text(
                '@${course.location}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: locationFontSize,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    // Web 端显示"下载",移动端显示"分享"
    final primaryButtonLabel = kIsWeb ? '下载' : '分享';
    final primaryButtonIcon = kIsWeb ? Icons.download : Icons.share;
    final primaryButtonLoadingLabel = kIsWeb ? '下载中...' : '分享中...';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Web 端隐藏"保存"按钮(下载即保存)
          if (!kIsWeb) ...[
            TextButton.icon(
              onPressed: _isSharing ? null : _saveCourseTable,
              icon: const Icon(Icons.save_alt),
              label: const Text('保存'),
            ),
            const SizedBox(width: 12),
          ],
          FilledButton.icon(
            onPressed: _isSharing ? null : _shareCourseTable,
            icon: _isSharing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(primaryButtonIcon),
            label: Text(_isSharing ? primaryButtonLoadingLabel : primaryButtonLabel),
          ),
        ],
      ),
    );
  }
}
