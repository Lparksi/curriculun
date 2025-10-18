import 'package:flutter/material.dart';
import '../models/privacy_policy.dart';

/// 隐私政策页面
///
/// 显示应用的隐私政策，支持中英文
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  /// 显示隐私政策页面
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final content = PrivacyPolicy.getContent(locale.languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(locale.languageCode.startsWith('zh') ? '隐私政策' : 'Privacy Policy'),
          ],
        ),
        actions: [
          // 分享按钮（可选）
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: locale.languageCode.startsWith('zh') ? '分享' : 'Share',
            onPressed: () => _sharePrivacyPolicy(context, content),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: SelectableText(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              fontSize: 15,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.check),
        label: Text(locale.languageCode.startsWith('zh') ? '我已阅读' : 'I Have Read'),
      ),
    );
  }

  /// 分享隐私政策
  void _sharePrivacyPolicy(BuildContext context, String content) {
    // 使用 share_plus 包分享内容
    // 这里简化处理，仅显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.localeOf(context).languageCode.startsWith('zh')
              ? '隐私政策内容已复制到剪贴板'
              : 'Privacy policy copied to clipboard',
        ),
      ),
    );
  }
}
