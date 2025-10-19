import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/course_import/course_html_import_service.dart';
import '../services/course_import/models/course_import_models.dart';
import '../services/course_service.dart';

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

  final CourseHtmlImportService _importService = CourseHtmlImportService();

  bool _isLoading = true;
  String _currentUrl = 'https://cn.bing.com/';
  double _loadingProgress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isEditingUrl = false;
  bool _isMobileMode = true; // 默认为移动端模式
  bool _isParsingCourses = false;

  // 默认主页地址
  static const String _defaultHomeUrl = 'https://cn.bing.com/';

  // User-Agent 配置
  static const String _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
  static const String _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

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
      ..setUserAgent(_mobileUserAgent) // 默认使用移动端 User-Agent
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
            // 不显示错误提示，避免干扰用户操作
            // _showErrorSnackBar('加载页面失败，HTTP 错误: ${error.response?.statusCode}');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('资源加载错误: ${error.description}');
            // 不显示错误提示，避免干扰用户操作
            // _showErrorSnackBar('资源加载错误: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_defaultHomeUrl));
  }

  /// 切换移动端/桌面端模式
  void _toggleUserAgent() {
    setState(() {
      _isMobileMode = !_isMobileMode;
    });

    // 设置 User-Agent
    final userAgent = _isMobileMode ? _mobileUserAgent : _desktopUserAgent;
    _controller.setUserAgent(userAgent);

    // 重新加载当前页面以应用新的 User-Agent
    _controller.reload();

    // 显示提示
    _showSuccessSnackBar(
      _isMobileMode ? '已切换到移动端模式' : '已切换到桌面端模式',
    );
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

  /// 复制当前页面的 HTML 到剪贴板（调试用）
  Future<void> _copyPageHtml() async {
    try {
      // 执行 JavaScript 获取页面 HTML
      final html = await _controller.runJavaScriptReturningResult(
        'document.documentElement.outerHTML',
      ) as String;

      if (!mounted) return;

      // 复制到剪贴板
      await Clipboard.setData(ClipboardData(text: html));
      _showSuccessSnackBar('HTML 内容已复制到剪贴板');
    } catch (e) {
      debugPrint('复制 HTML 失败: $e');
      _showErrorSnackBar('复制页面内容失败: $e');
    }
  }

  /// 解析页面课程数据并展示导入预览
  Future<void> _parseAndPreviewCourses() async {
    if (_isParsingCourses) {
      return;
    }
    setState(() {
      _isParsingCourses = true;
    });

    try {
      final result =
          await _controller.runJavaScriptReturningResult(
        'document.documentElement.outerHTML',
      );

      if (!mounted) return;

      final html = result is String ? result : result.toString();

      if (html.trim().isEmpty) {
        _showErrorSnackBar('未获取到页面 HTML 内容');
        return;
      }

      var parseResult = _importService.parseHtml(
        CourseImportSource(
          rawContent: html,
          origin: Uri.tryParse(_currentUrl),
        ),
      );

      if (!mounted) return;

      final aggregatedMessages = <CourseImportMessage>[
        ...parseResult.messages,
      ];
      final combinedCourses = <ParsedCourse>[
        ...parseResult.courses,
      ];
      var finalStatus = parseResult.status;
      var finalParserId = parseResult.parserId;
      final finalMetadata = Map<String, Object?>.from(parseResult.metadata);

      if (parseResult.status == ParseStatus.needAdditionalInput &&
          parseResult.frameRequests.isNotEmpty) {
        final frameHtmlMap =
            await _collectFrameHtmls(parseResult.frameRequests);
        if (!mounted) return;

        if (frameHtmlMap.isEmpty) {
          aggregatedMessages.add(
            const CourseImportMessage(
              severity: ParserMessageSeverity.error,
              message: '自动抓取课表 iframe 页面失败，未能解析到课程数据。',
            ),
          );
        } else {
          aggregatedMessages.add(
            const CourseImportMessage(
              severity: ParserMessageSeverity.info,
              message: '已自动抓取课表 iframe 页面并尝试解析。',
            ),
          );

          for (final entry in frameHtmlMap.entries) {
            final frameResult = _importService.parseHtml(
              CourseImportSource(
                rawContent: entry.value,
                origin: Uri.tryParse(_resolveFrameUrl(entry.key.src)),
              ),
            );
            aggregatedMessages.addAll(frameResult.messages);
            if (frameResult.courses.isNotEmpty) {
              combinedCourses.addAll(frameResult.courses);
              finalStatus = frameResult.status;
              if (frameResult.parserId != null) {
                finalParserId = frameResult.parserId;
              }
              finalMetadata.addAll(frameResult.metadata);
            }
          }
        }
      }

      if (combinedCourses.isEmpty) {
        final message = aggregatedMessages.isNotEmpty
            ? aggregatedMessages.last.message
            : '未解析到任何课程信息';
        _showErrorSnackBar(message);
        return;
      }

      parseResult = CourseImportResult(
        status: finalStatus == ParseStatus.needAdditionalInput
            ? ParseStatus.success
            : finalStatus,
        courses: combinedCourses,
        messages: aggregatedMessages,
        parserId: finalParserId,
        metadata: finalMetadata,
      );

      final existingCourses = await CourseService.loadAllCourses();
      if (!mounted) return;

      final append = await _showCourseImportPreview(
        parseResult: parseResult,
        existingCount: existingCourses.length,
      );

      if (append == null) {
        return;
      }

      await _importService.persistParsedCourses(
        parseResult.courses,
        append: append,
      );

      if (!mounted) return;

      final modeText = append ? '追加' : '覆盖';
      _showSuccessSnackBar('已$modeText ${parseResult.courses.length} 门课程');
    } catch (e) {
      debugPrint('解析课程失败: $e');
      if (mounted) {
        _showErrorSnackBar('解析课程失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isParsingCourses = false;
        });
      }
    }
  }

  Future<bool?> _showCourseImportPreview({
    required CourseImportResult parseResult,
    required int existingCount,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        bool append = true;
        final courses = parseResult.courses;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '导入课程预览',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '检测到 ${courses.length} 门课程；当前课程表包含 $existingCount 门课程。请选择导入方式并确认变更。',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      if (parseResult.messages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...parseResult.messages.map(
                          (message) => _buildMessageBanner(
                            context,
                            message,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        '导入方式',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment<bool>(
                            value: true,
                            label: const Text('追加到现有课程'),
                            icon: const Icon(Icons.playlist_add),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: const Text('覆盖现有课程'),
                            icon: const Icon(Icons.auto_delete),
                          ),
                        ],
                        selected: <bool>{append},
                        onSelectionChanged: (selection) {
                          if (selection.isEmpty) return;
                          setModalState(() {
                            append = selection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        append
                            ? '保留原有课程，并追加解析到的课程。'
                            : '警告：将清空现有课程，仅保留此次解析结果。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: append
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : Theme.of(context).colorScheme.error,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: courses.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final course = courses[index];
                            return _buildCoursePreviewTile(course);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  Navigator.pop(context, append),
                              child: Text(
                                append ? '追加这些课程' : '覆盖后导入',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBanner(
    BuildContext context,
    CourseImportMessage message,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    Color background;
    Color foreground;
    IconData icon;

    switch (message.severity) {
      case ParserMessageSeverity.info:
        background = colorScheme.primaryContainer;
        foreground = colorScheme.onPrimaryContainer;
        icon = Icons.info_outline;
        break;
      case ParserMessageSeverity.warning:
        background = colorScheme.tertiaryContainer;
        foreground = colorScheme.onTertiaryContainer;
        icon = Icons.warning_amber_outlined;
        break;
      case ParserMessageSeverity.error:
        background = colorScheme.errorContainer;
        foreground = colorScheme.onErrorContainer;
        icon = Icons.error_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (message.detail != null &&
                    message.detail!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      message.detail!,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.9),
                        fontSize: 12,
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

  Widget _buildCoursePreviewTile(ParsedCourse course) {
    final detailParts = <String>[
      _weekdayLabel(course.weekday),
      _formatSectionRange(course),
      _formatWeekRange(course),
    ]..removeWhere((element) => element.isEmpty);

    final infoParts = <String>[];
    if (course.teacher.isNotEmpty) {
      infoParts.add(course.teacher);
    }
    if (course.location.isNotEmpty) {
      infoParts.add(course.location);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (detailParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                detailParts.join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (infoParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                infoParts.join(' · '),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
            ),
          if (course.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: course.notes
                    .map(
                      (note) => Text(
                        note,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (course.rawWeeks != null &&
              course.rawWeeks!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '原始周次信息：${course.rawWeeks!}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const names = [
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六',
      '周日',
    ];
    if (weekday >= 1 && weekday <= names.length) {
      return names[weekday - 1];
    }
    return '星期$weekday';
  }

  String _formatSectionRange(ParsedCourse course) {
    final end = course.startSection + course.duration - 1;
    if (course.duration <= 1) {
      return '第${course.startSection}节';
    }
    return '第${course.startSection}-$end节';
  }

  String _formatWeekRange(ParsedCourse course) {
    if (course.startWeek == course.endWeek) {
      return '第${course.startWeek}周';
    }
    return '第${course.startWeek}-${course.endWeek}周';
  }

  Future<Map<FrameRequest, String>> _collectFrameHtmls(
    List<FrameRequest> frames,
  ) async {
    final results = <FrameRequest, String>{};
    for (final frame in frames) {
      final html = await _tryFetchFrameHtml(frame);
      if (html != null && html.trim().isNotEmpty) {
        results[frame] = html;
      }
    }
    return results;
  }

  Future<String?> _tryFetchFrameHtml(FrameRequest frame) async {
    final extractionScript = _buildFrameExtractionScript(frame);
    try {
      final result =
          await _controller.runJavaScriptReturningResult(extractionScript);
      if (result is String && result.trim().isNotEmpty) {
        return result;
      }
    } catch (e) {
      debugPrint('读取 iframe 文档失败: $e');
    }

    final resolvedUrl = _resolveFrameUrl(frame.src);
    final fetchScript = _buildFrameFetchScript(resolvedUrl);
    try {
      final result =
          await _controller.runJavaScriptReturningResult(fetchScript);
      if (result is String && result.trim().isNotEmpty) {
        return result;
      }
    } catch (e) {
      debugPrint('通过 fetch 获取 iframe HTML 失败: $e');
    }

    return null;
  }

  String _buildFrameExtractionScript(FrameRequest frame) {
    final escapedSrc = frame.src.replaceAll('"', r'\"');
    return '''
(() => {
  const candidates = [
    document.getElementById("frmDesk"),
    document.querySelector('iframe[src*="$escapedSrc"]')
  ].filter(Boolean);
  for (const candidate of candidates) {
    const doc = candidate.contentDocument || candidate.contentWindow?.document;
    if (doc && doc.documentElement) {
      return doc.documentElement.outerHTML ?? '';
    }
  }
  return '';
})()
''';
  }

  String _buildFrameFetchScript(String url) {
    final escaped = url.replaceAll('"', r'\"');
    return '''
(async () => {
  try {
    const response = await fetch("$escaped", { credentials: 'include' });
    if (!response.ok) {
      return '';
    }
    return await response.text();
  } catch (error) {
    return '';
  }
})()
''';
  }

  String _resolveFrameUrl(String src) {
    try {
      final base = Uri.parse(_currentUrl);
      return base.resolve(src).toString();
    } catch (_) {
      return src;
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
          // 解析课程并导入
          IconButton(
            icon: const Icon(Icons.fact_check),
            tooltip: '解析课程并导入',
            onPressed:
                _isParsingCourses ? null : _parseAndPreviewCourses,
          ),
          // 复制 HTML 按钮（调试用）
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制页面 HTML',
            onPressed: _copyPageHtml,
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

          // 底部提示和控制栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 提示信息
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '请登录教务系统并导航到课程表页面，然后点击右上角的"提取页面内容"按钮',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 模式切换按钮
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _toggleUserAgent,
                    icon: Icon(
                      _isMobileMode ? Icons.computer : Icons.smartphone,
                      size: 18,
                    ),
                    label: Text(
                      _isMobileMode ? '切换到桌面端模式' : '切换到移动端模式',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
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
