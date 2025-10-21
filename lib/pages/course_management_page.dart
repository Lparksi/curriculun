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
  /// 是否自动打开新建课程对话框
  final bool autoShowAddDialog;

  const CourseManagementPage({super.key, this.autoShowAddDialog = false});

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

  // 搜索相关状态
  bool _isSearchMode = false; // 是否处于搜索模式
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // 搜索关键词

  @override
  void initState() {
    super.initState();
    _loadCourses();
    // 监听搜索框变化
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    // 如果需要自动打开新建对话框，在加载完成后打开
    if (widget.autoShowAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEditDialog();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (context) => CourseEditDialog(
          course: course,
          courseIndex: index,
          allCourses: _courses,
          semesterId: _currentSemester?.id, // 传递当前学期ID
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      // 检查是否是删除操作
      if (result == 'DELETE' && index != null) {
        await _deleteCourse(index, fromDialog: true);
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
          // 添加新课程（冲突检测已在 CourseEditDialog 中完成）
          await CourseService.addCourse(result);
          if (mounted) {
            final message = result.isHidden
                ? '课程已添加（已隐藏）'
                : '课程已添加';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        }

        await _loadCourses();
      } else if (result is Map<String, dynamic>) {
        // 处理隐藏冲突课程的情况
        final newCourse = result['newCourse'] as Course;
        final conflictToHide = result['hideConflict'] as Course;

        // 找到要隐藏的课程在列表中的索引
        final hideIndex = _courses.indexWhere((c) =>
            c.name == conflictToHide.name &&
            c.weekday == conflictToHide.weekday &&
            c.startSection == conflictToHide.startSection &&
            c.startWeek == conflictToHide.startWeek &&
            c.endWeek == conflictToHide.endWeek);

        if (hideIndex != -1) {
          // 创建隐藏版本的冲突课程
          final hiddenCourse = Course(
            name: conflictToHide.name,
            location: conflictToHide.location,
            teacher: conflictToHide.teacher,
            weekday: conflictToHide.weekday,
            startSection: conflictToHide.startSection,
            duration: conflictToHide.duration,
            color: conflictToHide.color,
            startWeek: conflictToHide.startWeek,
            endWeek: conflictToHide.endWeek,
            semesterId: conflictToHide.semesterId,
            isHidden: true, // 设置为隐藏
          );

          // 更新被隐藏的课程
          await CourseService.updateCourse(hideIndex, hiddenCourse);
        }

        // 添加新课程
        if (index != null) {
          await CourseService.updateCourse(index, newCourse);
        } else {
          await CourseService.addCourse(newCourse);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已保存新课程并隐藏"${conflictToHide.name}"'),
            ),
          );
        }

        await _loadCourses();
      }
    }
  }

  /// 删除课程（fromDialog参数表示是否来自编辑对话框）
  Future<void> _deleteCourse(int index, {bool fromDialog = false}) async {
    final course = _courses[index];
    final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
    final weekdayText = '星期${weekdayNames[course.weekday - 1]}';

    // 如果是来自编辑对话框,则跳过二次确认(在对话框中已确认过)
    bool confirm = fromDialog;
    if (!fromDialog) {
      confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认删除课程'),
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
          ) ??
          false;
    }

    if (confirm && mounted) {
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

  /// 切换搜索模式
  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// 根据搜索关键词过滤课程
  List<Course> get _filteredCourses {
    if (_searchQuery.isEmpty) {
      return _courses;
    }

    final query = _searchQuery.toLowerCase();
    return _courses.where((course) {
      // 搜索课程名称、教师、地点
      return course.name.toLowerCase().contains(query) ||
          course.teacher.toLowerCase().contains(query) ||
          course.location.toLowerCase().contains(query);
    }).toList();
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
        title: const Text('确认删除课程'),
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
        title: _isSearchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索课程名、教师或地点...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              )
            : _isMultiSelectMode
                ? Text('已选择 ${_selectedIndices.length} 项')
                : const Text('课程管理'),
        leading: _isSearchMode || _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed:
                    _isSearchMode ? _toggleSearchMode : _toggleMultiSelectMode,
                tooltip: '取消',
              )
            : null,
        actions: _isSearchMode
            ? [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                    tooltip: '清空',
                  ),
              ]
            : _isMultiSelectMode
                ? [
                    IconButton(
                      icon: Icon(
                        _selectedIndices.length == _filteredCourses.length
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      onPressed: _toggleSelectAll,
                      tooltip: _selectedIndices.length == _filteredCourses.length
                          ? '取消全选'
                          : '全选',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed:
                          _selectedIndices.isEmpty ? null : _deleteSelected,
                      tooltip: '删除',
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _toggleSearchMode,
                      tooltip: '搜索',
                    ),
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
              : Column(
                  children: [
                    // 搜索结果提示
                    if (_searchQuery.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withValues(alpha: 0.3),
                        child: Text(
                          '找到 ${_filteredCourses.length} 门课程',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                        ),
                      ),
                    Expanded(child: _buildCourseList()),
                  ],
                ),
      floatingActionButton: _isMultiSelectMode || _isSearchMode
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
    // 使用过滤后的课程
    final displayCourses = _filteredCourses;

    // 按课程名称分组
    final coursesByName = <String, List<MapEntry<int, Course>>>{};
    for (int i = 0; i < _courses.length; i++) {
      final course = _courses[i];
      // 只显示过滤后的课程
      if (!displayCourses.contains(course)) continue;

      coursesByName.putIfAbsent(course.name, () => []);
      coursesByName[course.name]!.add(MapEntry(i, course));
    }

    // 如果过滤后没有课程，显示空状态
    if (coursesByName.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到匹配的课程',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试使用其他关键词搜索',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      );
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
                child: _buildHighlightedText(
                  courseName,
                  Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              child: _buildHighlightedText(
                                course.location,
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                _buildHighlightedText(
                                  course.teacher,
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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

                  // 隐藏/显示切换按钮
                  if (!_isMultiSelectMode)
                    IconButton(
                      icon: Icon(
                        course.isHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: course.isHidden
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => _toggleCourseVisibility(index),
                      tooltip: course.isHidden ? '显示课程' : '隐藏课程',
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

  /// 构建带高亮的文本
  Widget _buildHighlightedText(
    String text,
    TextStyle? style, {
    int maxLines = 1,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    if (_searchQuery.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final query = _searchQuery.toLowerCase();
    final textLower = text.toLowerCase();

    if (!textLower.contains(query)) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final spans = <TextSpan>[];
    int currentIndex = 0;

    while (currentIndex < text.length) {
      final matchIndex = textLower.indexOf(query, currentIndex);
      if (matchIndex == -1) {
        // 没有更多匹配，添加剩余文本
        spans.add(TextSpan(text: text.substring(currentIndex)));
        break;
      }

      // 添加匹配前的文本
      if (matchIndex > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, matchIndex)));
      }

      // 添加高亮的匹配文本
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchIndex + query.length),
          style: TextStyle(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      currentIndex = matchIndex + query.length;
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// 切换课程的隐藏/显示状态
  Future<void> _toggleCourseVisibility(int index) async {
    final course = _courses[index];
    final newCourse = Course(
      name: course.name,
      location: course.location,
      teacher: course.teacher,
      weekday: course.weekday,
      startSection: course.startSection,
      duration: course.duration,
      color: course.color,
      startWeek: course.startWeek,
      endWeek: course.endWeek,
      semesterId: course.semesterId,
      isHidden: !course.isHidden, // 切换隐藏状态
    );

    await CourseService.updateCourse(index, newCourse);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newCourse.isHidden ? '已隐藏"${course.name}"' : '已显示"${course.name}"',
          ),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () async {
              await CourseService.updateCourse(index, course);
              await _loadCourses();
            },
          ),
        ),
      );
    }

    await _loadCourses();
  }
}
