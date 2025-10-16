import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/semester_settings.dart';
import '../services/settings_service.dart';
import '../utils/course_colors.dart';
import '../widgets/course_detail_dialog.dart';
import 'semester_settings_page.dart';

/// 课程表主页面
class CourseTablePage extends StatefulWidget {
  const CourseTablePage({super.key});

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

  // 示例课程数据
  late final List<Course> _courses = _initCourses();

  @override
  void initState() {
    super.initState();
    _loadSettingsAndInitialize();
  }

  /// 加载设置并初始化
  Future<void> _loadSettingsAndInitialize() async {
    final settings = await SettingsService.loadSemesterSettings();
    setState(() {
      _semesterStartDate = settings.startDate;
      _totalWeeks = settings.totalWeeks;
      _isLoadingSettings = false;
    });

    // 计算今天所在的实际周次
    final actualWeek = _calculateWeekNumber(_today);
    _currentWeek = actualWeek;
    // 初始化 PageController，初始页面为今天所在周
    _pageController = PageController(initialPage: _currentWeek - 1);
  }

  /// 重新加载设置（从设置页面返回时调用）
  Future<void> _reloadSettings() async {
    final settings = await SettingsService.loadSemesterSettings();
    setState(() {
      _semesterStartDate = settings.startDate;
      _totalWeeks = settings.totalWeeks;
    });

    // 重新计算当前周次
    final actualWeek = _calculateWeekNumber(_today);
    if (actualWeek != _currentWeek) {
      _currentWeek = actualWeek;
      // 跳转到新的当前周
      _pageController.jumpToPage(_currentWeek - 1);
    }
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

  /// 根据当前周次过滤课程
  List<Course> get _currentWeekCourses {
    return _courses.where((course) {
      return _currentWeek >= course.startWeek && _currentWeek <= course.endWeek;
    }).toList();
  }

  List<Course> _initCourses() {
    // 先重置颜色管理器
    CourseColorManager.reset();

    return [
      Course(
        name: '大学体育(三)',
        location: '篮球场(文明)',
        teacher: '王银晖',
        weekday: 1,
        startSection: 1,
        duration: 2,
        startWeek: 1,
        endWeek: 16,
        color: CourseColorManager.getColorForCourse('大学体育(三)'),
      ),
      Course(
        name: '大学英语(三)',
        location: '科技馆213',
        teacher: '秦清玲',
        weekday: 2,
        startSection: 1,
        duration: 2,
        startWeek: 1,
        endWeek: 18,
        color: CourseColorManager.getColorForCourse('大学英语(三)'),
      ),
      Course(
        name: '大学物理',
        location: '教学楼210',
        teacher: '牛富全',
        weekday: 3,
        startSection: 1,
        duration: 2,
        startWeek: 1,
        endWeek: 16,
        color: CourseColorManager.getColorForCourse('大学物理'),
      ),
      Course(
        name: '计算机系统基础',
        location: '教学楼102',
        teacher: '王丁磊',
        weekday: 4,
        startSection: 1,
        duration: 2,
        startWeek: 1,
        endWeek: 18,
        color: CourseColorManager.getColorForCourse('计算机系统基础'),
      ),
      Course(
        name: '概率论与数理统计',
        location: '科技馆101',
        teacher: '何朝兵',
        weekday: 5,
        startSection: 1,
        duration: 2,
        startWeek: 3,
        endWeek: 18,
        color: CourseColorManager.getColorForCourse('概率论与数理统计'),
      ),
      Course(
        name: '多媒体人机交互设计与实践',
        location: '科技馆214',
        teacher: '吕鑫',
        weekday: 2,
        startSection: 3,
        duration: 2,
        color: CourseColorManager.getColorForCourse('多媒体人机交互设计与实践'),
      ),
      Course(
        name: '多媒体人机交互设计与实践',
        location: '教学楼405机房',
        teacher: '吕鑫',
        weekday: 3,
        startSection: 3,
        duration: 2,
        color: CourseColorManager.getColorForCourse('多媒体人机交互设计与实践'),
      ),
      Course(
        name: '大学英语(三)',
        location: '科技馆101',
        teacher: '秦清玲',
        weekday: 4,
        startSection: 3,
        duration: 2,
        color: CourseColorManager.getColorForCourse('大学英语(三)'),
      ),
      Course(
        name: '专业英语',
        location: '科技馆214',
        teacher: '黄永灿',
        weekday: 5,
        startSection: 3,
        duration: 2,
        color: CourseColorManager.getColorForCourse('专业英语'),
      ),
      Course(
        name: '高等数学',
        location: '教学楼310',
        teacher: '刘跃军',
        weekday: 1,
        startSection: 5,
        duration: 2,
        color: CourseColorManager.getColorForCourse('高等数学'),
      ),
      Course(
        name: '大学语文',
        location: '科技馆315',
        teacher: '聂晓萌',
        weekday: 2,
        startSection: 5,
        duration: 2,
        color: CourseColorManager.getColorForCourse('大学语文'),
      ),
      Course(
        name: '马克思主义基本原理',
        location: '科技馆215',
        teacher: '木忆文',
        weekday: 3,
        startSection: 5,
        duration: 2,
        color: CourseColorManager.getColorForCourse('马克思主义基本原理'),
      ),
      Course(
        name: '概率论与数理统计',
        location: '科技馆213',
        teacher: '何朝兵',
        weekday: 4,
        startSection: 5,
        duration: 2,
        color: CourseColorManager.getColorForCourse('概率论与数理统计'),
      ),
      Course(
        name: '大学物理',
        location: '教学楼210',
        teacher: '牛富全',
        weekday: 1,
        startSection: 7,
        duration: 2,
        color: CourseColorManager.getColorForCourse('大学物理'),
      ),
      Course(
        name: '面向对象程序设计',
        location: '科技馆214',
        teacher: '郭磊',
        weekday: 2,
        startSection: 7,
        duration: 2,
        color: CourseColorManager.getColorForCourse('面向对象程序设计'),
      ),
      Course(
        name: '离散数学',
        location: '教学楼310',
        teacher: '刘跃军',
        weekday: 3,
        startSection: 7,
        duration: 2,
        color: CourseColorManager.getColorForCourse('离散数学'),
      ),
      Course(
        name: '大学物理',
        location: '大学物理实验室2',
        teacher: '',
        weekday: 1,
        startSection: 9,
        duration: 2,
        color: CourseColorManager.getColorForCourse('大学物理'),
      ),
      Course(
        name: '计算机系统基础',
        location: '教学楼102',
        teacher: '',
        weekday: 2,
        startSection: 9,
        duration: 2,
        color: CourseColorManager.getColorForCourse('计算机系统基础'),
      ),
      Course(
        name: '面向对象程序设计',
        location: '科技馆214',
        teacher: '',
        weekday: 3,
        startSection: 9,
        duration: 2,
        color: CourseColorManager.getColorForCourse('面向对象程序设计'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // 显示加载状态
    if (_isLoadingSettings) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _jumpToCurrentWeek,
                child: Text(
                  '${_today.year}/${_today.month.toString().padLeft(2, '0')}/${_today.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 140, // 固定宽度确保居中
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.chevron_left,
                          size: 18,
                          color: _currentWeek > 1 ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                    ),
                    // 周数显示区域 - 固定宽度
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '第 $_currentWeek 周',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // 刷新按钮 - 始终显示,本周时灰色且不可点击
                          GestureDetector(
                            onTap: _isViewingCurrentWeek ? null : _jumpToCurrentWeek,
                            child: Icon(
                              Icons.refresh,
                              size: 14,
                              color: _isViewingCurrentWeek
                                  ? Colors.grey[300]
                                  : Colors.blue[600],
                            ),
                          ),
                        ],
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
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: _currentWeek < _totalWeeks ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add, size: 28),
                onPressed: () {},
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.file_download, size: 28),
                onPressed: () {},
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.share, size: 28),
                onPressed: () {},
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 28),
                onPressed: _showMoreMenu,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${startOfWeek.month}\n月',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final date = startOfWeek.add(Duration(days: index));
                final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
                final isToday = date.day == DateTime.now().day &&
                    date.month == DateTime.now().month;

                return Column(
                  children: [
                    Text(
                      weekdayNames[index],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isToday ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.month}/${date.day}',
                        style: TextStyle(
                          fontSize: 9,
                          color: isToday ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                );
              }),
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
    return Column(
      children: SectionTimeTable.sections.map((section) {
        return Container(
          width: 50,
          height: 85,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
              right: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${section.section}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                section.timeRange,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
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
    final visibleCourses = _currentWeekCourses;

    return SizedBox(
      height: SectionTimeTable.sections.length * cellHeight,
      child: Stack(
        children: [
          // 背景网格
          Column(
            children: List.generate(
              SectionTimeTable.sections.length,
              (row) => Row(
                children: List.generate(
                  7,
                  (col) => Container(
                    width: (MediaQuery.of(context).size.width - 50) / 7,
                    height: cellHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                        right: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 课程卡片 - 仅显示当前周的课程
          ...visibleCourses.map((course) => _buildCourseCard(course)),
        ],
      ),
    );
  }

  /// 构建单个课程卡片
  Widget _buildCourseCard(Course course) {
    const cellHeight = 85.0;
    final cellWidth = (MediaQuery.of(context).size.width - 50) / 7;
    final left = (course.weekday - 1) * cellWidth;
    final top = (course.startSection - 1) * cellHeight;
    final height = course.duration * cellHeight - 3;

    // 根据卡片高度动态调整字体大小
    final isSmallCard = course.duration == 1;
    final nameFontSize = isSmallCard ? 11.0 : 13.0;
    final locationFontSize = isSmallCard ? 9.0 : 10.0;
    final teacherFontSize = isSmallCard ? 8.5 : 9.5;

    // 文字阴影增强对比度
    final textShadow = [
      Shadow(
        offset: const Offset(0, 0.5),
        blurRadius: 1.5,
        color: Colors.black.withValues(alpha: 0.3),
      ),
    ];

    return Positioned(
      left: left + 1.5,
      top: top + 1.5,
      width: cellWidth - 3,
      height: height,
      child: GestureDetector(
        onTap: () => CourseDetailDialog.show(context, course),
        child: Container(
          decoration: BoxDecoration(
            color: course.color,
            borderRadius: BorderRadius.circular(6),
            // 添加渐变覆盖层增强深度
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                course.color,
                course.color.withValues(alpha: 0.9),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
                  height: 1.15,
                  letterSpacing: -0.2,
                  shadows: textShadow,
                ),
                maxLines: isSmallCard ? 1 : 3,
                overflow: TextOverflow.ellipsis,
              ),
              // 上课地点 - 次要信息
              if (course.location.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '@${course.location}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: locationFontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    letterSpacing: -0.1,
                    shadows: textShadow,
                  ),
                  maxLines: isSmallCard ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // 教师姓名 - 辅助信息,字体较小
              if (course.teacher.isNotEmpty) ...[
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
    );
  }

  /// 显示更多菜单
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('学期设置'),
                onTap: () async {
                  Navigator.pop(context); // 关闭菜单
                  // 导航到设置页面
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SemesterSettingsPage(),
                    ),
                  );
                  // 如果设置被更新，重新加载设置
                  if (result == true) {
                    await _reloadSettings();
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: 显示关于页面
                },
              ),
            ],
          ),
        );
      },
    );
  }

}
