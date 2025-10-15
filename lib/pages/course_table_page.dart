import 'package:flutter/material.dart';
import '../models/course.dart';
import '../utils/course_colors.dart';

/// 课程表主页面
class CourseTablePage extends StatefulWidget {
  const CourseTablePage({super.key});

  @override
  State<CourseTablePage> createState() => _CourseTablePageState();
}

class _CourseTablePageState extends State<CourseTablePage> {
  final int _currentWeek = 5; // 当前第几周
  final DateTime _selectedDate = DateTime.now();

  // 示例课程数据
  late final List<Course> _courses = _initCourses();

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
        color: CourseColorManager.getColorForCourse('大学体育(三)'),
      ),
      Course(
        name: '大学英语(三)',
        location: '科技馆213',
        teacher: '秦清玲',
        weekday: 2,
        startSection: 1,
        duration: 2,
        color: CourseColorManager.getColorForCourse('大学英语(三)'),
      ),
      Course(
        name: '大学物理',
        location: '教学楼210',
        teacher: '牛富全',
        weekday: 3,
        startSection: 1,
        duration: 2,
        color: CourseColorManager.getColorForCourse('大学物理'),
      ),
      Course(
        name: '计算机系统基础',
        location: '教学楼102',
        teacher: '王丁磊',
        weekday: 4,
        startSection: 1,
        duration: 2,
        color: CourseColorManager.getColorForCourse('计算机系统基础'),
      ),
      Course(
        name: '概率论与数理统计',
        location: '科技馆101',
        teacher: '何朝兵',
        weekday: 5,
        startSection: 1,
        duration: 2,
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildWeekSelector(),
            Expanded(child: _buildCourseGrid()),
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
              Text(
                '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '第 $_currentWeek 周  当前为第 ${_currentWeek + 1} 周',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.file_download, size: 20),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.share, size: 20),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {},
                padding: EdgeInsets.zero,
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
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '10\n月',
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                section.timeRange,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[600],
                  height: 1.1,
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
          // 课程卡片
          ..._courses.map((course) => _buildCourseCard(course)),
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
    );
  }

}
