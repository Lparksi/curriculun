import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/semester_settings.dart';
import '../models/time_table.dart';
import '../services/course_service.dart';
import '../services/settings_service.dart';
import '../services/time_table_service.dart';
import '../widgets/course_edit_dialog.dart';

/// 课程管理页面
class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({super.key});

  @override
  State<CourseManagementPage> createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage> {
  List<Course> _courses = [];
  late TimeTable _currentTimeTable;
  SemesterSettings? _currentSemester;
  bool _isLoading = true;
  bool _isMultiSelectMode = false; // 是否处于多选模式
  final Set<int> _selectedIndices = {}; // 选中的课程索引

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  /// 加载课程列表
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    final results = await Future.wait([
      TimeTableService.getActiveTimeTable(),
      SettingsService.getActiveSemester(),
    ]);

    final timeTable = results[0] as TimeTable;
    final semester = results[1] as SemesterSettings;

    // 根据当前学期加载课程
    final courses = await CourseService.loadCoursesBySemester(semester.id);

    setState(() {
      _courses = courses;
      _currentTimeTable = timeTable;
      _currentSemester = semester;
      _isLoading = false;
    });
  }

  /// 显示课程编辑对话框
  Future<void> _showEditDialog({Course? course, int? index}) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => CourseEditDialog(
        course: course,
        courseIndex: index,
        allCourses: _courses,
        semesterId: _currentSemester?.id, // 传递当前学期ID
      ),
    );

    if (result != null && mounted) {
      // 检查是否是删除操作
      if (result == 'DELETE' && index != null) {
        await _deleteCourse(index);
        return;
      }

      // 处理保存操作
      if (result is Course) {
        if (index != null) {
          // 更新课程
          await CourseService.updateCourse(index, result);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('课程已更新')));
          }
        } else {
          // 检查时间冲突
          if (CourseService.hasTimeConflict(_courses, result)) {
            if (mounted) {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('时间冲突'),
                  content: const Text('检测到该课程与已有课程时间冲突，是否仍要添加？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('仍要添加'),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;
            }
          }

          // 添加新课程
          await CourseService.addCourse(result);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('课程已添加')));
          }
        }

        await _loadCourses();
      }
    }
  }

  /// 删除课程
  Future<void> _deleteCourse(int index) async {
    final course = _courses[index];
    final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
    final weekdayText = '星期${weekdayNames[course.weekday - 1]}';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除以下课程吗？\n\n'
          '课程名称：${course.name}\n'
          '上课时间：$weekdayText ${course.sectionRangeText}\n'
          '上课地点：${course.location}',
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
      await CourseService.deleteCourse(index);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已删除：${course.name}（$weekdayText ${course.sectionRangeText}）',
            ),
            action: SnackBarAction(
              label: '撤销',
              onPressed: () async {
                await CourseService.addCourse(course);
                await _loadCourses();
              },
            ),
          ),
        );
      }

      await _loadCourses();
    }
  }

  /// 重置为默认课程
  Future<void> _resetToDefault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('确定要恢复为默认课程数据吗？当前所有自定义课程将被删除。'),
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
            child: const Text('重置'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await CourseService.resetToDefault();
      await _loadCourses();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已恢复为默认课程')));
      }
    }
  }

  /// 切换多选模式
  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedIndices.clear(); // 退出多选模式时清空选择
      }
    });
  }

  /// 切换单个课程的选中状态
  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  /// 全选/取消全选
  void _toggleSelectAll() {
    setState(() {
      if (_selectedIndices.length == _courses.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.clear();
        for (int i = 0; i < _courses.length; i++) {
          _selectedIndices.add(i);
        }
      }
    });
  }

  /// 批量删除选中的课程
  Future<void> _deleteSelected() async {
    if (_selectedIndices.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedIndices.length} 门课程吗？'),
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
      // 保存要删除的课程（用于撤销）
      final deletedCourses = <Course>[];
      final sortedIndices = _selectedIndices.toList()
        ..sort((a, b) => b.compareTo(a));

      for (final index in sortedIndices) {
        deletedCourses.add(_courses[index]);
      }

      // 从后往前删除，避免索引变化
      for (final index in sortedIndices) {
        await CourseService.deleteCourse(index);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已删除 ${deletedCourses.length} 门课程'),
            action: SnackBarAction(
              label: '撤销',
              onPressed: () async {
                for (final course in deletedCourses) {
                  await CourseService.addCourse(course);
                }
                await _loadCourses();
              },
            ),
          ),
        );
      }

      // 清空选择并退出多选模式
      setState(() {
        _selectedIndices.clear();
        _isMultiSelectMode = false;
      });

      await _loadCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text('已选择 ${_selectedIndices.length} 项')
            : const Text('课程管理'),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleMultiSelectMode,
                tooltip: '取消',
              )
            : null,
        actions: _isMultiSelectMode
            ? [
                IconButton(
                  icon: Icon(
                    _selectedIndices.length == _courses.length
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  onPressed: _toggleSelectAll,
                  tooltip: _selectedIndices.length == _courses.length
                      ? '取消全选'
                      : '全选',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedIndices.isEmpty ? null : _deleteSelected,
                  tooltip: '删除',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: _toggleMultiSelectMode,
                  tooltip: '多选',
                ),
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: _resetToDefault,
                  tooltip: '恢复默认',
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
          ? _buildEmptyState()
          : _buildCourseList(),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              onPressed: () => _showEditDialog(),
              tooltip: '添加课程',
              child: const Icon(Icons.add),
            ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无课程',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加课程',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建课程列表
  Widget _buildCourseList() {
    // 按课程名称分组
    final coursesByName = <String, List<MapEntry<int, Course>>>{};
    for (int i = 0; i < _courses.length; i++) {
      final course = _courses[i];
      coursesByName.putIfAbsent(course.name, () => []);
      coursesByName[course.name]!.add(MapEntry(i, course));
    }

    // 按课程名称排序
    final sortedNames = coursesByName.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedNames.length,
      itemBuilder: (context, index) {
        final courseName = sortedNames[index];
        final courses = coursesByName[courseName]!;

        // 按星期和节次排序
        courses.sort((a, b) {
          final weekdayCompare = a.value.weekday.compareTo(b.value.weekday);
          if (weekdayCompare != 0) return weekdayCompare;
          return a.value.startSection.compareTo(b.value.startSection);
        });

        return _buildCourseSection(courseName, courses);
      },
    );
  }

  /// 构建课程分组
  Widget _buildCourseSection(
    String courseName,
    List<MapEntry<int, Course>> courses,
  ) {
    // 使用第一个课程的颜色作为分组标识
    final courseColor = courses.first.value.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: courseColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  courseName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${courses.length}节',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...courses.map((entry) => _buildCourseCard(entry.key, entry.value)),
        const SizedBox(height: 8),
      ],
    );
  }

  /// 构建课程卡片
  Widget _buildCourseCard(int index, Course course) {
    final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
    final isSelected = _selectedIndices.contains(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      child: Dismissible(
        key: ValueKey('course_$index'),
        direction: _isMultiSelectMode
            ? DismissDirection.none
            : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          await _deleteCourse(index);
          return false; // 不自动删除，由我们手动刷新列表
        },
        child: InkWell(
          onTap: _isMultiSelectMode
              ? () => _toggleSelection(index)
              : () => _showEditDialog(course: course, index: index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 多选模式下显示复选框，否则显示星期标识
                  if (_isMultiSelectMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleSelection(index),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: course.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '周${weekdayNames[course.weekday - 1]}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 12),

                  // 课程信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 时间信息（主标题）
                        Text(
                          '${course.sectionRangeText} ${course.getTimeRangeText(_currentTimeTable)}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // 地点信息
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                course.location,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // 教师和周次
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              if (course.teacher.isNotEmpty) ...[
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  course.teacher,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Icon(
                                Icons.event,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                course.weekRangeText,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 编辑按钮（非多选模式显示）
                  if (!_isMultiSelectMode)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          _showEditDialog(course: course, index: index),
                      tooltip: '编辑',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
