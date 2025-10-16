import 'package:flutter/material.dart';
import '../models/semester_settings.dart';
import '../services/settings_service.dart';

/// 学期设置页面
class SemesterSettingsPage extends StatefulWidget {
  const SemesterSettingsPage({super.key});

  @override
  State<SemesterSettingsPage> createState() => _SemesterSettingsPageState();
}

class _SemesterSettingsPageState extends State<SemesterSettingsPage> {
  late DateTime _startDate;
  late int _totalWeeks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final settings = await SettingsService.loadSemesterSettings();
    setState(() {
      _startDate = settings.startDate;
      _totalWeeks = settings.totalWeeks;
      _isLoading = false;
    });
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    final settings = SemesterSettings(
      startDate: _startDate,
      totalWeeks: _totalWeeks,
    );

    await SettingsService.saveSemesterSettings(settings);

    if (!mounted) return;

    // 显示保存成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('设置已保存'),
        duration: Duration(seconds: 2),
      ),
    );

    // 返回上一页，并传递true表示设置已更新
    Navigator.of(context).pop(true);
  }

  /// 选择开始日期
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  /// 重置为默认设置
  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要恢复为默认设置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final defaultSettings = SemesterSettings.defaultSettings();
      setState(() {
        _startDate = defaultSettings.startDate;
        _totalWeeks = defaultSettings.totalWeeks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('学期设置'),
        actions: [
          TextButton(
            onPressed: _resetToDefault,
            child: const Text(
              '恢复默认',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 学期开始日期
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('学期开始日期'),
              subtitle: Text(
                '${_startDate.year}年${_startDate.month}月${_startDate.day}日',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectStartDate,
            ),
          ),

          const SizedBox(height: 16),

          // 学期总周数
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_note),
                      const SizedBox(width: 16),
                      const Text(
                        '学期总周数',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 说明文字
          Card(
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '设置说明',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 学期开始日期：从这一天开始计算第1周\n'
                    '• 学期总周数：整个学期的周数（一般为16-20周）\n'
                    '• 修改设置后，课程表会自动更新周次计算',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 保存按钮
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              '保存设置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
