import 'package:flutter/material.dart';
import '../models/firebase_consent.dart';
import '../services/firebase_consent_service.dart';

/// Firebase 功能同意对话框
///
/// 在应用首次启动时显示，让用户选择是否启用各项 Firebase 功能
class FirebaseConsentDialog extends StatefulWidget {
  const FirebaseConsentDialog({
    super.key,
    this.isSettings = false,
  });

  /// 是否在设置页面中调用（如果是，则显示重启提示）
  final bool isSettings;

  /// 显示同意对话框
  static Future<FirebaseConsent?> show(
    BuildContext context, {
    bool isSettings = false,
  }) {
    return Navigator.of(context).push<FirebaseConsent>(
      MaterialPageRoute(
        builder: (context) => FirebaseConsentDialog(isSettings: isSettings),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<FirebaseConsentDialog> createState() => _FirebaseConsentDialogState();
}

class _FirebaseConsentDialogState extends State<FirebaseConsentDialog> {
  bool _crashlyticsEnabled = false;
  bool _performanceEnabled = false;
  bool _analyticsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final consent = await FirebaseConsentService.loadConsent();
    setState(() {
      _crashlyticsEnabled = consent.crashlyticsEnabled;
      _performanceEnabled = consent.performanceEnabled;
      _analyticsEnabled = consent.analyticsEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: widget.isSettings, // 仅在设置页面时允许返回
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.privacy_tip_outlined, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('隐私与数据使用'),
            ],
          ),
          automaticallyImplyLeading: widget.isSettings,
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isSettings
                  ? '您可以随时更改这些设置。修改后需要重启应用以应用新的政策。'
                  : '为了提供更好的使用体验，我们希望使用以下 Google Firebase 服务。所有数据仅用于改进应用质量，您可以选择启用或禁用这些功能。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            _buildFeatureItem(
              icon: Icons.bug_report_outlined,
              title: 'Crashlytics（崩溃报告）',
              description: '自动收集应用崩溃信息，帮助我们快速修复问题',
              value: _crashlyticsEnabled,
              onChanged: (value) {
                setState(() => _crashlyticsEnabled = value);
              },
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              icon: Icons.speed_outlined,
              title: 'Performance Monitoring（性能监控）',
              description: '收集应用性能数据，帮助我们优化应用速度',
              value: _performanceEnabled,
              onChanged: (value) {
                setState(() => _performanceEnabled = value);
              },
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              icon: Icons.analytics_outlined,
              title: 'Analytics（数据分析）',
              description: '收集匿名使用数据，帮助我们了解功能使用情况',
              value: _analyticsEnabled,
              onChanged: (value) {
                setState(() => _analyticsEnabled = value);
              },
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '您的选择不会影响应用的核心功能使用',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 添加底部安全区域
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 全部拒绝按钮
              if (!widget.isSettings)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDeclineAll(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                    child: const Text('全部拒绝'),
                  ),
                ),
              if (!widget.isSettings) const SizedBox(width: 12),
              // 全部接受按钮
              if (!widget.isSettings)
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _handleAcceptAll(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('全部接受'),
                  ),
                ),
              if (!widget.isSettings) const SizedBox(width: 12),
              // 确认按钮
              Expanded(
                child: FilledButton(
                  onPressed: () => _handleConfirm(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(widget.isSettings ? '保存并重启' : '确认'),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeclineAll(BuildContext context) {
    setState(() {
      _crashlyticsEnabled = false;
      _performanceEnabled = false;
      _analyticsEnabled = false;
    });
    _handleConfirm(context);
  }

  void _handleAcceptAll(BuildContext context) {
    setState(() {
      _crashlyticsEnabled = true;
      _performanceEnabled = true;
      _analyticsEnabled = true;
    });
    _handleConfirm(context);
  }

  Future<void> _handleConfirm(BuildContext context) async {
    final consent = FirebaseConsent(
      hasShown: true,
      crashlyticsEnabled: _crashlyticsEnabled,
      performanceEnabled: _performanceEnabled,
      analyticsEnabled: _analyticsEnabled,
    );

    await FirebaseConsentService.saveConsent(consent);

    if (context.mounted) {
      if (widget.isSettings) {
        // 在设置页面中，显示重启提示
        _showRestartDialog(context, consent);
      } else {
        // 首次启动，直接返回结果
        Navigator.of(context).pop(consent);
      }
    }
  }

  void _showRestartDialog(BuildContext context, FirebaseConsent consent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.restart_alt),
        title: const Text('需要重启应用'),
        content: const Text(
          '您的隐私设置已保存。为了应用新的政策，应用需要重启。\n\n请手动关闭并重新打开应用。',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭重启对话框
              Navigator.of(context).pop(consent); // 关闭设置对话框
            },
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
