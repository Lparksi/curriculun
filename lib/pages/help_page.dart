import 'package:flutter/material.dart';

/// 帮助页面 - 使用指南和常见问题
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  /// 显示帮助页面
  static Future<void> show(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('帮助中心'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 欢迎卡片
          _buildWelcomeCard(context),
          const SizedBox(height: 24),

          // 功能介绍
          _buildSectionTitle(context, '✨ 功能介绍'),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            icon: Icons.calendar_today,
            title: '多学期管理',
            description: '支持创建多个学期，轻松切换不同学期的课程表',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            icon: Icons.schedule,
            title: '自定义时间表',
            description: '自由设置上课时间，支持多套时间表方案',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            icon: Icons.cloud_sync,
            title: 'WebDAV 云备份',
            description: '数据安全存储，多设备同步无忧',
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            icon: Icons.color_lens,
            title: '智能配色',
            description: '18色高辨识度色盘，同名课程颜色一致',
            color: Colors.purple,
          ),
          const SizedBox(height: 24),

          // 使用指南
          _buildSectionTitle(context, '📖 使用指南'),
          const SizedBox(height: 12),
          _buildGuideExpansionTile(
            context,
            title: '如何添加课程？',
            icon: Icons.add_circle_outline,
            steps: [
              '方法一：点击左上角菜单 → 快捷操作 → 添加课程',
              '方法二：点击菜单 → 管理 → 课程管理 → 右下角 + 按钮',
              '填写课程名称、教师、地点等信息',
              '设置上课时间：星期、节次、周次范围',
              '点击保存即可',
            ],
          ),
          _buildGuideExpansionTile(
            context,
            title: '如何切换学期？',
            icon: Icons.calendar_month,
            steps: [
              '点击左上角菜单 → 管理 → 学期管理',
              '在学期列表中点击要切换的学期',
              '点击「设为当前学期」按钮',
              '返回主页面即可看到该学期的课程',
            ],
          ),
          _buildGuideExpansionTile(
            context,
            title: '如何修改时间表？',
            icon: Icons.access_time,
            steps: [
              '点击左上角菜单 → 管理 → 时间表管理',
              '点击要修改的时间表进入编辑',
              '调整各节课的开始和结束时间',
              '保存后返回，新时间会立即生效',
            ],
          ),
          _buildGuideExpansionTile(
            context,
            title: '如何导入/导出课程？',
            icon: Icons.import_export,
            steps: [
              '点击菜单 → 工具 → 数据管理',
              '导出：选择要导出的内容（全部数据/仅课程/仅学期等）',
              '导入：点击「导入数据」选择 JSON 文件',
              '可选择覆盖或合并模式',
              '支持版本管理，自动升级旧版本数据',
            ],
          ),
          _buildGuideExpansionTile(
            context,
            title: '如何设置 WebDAV 备份？',
            icon: Icons.cloud_upload,
            steps: [
              '点击菜单 → 工具 → 数据管理 → WebDAV 云备份',
              '输入 WebDAV 服务器地址、用户名、密码',
              '设置备份路径（可选，默认为 /curriculum_backup）',
              '点击「测试连接」确保配置正确',
              '保存后即可使用备份和恢复功能',
            ],
          ),
          _buildGuideExpansionTile(
            context,
            title: '如何分享课程表？',
            icon: Icons.share,
            steps: [
              '点击菜单 → 工具 → 分享课程表',
              '选择要分享的周次和主题样式',
              '预览课程表截图',
              '点击「分享」按钮选择分享方式',
              '可保存图片或分享到社交媒体',
            ],
          ),
          const SizedBox(height: 24),

          // 常见问题
          _buildSectionTitle(context, '❓ 常见问题'),
          const SizedBox(height: 12),
          _buildFaqExpansionTile(
            context,
            question: '为什么课程显示不出来？',
            answer: '请检查以下几点：\n'
                '1. 确认当前周次在课程的周次范围内\n'
                '2. 检查是否选择了正确的学期\n'
                '3. 确认课程没有被隐藏（编辑课程时查看）\n'
                '4. 如果显示周末，确认「展示周六、周日」开关状态',
          ),
          _buildFaqExpansionTile(
            context,
            question: '课程时间冲突怎么办？',
            answer: '应用支持课程冲突处理：\n'
                '1. 添加冲突课程时会显示冲突提示\n'
                '2. 冲突课程会并排显示在课程表中\n'
                '3. 可以选择隐藏其中一门课程（编辑课程 → 勾选「隐藏此课程」）\n'
                '4. 隐藏的课程不会在主课程表中显示，但数据仍保留',
          ),
          _buildFaqExpansionTile(
            context,
            question: '如何快速定位当前周？',
            answer: '点击顶部日期旁边的刷新按钮（🔄），会自动跳转到本周课程表。',
          ),
          _buildFaqExpansionTile(
            context,
            question: '数据会丢失吗？',
            answer: '应用采用多重保护机制：\n'
                '1. 所有数据自动保存到本地存储\n'
                '2. 支持导出 JSON 文件备份\n'
                '3. 支持 WebDAV 云端备份\n'
                '4. 导入时可选择合并模式，不会覆盖已有数据\n'
                '建议定期导出或使用云备份功能。',
          ),
          _buildFaqExpansionTile(
            context,
            question: 'Firebase 功能有什么用？',
            answer: 'Firebase 提供以下功能：\n'
                '1. 崩溃报告：自动收集应用崩溃信息，帮助开发者修复问题\n'
                '2. 性能监控：跟踪应用性能，优化用户体验\n'
                '3. 所有功能完全可选，您可以在「隐私与数据使用」中关闭\n'
                '4. 不收集任何个人身份信息或课程数据',
          ),
          _buildFaqExpansionTile(
            context,
            question: '如何更换主题？',
            answer: '点击菜单 → 更多选项 → 主题模式，可选择：\n'
                '• 明亮模式：始终使用亮色主题\n'
                '• 深夜模式：始终使用暗色主题\n'
                '• 跟随系统：根据系统设置自动切换',
          ),
          _buildFaqExpansionTile(
            context,
            question: '课程搜索功能怎么用？',
            answer: '在课程管理页面：\n'
                '1. 点击右上角搜索图标\n'
                '2. 输入课程名称、教师或地点的关键词\n'
                '3. 实时过滤并高亮显示匹配内容\n'
                '4. 点击 × 清除搜索',
          ),
          const SizedBox(height: 24),

          // 技巧提示
          _buildSectionTitle(context, '💡 使用技巧'),
          const SizedBox(height: 12),
          _buildTipCard(
            context,
            icon: Icons.lightbulb_outline,
            tip: '长按课程卡片可以快速查看课程详情',
            color: Colors.amber,
          ),
          const SizedBox(height: 8),
          _buildTipCard(
            context,
            icon: Icons.copy,
            tip: '复制学期或时间表可以快速创建相似配置',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _buildTipCard(
            context,
            icon: Icons.color_lens,
            tip: '相同课程名会自动使用一致的颜色',
            color: Colors.pink,
          ),
          const SizedBox(height: 8),
          _buildTipCard(
            context,
            icon: Icons.weekend,
            tip: '不上周末课程？关闭「展示周六、周日」可以让课程表更简洁',
            color: Colors.indigo,
          ),
          const SizedBox(height: 32),

          // 底部信息
          Center(
            child: Column(
              children: [
                Text(
                  '还有问题？',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '查看「关于」了解版本信息',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建欢迎卡片
  Widget _buildWelcomeCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.waving_hand,
              size: 48,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '欢迎使用课程表！',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '这里有完整的使用指南和常见问题解答',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
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

  /// 构建分组标题
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// 构建功能卡片
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1);
    final iconColor = isDark ? color.withValues(alpha: 0.8) : color;

    return Card(
      elevation: 0,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
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

  /// 构建使用指南展开项
  Widget _buildGuideExpansionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> steps,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: ExpansionTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
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

  /// 构建常见问题展开项
  Widget _buildFaqExpansionTile(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: ExpansionTile(
        leading: Icon(Icons.help_outline, color: colorScheme.primary),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建技巧卡片
  Widget _buildTipCard(
    BuildContext context, {
    required IconData icon,
    required String tip,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08);
    final iconColor = isDark ? color.withValues(alpha: 0.7) : color;

    return Card(
      elevation: 0,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tip,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
