import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 教务系统导入页面
/// 提供 WebView 功能让用户登录教务系统并导航到课程表页面
/// 后续将实现自动提取 HTML 并解析课程数据
class CourseImportWebViewPage extends StatefulWidget {
  const CourseImportWebViewPage({super.key});

  @override
  State<CourseImportWebViewPage> createState() =>
      _CourseImportWebViewPageState();
}

class _CourseImportWebViewPageState extends State<CourseImportWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// 初始化 WebView
  void _initializeWebView() {
    // 创建 WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('HTTP 错误: ${error.response?.statusCode}');
            _showErrorSnackBar('加载页面失败，HTTP 错误: ${error.response?.statusCode}');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('资源加载错误: ${error.description}');
            _showErrorSnackBar('资源加载错误: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.baidu.com')); // 默认打开百度，用户可以自行导航
  }

  /// 提取当前页面的 HTML
  Future<void> _extractPageHtml() async {
    try {
      // 执行 JavaScript 获取页面 HTML
      final html = await _controller.runJavaScriptReturningResult(
        'document.documentElement.outerHTML',
      ) as String;

      if (!mounted) return;

      // 显示 HTML 内容（用于调试）
      _showHtmlPreviewDialog(html);
    } catch (e) {
      debugPrint('提取 HTML 失败: $e');
      _showErrorSnackBar('提取页面内容失败: $e');
    }
  }

  /// 显示 HTML 预览对话框（调试用）
  void _showHtmlPreviewDialog(String html) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('页面 HTML 内容'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              html,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              // 将 HTML 复制到剪贴板
              Navigator.pop(context);
              _showSuccessSnackBar('HTML 内容已准备解析（功能开发中）');
            },
            child: const Text('解析'),
          ),
        ],
      ),
    );
  }

  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Web 平台不支持 WebView
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('从教务系统导入'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Web 平台不支持此功能',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '请在 Android 平台使用此功能',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('从教务系统导入'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新页面',
            onPressed: () => _controller.reload(),
          ),
          // 提取 HTML 按钮
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: '提取页面内容',
            onPressed: _extractPageHtml,
          ),
          // 更多菜单
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'forward':
                  _controller.goForward();
                  break;
                case 'back':
                  _controller.goBack();
                  break;
                case 'clear_cache':
                  _controller.clearCache();
                  _controller.clearLocalStorage();
                  _showSuccessSnackBar('缓存已清除');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'back',
                child: Row(
                  children: [
                    Icon(Icons.arrow_back),
                    SizedBox(width: 8),
                    Text('后退'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'forward',
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward),
                    SizedBox(width: 8),
                    Text('前进'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('清除缓存'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 加载进度条
          if (_isLoading)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          // URL 地址栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.link, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentUrl,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          // 底部提示
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '请登录教务系统并导航到课程表页面，然后点击右上角的"提取页面内容"按钮',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
