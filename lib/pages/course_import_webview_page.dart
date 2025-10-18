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
  late final TextEditingController _urlController;
  late final FocusNode _urlFocusNode;

  bool _isLoading = true;
  String _currentUrl = 'https://www.baidu.com';
  double _loadingProgress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isEditingUrl = false;

  // 默认主页地址
  static const String _defaultHomeUrl = 'https://www.baidu.com';

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _currentUrl);
    _urlFocusNode = FocusNode();
    _initializeWebView();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
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
              if (!_isEditingUrl) {
                _urlController.text = url;
              }
            });
            _updateNavigationButtons();
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
              if (!_isEditingUrl) {
                _urlController.text = url;
              }
            });
            _updateNavigationButtons();
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
      ..loadRequest(Uri.parse(_defaultHomeUrl));
  }

  /// 更新导航按钮状态
  Future<void> _updateNavigationButtons() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();
    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }

  /// 导航到指定 URL
  void _navigateToUrl(String url) {
    // 添加协议前缀（如果没有）
    String finalUrl = url.trim();
    if (finalUrl.isEmpty) {
      _showErrorSnackBar('请输入有效的网址');
      return;
    }

    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }

    try {
      _controller.loadRequest(Uri.parse(finalUrl));
      _urlFocusNode.unfocus();
      setState(() {
        _isEditingUrl = false;
      });
    } catch (e) {
      _showErrorSnackBar('无效的网址: $e');
    }
  }

  /// 返回主页
  void _goHome() {
    _controller.loadRequest(Uri.parse(_defaultHomeUrl));
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
                case 'clear_cache':
                  _controller.clearCache();
                  _controller.clearLocalStorage();
                  _showSuccessSnackBar('缓存已清除');
                  break;
              }
            },
            itemBuilder: (context) => [
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

          // 导航栏
          _buildNavigationBar(),

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

  /// 构建导航栏
  Widget _buildNavigationBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 第一行：导航按钮 + 地址栏
          Row(
            children: [
              // 后退按钮
              IconButton(
                icon: const Icon(Icons.arrow_back),
                iconSize: 20,
                tooltip: '后退',
                onPressed: _canGoBack
                    ? () async {
                        await _controller.goBack();
                        _updateNavigationButtons();
                      }
                    : null,
              ),
              // 前进按钮
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                iconSize: 20,
                tooltip: '前进',
                onPressed: _canGoForward
                    ? () async {
                        await _controller.goForward();
                        _updateNavigationButtons();
                      }
                    : null,
              ),
              // 刷新按钮
              IconButton(
                icon: const Icon(Icons.refresh),
                iconSize: 20,
                tooltip: '刷新',
                onPressed: () => _controller.reload(),
              ),
              // 主页按钮
              IconButton(
                icon: const Icon(Icons.home),
                iconSize: 20,
                tooltip: '主页',
                onPressed: _goHome,
              ),
              const SizedBox(width: 8),
              // 地址栏
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isEditingUrl
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.3),
                      width: _isEditingUrl ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _urlController,
                    focusNode: _urlFocusNode,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '输入教务系统网址',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      prefixIcon: Icon(
                        _currentUrl.startsWith('https')
                            ? Icons.lock
                            : Icons.lock_open,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    textInputAction: TextInputAction.go,
                    keyboardType: TextInputType.url,
                    onTap: () {
                      setState(() {
                        _isEditingUrl = true;
                      });
                      _urlController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _urlController.text.length,
                      );
                    },
                    onSubmitted: (value) {
                      _navigateToUrl(value);
                    },
                    onEditingComplete: () {
                      _navigateToUrl(_urlController.text);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 前往按钮
              if (_isEditingUrl)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  iconSize: 20,
                  tooltip: '前往',
                  color: colorScheme.primary,
                  onPressed: () {
                    _navigateToUrl(_urlController.text);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
