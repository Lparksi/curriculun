import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/course.dart';
import '../models/semester_settings.dart';
import '../models/time_table.dart';
import '../services/settings_service.dart';
import '../services/course_service.dart';
import '../services/time_table_service.dart';
import '../services/display_preferences_service.dart';
import '../services/firebase_consent_service.dart';
import '../services/firebase_init_service.dart';
import '../widgets/course_detail_dialog.dart';
import '../widgets/course_table_share_dialog.dart';
import '../widgets/firebase_consent_dialog.dart';
import 'semester_management_page.dart';
import 'course_management_page.dart';
import 'time_table_management_page.dart';
import 'data_management_page.dart';
import 'privacy_policy_page.dart';
import 'help_page.dart';

/// 课程表主页面
class CourseTablePage extends StatefulWidget {
  const CourseTablePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<CourseTablePage> createState() => _CourseTablePageState();
}

class _CourseTablePageState extends State<CourseTablePage> {
  int _currentWeek = 1; // 当前显示的周次
  late PageController _pageController;
  late int _totalWeeks; // 总周数（从设置读取）
  late DateTime _semesterStartDate; // 学期开始日期（从设置读取）
  final DateTime _today = DateTime.now(); // 今天的日期
  bool _isLoadingSettings = true; // 是否正在加载设置
  bool _showWeekend = true; // 是否展示周末列
  List<Course> _courses = []; // 课程数据列表
  late TimeTable _currentTimeTable; // 当前使用的时间表
  SemesterSettings? _currentSemester; // 当前激活的学期

  @override
  void initState() {
    super.initState();
    _loadSettingsAndInitialize();
  }

  /// 加载设置并初始化
  Future<void> _loadSettingsAndInitialize() async {
    // 并行加载设置、时间表和激活学期
    final results = await Future.wait([
      TimeTableService.getActiveTimeTable(),
      SettingsService.getActiveSemester(),
      DisplayPreferencesService.loadShowWeekend(),
    ]);

    final timeTable = results[0] as TimeTable;
    final semester = results[1] as SemesterSettings;
    final showWeekend = results[2] as bool;

    // 根据当前学期加载课程
    final courses = await CourseService.loadCoursesBySemester(semester.id);

    // 先设置基础数据,用于计算当前周次
    _currentSemester = semester;
    _semesterStartDate = semester.startDate;
    _totalWeeks = semester.totalWeeks;
    _currentTimeTable = timeTable;

    // 计算今天所在的实际周次
    final actualWeek = _calculateWeekNumber(_today);
    _currentWeek = actualWeek;

    // 初始化 PageController，初始页面为今天所在周
    _pageController = PageController(initialPage: _currentWeek - 1);

    // 最后更新状态触发重新渲染
    setState(() {
      _courses = courses;
      _isLoadingSettings = false;
      _showWeekend = showWeekend;
    });

    // 页面加载完成后，检查是否需要显示 Firebase 同意对话框
    _checkFirebaseConsent();
  }

  /// 检查是否需要显示 Firebase 同意对话框
  Future<void> _checkFirebaseConsent() async {
    final consent = await FirebaseConsentService.loadConsent();

    // 如果已经显示过对话框，不再显示
    if (consent.hasShown) {
      return;
    }

    // 延迟显示对话框，确保 UI 完全构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final updatedConsent = await FirebaseConsentDialog.show(context);
      if (updatedConsent != null) {
        await FirebaseInitService.initialize();
      }
    });
  }

  /// 重新加载学期（从学期管理页面返回时调用）
  Future<void> _reloadSemester() async {
    final semester = await SettingsService.getActiveSemester();
    final courses = await CourseService.loadCoursesBySemester(semester.id);

    setState(() {
      _currentSemester = semester;
      _semesterStartDate = semester.startDate;
      _totalWeeks = semester.totalWeeks;
      _courses = courses;
    });

    // 重新计算当前周次
    final actualWeek = _calculateWeekNumber(_today);
    if (actualWeek != _currentWeek) {
      _currentWeek = actualWeek;
      // 跳转到新的当前周
      _pageController.jumpToPage(_currentWeek - 1);
    }
  }

  /// 重新加载课程（从课程管理页面返回时调用）
  Future<void> _reloadCourses() async {
    if (_currentSemester != null) {
      final courses = await CourseService.loadCoursesBySemester(
        _currentSemester!.id,
      );
      setState(() {
        _courses = courses;
      });
    }
  }

  /// 重新加载时间表（从时间表管理页面返回时调用）
  Future<void> _reloadTimeTable() async {
    final timeTable = await TimeTableService.getActiveTimeTable();
    setState(() {
      _currentTimeTable = timeTable;
    });
  }

  void _updateShowWeekend(bool value) {
    if (_showWeekend == value) {
      return;
    }
    setState(() {
      _showWeekend = value;
    });
    unawaited(DisplayPreferencesService.saveShowWeekend(value));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 计算指定日期所在的周次
  int _calculateWeekNumber(DateTime date) {
    final difference = date.difference(_semesterStartDate).inDays;
    final week = (difference / 7).floor() + 1;
    // 确保周次在有效范围内
    return week.clamp(1, _totalWeeks);
  }

  /// 获取今天所在的实际周次
  int get _actualCurrentWeek => _calculateWeekNumber(_today);

  /// 判断当前视图是否在本周
  bool get _isViewingCurrentWeek => _currentWeek == _actualCurrentWeek;

  /// 跳转到本周
  void _jumpToCurrentWeek() {
    if (!_isViewingCurrentWeek) {
      _pageController.animateToPage(
        _actualCurrentWeek - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 获取当前显示周次的开始日期
  DateTime get _currentWeekStartDate {
    // 从学期开始日期计算当前周的开始日期
    final daysOffset = (_currentWeek - 1) * 7;
    final weekStart = _semesterStartDate.add(Duration(days: daysOffset));
    // 调整到周一
    final weekday = weekStart.weekday;
    return weekStart.subtract(Duration(days: weekday - 1));
  }

  /// 根据当前周次过滤课程（同时过滤隐藏的课程）
  List<Course> get _currentWeekCourses {
    return _courses.where((course) {
      // 过滤隐藏的课程
      if (course.isHidden) return false;
      // 过滤不在当前周次的课程
      return _currentWeek >= course.startWeek && _currentWeek <= course.endWeek;
    }).toList();
  }

  int get _visibleDayCount => _showWeekend ? 7 : 5;

  List<int> get _visibleWeekdays =>
      List<int>.generate(_visibleDayCount, (index) => index + 1);

  double _calculateCellWidth(BuildContext context) {
    final availableWidth = MediaQuery.of(context).size.width - 50;
    return availableWidth / _visibleDayCount;
  }

  @override
  Widget build(BuildContext context) {
    // 显示加载状态
    if (_isLoadingSettings) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildWeekSelector(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalWeeks,
                physics: const PageScrollPhysics(), // 明确使用 PageView 的物理特性
                onPageChanged: (index) {
                  setState(() {
                    _currentWeek = index + 1;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildCourseGrid();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部日期信息
  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
    final disabledColor = onSurface.withValues(alpha: 0.2);
    final primaryColor = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // 垂直上对齐
        children: [
          // 汉堡菜单按钮
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, size: 28),
              tooltip: '菜单',
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 最小化垂直空间
            children: [
              // 今天日期
              GestureDetector(
                onTap: _jumpToCurrentWeek,
                child: Text(
                  '${_today.year}/${_today.month.toString().padLeft(2, '0')}/${_today.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 4),
              // 周次控制栏
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 上一周按钮
                  InkWell(
                    onTap: _currentWeek > 1
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: _currentWeek > 1
                            ? onSurfaceVariant
                            : disabledColor,
                      ),
                    ),
                  ),
                  // 周次显示
                  Text(
                    '第 $_currentWeek 周',
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 刷新按钮
                  InkWell(
                    onTap: _isViewingCurrentWeek ? null : _jumpToCurrentWeek,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.refresh,
                        size: 16,
                        color: _isViewingCurrentWeek
                            ? disabledColor
                            : primaryColor,
                      ),
                    ),
                  ),
                  // 下一周按钮
                  InkWell(
                    onTap: _currentWeek < _totalWeeks
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: _currentWeek < _totalWeeks
                            ? onSurfaceVariant
                            : disabledColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建周次选择器
  Widget _buildWeekSelector() {
    final startOfWeek = _currentWeekStartDate;
    final colorScheme = Theme.of(context).colorScheme;
    final labelColor = colorScheme.onSurfaceVariant;
    final primaryColor = colorScheme.primary;
    final highlightTextColor = colorScheme.onPrimary;
    final normalTextColor = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${startOfWeek.month}\n月',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: labelColor),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _visibleWeekdays.map((weekday) {
                final date = startOfWeek.add(Duration(days: weekday - 1));
                const weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
                final now = DateTime.now();
                final isToday =
                    date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;

                return Column(
                  children: [
                    Text(
                      weekdayNames[weekday - 1],
                      style: TextStyle(fontSize: 11, color: labelColor),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isToday ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.month}/${date.day}',
                        style: TextStyle(
                          fontSize: 9,
                          color: isToday ? highlightTextColor : normalTextColor,
                        ),
                      ),
                    ),
                  ],
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
    return SingleChildScrollView(
      scrollDirection: Axis.vertical, // 明确指定垂直滚动
      physics: const ClampingScrollPhysics(), // 使用 ClampingScrollPhysics 避免滚动冲突
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeColumn(),
          Expanded(child: _buildCoursesGrid()),
        ],
      ),
    );
  }

  /// 构建时间列
  Widget _buildTimeColumn() {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    final mutedTextColor = colorScheme.onSurfaceVariant;

    return Column(
      children: _currentTimeTable.sections.map((section) {
        return Container(
          width: 50,
          height: 85,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: dividerColor),
              right: BorderSide(color: dividerColor),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${section.section}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                section.timeRange,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: mutedTextColor,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建课程网格
  Widget _buildCoursesGrid() {
    const cellHeight = 85.0;
    // 使用当前周次过滤后的课程
    final visibleCourses = _showWeekend
        ? _currentWeekCourses
        : _currentWeekCourses.where((course) => course.weekday <= 5).toList();
    final dividerColor = Theme.of(context).dividerColor;
    final cellWidth = _calculateCellWidth(context);

    // 按时间段分组课程，检测冲突
    final courseGroups = _groupConflictingCourses(visibleCourses);

    return SizedBox(
      height: _currentTimeTable.sections.length * cellHeight,
      child: Stack(
        children: [
          // 背景网格
          Column(
            children: List.generate(
              _currentTimeTable.sections.length,
              (row) => Row(
                children: _visibleWeekdays
                    .map(
                      (_) => Container(
                        width: cellWidth,
                        height: cellHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: dividerColor),
                            right: BorderSide(color: dividerColor),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          // 课程卡片 - 支持冲突课程并排显示
          ...courseGroups.expand((group) {
            if (group.length == 1) {
              // 无冲突，正常显示
              return [_buildCourseCard(group[0], cellWidth, 1, 0)];
            } else {
              // 有冲突，并排显示
              return group.asMap().entries.map((entry) {
                final index = entry.key;
                final course = entry.value;
                return _buildCourseCard(
                  course,
                  cellWidth,
                  group.length, // 总共有几门冲突的课程
                  index, // 当前是第几门
                );
              });
            }
          }),
        ],
      ),
    );
  }

  /// 将冲突的课程分组
  List<List<Course>> _groupConflictingCourses(List<Course> courses) {
    final groups = <List<Course>>[];
    final processed = <Course>{};

    for (final course in courses) {
      if (processed.contains(course)) continue;

      // 找到所有与该课程冲突的课程
      final conflictGroup = <Course>[course];
      processed.add(course);

      for (final otherCourse in courses) {
        if (processed.contains(otherCourse)) continue;

        // 检查是否冲突
        if (_isConflicting(course, otherCourse)) {
          conflictGroup.add(otherCourse);
          processed.add(otherCourse);
        }
      }

      groups.add(conflictGroup);
    }

    return groups;
  }

  /// 判断两门课程是否在时间上冲突
  bool _isConflicting(Course a, Course b) {
    // 检查是否在同一天
    if (a.weekday != b.weekday) return false;

    // 检查节次是否重叠
    final aEnd = a.startSection + a.duration - 1;
    final bEnd = b.startSection + b.duration - 1;

    return !(aEnd < b.startSection || a.startSection > bEnd);
  }

  /// 构建单个课程卡片
  ///
  /// [course] 课程对象
  /// [cellWidth] 单元格宽度
  /// [conflictCount] 冲突课程总数（默认1表示无冲突）
  /// [conflictIndex] 当前课程在冲突组中的索引（从0开始）
  Widget _buildCourseCard(
    Course course,
    double cellWidth, [
    int conflictCount = 1,
    int conflictIndex = 0,
  ]) {
    const cellHeight = 85.0;

    // 计算位置和宽度（支持冲突课程并排显示）
    final baseLeft = (course.weekday - 1) * cellWidth;
    final top = (course.startSection - 1) * cellHeight;
    final height = course.duration * cellHeight - 3;

    // 如果有冲突，平分宽度
    final cardWidth = (cellWidth - 3) / conflictCount;
    final left = baseLeft + 1.5 + (cardWidth * conflictIndex);

    // 根据卡片高度、宽度和冲突数动态调整字体大小和显示策略
    final isSmallCard = course.duration == 1;
    final hasConflict = conflictCount > 1;

    // 优化字体大小策略：根据冲突数和卡片大小调整
    final nameFontSize = hasConflict
        ? (isSmallCard ? 9.5 : (conflictCount == 2 ? 11.0 : 10.0))
        : (isSmallCard ? 11.0 : 13.0);
    final locationFontSize = hasConflict
        ? (isSmallCard ? 8.0 : (conflictCount == 2 ? 9.0 : 8.5))
        : (isSmallCard ? 9.0 : 10.0);
    final teacherFontSize = hasConflict
        ? (isSmallCard ? 7.5 : 8.5)
        : (isSmallCard ? 8.5 : 9.5);

    // 优化显示策略：充分利用空间显示内容
    final showLocation = course.location.isNotEmpty &&
        (course.duration >= 2); // 2节以上都显示地点，无论是否冲突
    final showTeacher = course.teacher.isNotEmpty; // 始终显示教师（只要有教师信息）

    // 文字阴影增强对比度
    final textShadow = [
      Shadow(
        offset: const Offset(0, 0.5),
        blurRadius: 1.5,
        color: Colors.black.withValues(alpha: 0.3),
      ),
    ];

    // 冲突提示边框
    final borderDecoration = hasConflict
        ? BoxDecoration(
            border: Border.all(
              color: Colors.orange,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          )
        : null;

    // 根据冲突数和卡片大小优化内边距
    final horizontalPadding = hasConflict
        ? (conflictCount == 2 ? 4.0 : 3.0) // 2门冲突稍微宽松一点
        : 5.0;
    final verticalPadding = isSmallCard ? 3.0 : 4.0;

    return Positioned(
      left: left,
      top: top + 1.5,
      width: cardWidth,
      height: height,
      child: GestureDetector(
        onTap: () => CourseDetailDialog.show(context, course),
        child: Container(
          decoration: borderDecoration,
          child: Container(
            decoration: BoxDecoration(
              color: course.color,
              borderRadius: BorderRadius.circular(hasConflict ? 4 : 6),
              // 添加渐变覆盖层增强深度
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [course.color, course.color.withValues(alpha: 0.9)],
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 课程名称 - 主要信息,字体最大最粗
                Text(
                  course.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.w700,
                    height: 1.1, // 减小行高，节省空间
                    letterSpacing: -0.2,
                    shadows: textShadow,
                  ),
                  maxLines: isSmallCard
                      ? 1
                      : (hasConflict
                          ? (course.duration >= 2
                              ? 3
                              : 2) // 2节以上冲突课程显示3行名称
                          : 3),
                  overflow: TextOverflow.ellipsis,
                ),
                // 上课地点 - 次要信息
                if (showLocation) ...[
                  const SizedBox(height: 1.5),
                  Text(
                    'At ${course.location}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: locationFontSize,
                      fontWeight: FontWeight.w500,
                      height: 1.15, // 减小行高
                      letterSpacing: -0.1,
                      shadows: textShadow,
                    ),
                    maxLines: isSmallCard
                        ? 1
                        : (hasConflict
                            ? (course.duration >= 3 ? 2 : 1) // 3节以上显示2行地点
                            : 2),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // 教师姓名 - 辅助信息,字体较小
                if (showTeacher) ...[
                  const SizedBox(height: 1.5),
                  Text(
                    course.teacher,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: teacherFontSize,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                      shadows: textShadow,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建抽屉菜单
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 抽屉头部
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  '课程表',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentSemester?.name ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // 快捷操作分组
          _buildDrawerSection('快捷操作'),
          ListTile(
            leading: Icon(
              Icons.add_circle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.red[300]
                  : Colors.red[600],
            ),
            title: const Text('添加课程'),
            subtitle: const Text('快速添加新课程'),
            onTap: () async {
              Navigator.pop(context); // 关闭抽屉
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CourseManagementPage(autoShowAddDialog: true),
                ),
              );
              await _reloadCourses();
            },
          ),
          const Divider(),
          // 管理功能分组
          _buildDrawerSection('管理'),
          ListTile(
            leading: Icon(
              Icons.school,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue[300]
                  : Colors.blue[600],
            ),
            title: const Text('课程管理'),
            subtitle: const Text('查看和管理所有课程'),
            onTap: () async {
              Navigator.pop(context); // 关闭抽屉
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CourseManagementPage(),
                ),
              );
              await _reloadCourses();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.schedule,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.orange[300]
                  : Colors.orange[600],
            ),
            title: const Text('时间表管理'),
            subtitle: const Text('自定义上课时间'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TimeTableManagementPage(),
                ),
              );
              if (result == true) {
                await _reloadTimeTable();
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.calendar_month,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green[300]
                  : Colors.green[600],
            ),
            title: const Text('学期管理'),
            subtitle: const Text('管理学期设置'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SemesterManagementPage(),
                ),
              );
              if (result == true) {
                await _reloadSemester();
              }
            },
          ),
          const Divider(),
          // 工具功能分组
          _buildDrawerSection('工具'),
          ListTile(
            leading: Icon(
              Icons.cloud_sync,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.teal[300]
                  : Colors.teal[600],
            ),
            title: const Text('数据管理'),
            subtitle: const Text('导入和导出课程数据'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DataManagementPage(),
                ),
              );
              // 导入后可能数据发生变化，重新加载
              await _reloadSemester();
              await _reloadCourses();
              await _reloadTimeTable();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.share,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.purple[300]
                  : Colors.purple[600],
            ),
            title: const Text('分享课程表'),
            subtitle: const Text('生成分享图片'),
            onTap: () {
              Navigator.pop(context);
              _showShareDialog();
            },
          ),
          const Divider(),
          // 更多选项
          _buildDrawerSection('更多选项'),
          ListTile(
            leading: Icon(
              Icons.dark_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('主题模式'),
            subtitle: Text('当前：${_describeThemeMode(widget.themeMode)}'),
            onTap: () {
              Future.microtask(_showThemeModeSelector);
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          SwitchListTile.adaptive(
            value: _showWeekend,
            title: const Text('展示周六、周日'),
            subtitle: const Text('切换课程表是否包含周末列'),
            secondary: Icon(
              Icons.weekend,
              color: Theme.of(context).colorScheme.primary,
            ),
            onChanged: _updateShowWeekend,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          ListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('隐私与数据使用'),
            subtitle: const Text('管理 Firebase 功能设置'),
            onTap: () {
              Navigator.pop(context);
              _showFirebaseConsentSettings();
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(
              Icons.policy_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('隐私政策'),
            subtitle: const Text('查看应用隐私政策'),
            onTap: () {
              Navigator.pop(context);
              PrivacyPolicyPage.show(context);
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          // 设置和帮助分组
          _buildDrawerSection('其他'),
          ListTile(
            leading: Icon(
              Icons.help_outline,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber[300]
                  : Colors.amber[700],
            ),
            title: const Text('帮助'),
            subtitle: const Text('使用指南和常见问题'),
            onTap: () {
              Navigator.pop(context);
              HelpPage.show(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue[300]
                  : Colors.blue[700],
            ),
            title: const Text('关于'),
            subtitle: const Text('版本信息和开发者'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  String _describeThemeMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => '明亮模式',
      ThemeMode.dark => '深夜模式',
      ThemeMode.system => '跟随系统',
    };
  }

  Future<void> _showThemeModeSelector() async {
    if (!mounted) {
      return;
    }

    final options = <ThemeMode, String>{
      ThemeMode.system: '跟随系统',
      ThemeMode.light: '明亮模式',
      ThemeMode.dark: '深夜模式',
    };

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        void handleChange(ThemeMode mode) {
          widget.onThemeModeChanged(mode);
          Navigator.of(sheetContext).pop();
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '选择主题模式',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              ...options.entries.map(
                (entry) => ListTile(
                  leading: Icon(
                    widget.themeMode == entry.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: Theme.of(sheetContext).colorScheme.primary,
                  ),
                  title: Text(entry.value),
                  onTap: () => handleChange(entry.key),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// 构建抽屉菜单分组标题
  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// 显示分享对话框
  void _showShareDialog() {
    CourseTableShareDialog.show(
      context,
      courses: _currentWeekCourses,
      timeTable: _currentTimeTable,
      currentWeek: _currentWeek,
      weekStartDate: _currentWeekStartDate,
      showWeekend: _showWeekend,
      semesterName: _currentSemester?.name,
    );
  }

  /// 显示 Firebase 隐私设置对话框
  Future<void> _showFirebaseConsentSettings() async {
    await FirebaseConsentDialog.show(
      context,
      isSettings: true,
    );
  }

  /// 显示关于对话框
  Future<void> _showAboutDialog() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = '${packageInfo.version}+${packageInfo.buildNumber}';

    if (!mounted) return;

    showAboutDialog(
      context: context,
      applicationName: '课程表',
      applicationVersion: version,
      applicationIcon: const Icon(
        Icons.calendar_today,
        size: 48,
        color: Color(0xFF6BA3FF),
      ),
      applicationLegalese: '© 2025 Curriculum App',
      children: [
        const SizedBox(height: 16),
        const Text(
          '一个功能强大的智能课程管理应用，'
          '支持多学期管理、自定义时间表、课程导入导出等功能。',
        ),
      ],
    );
  }
}
