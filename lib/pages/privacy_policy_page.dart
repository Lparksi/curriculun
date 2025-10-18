import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/privacy_policy.dart';

/// 隐私政策页面
///
/// 显示应用的隐私政策，支持中英文
class PrivacyPolicyPage extends StatefulWidget {
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
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final GlobalKey _boundaryKey = GlobalKey();

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
        child: RepaintBoundary(
          key: _boundaryKey,
          child: MarkdownWidget(
            data: content,
            shrinkWrap: false,
            selectable: true,
            padding: const EdgeInsets.all(16.0),
            config: MarkdownConfig(
            configs: [
              // 配置链接样式
              LinkConfig(
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                onTap: (url) {
                  // 链接点击处理（可选）
                },
              ),
              // 配置段落样式
              PConfig(
                textStyle: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  fontSize: 15,
                ) ?? const TextStyle(height: 1.6, fontSize: 15),
              ),
              // 配置 H1 样式
              H1Config(
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ) ?? TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              // 配置 H2 样式
              H2Config(
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ) ?? TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              // 配置 H3 样式
              H3Config(
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ) ?? const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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

  /// 将 Widget 渲染为图片
  Future<Uint8List?> _captureWidget() async {
    try {
      // 获取 RenderRepaintBoundary
      final RenderRepaintBoundary boundary =
          _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // 将 Widget 转换为图片（使用 2.0 的像素比例提高清晰度）
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);

      // 转换为 PNG 格式的字节数据
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('截图失败: $e');
      return null;
    }
  }

  /// 分享隐私政策（作为图片）
  Future<void> _sharePrivacyPolicy(BuildContext context, String content) async {
    final locale = Localizations.localeOf(context);
    final title = locale.languageCode.startsWith('zh') ? '隐私政策' : 'Privacy Policy';

    // 显示加载提示
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locale.languageCode.startsWith('zh') ? '正在生成图片...' : 'Generating image...',
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      // 截图
      final imageBytes = await _captureWidget();

      if (imageBytes == null) {
        throw Exception(locale.languageCode.startsWith('zh') ? '截图失败' : 'Screenshot failed');
      }

      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/privacy_policy_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // 使用 share_plus 分享图片
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'image/png')],
          subject: title,
        ),
      );
    } catch (e) {
      // 分享失败时显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              locale.languageCode.startsWith('zh')
                  ? '分享失败: $e'
                  : 'Share failed: $e',
            ),
          ),
        );
      }
    }
  }
}
