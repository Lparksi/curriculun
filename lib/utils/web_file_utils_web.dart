import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web 平台文件下载工具类
/// 仅在 Web 平台使用,提供文件下载功能
class WebFileUtils {
  /// 触发浏览器下载文件
  ///
  /// [content] 文件内容(字符串)
  /// [fileName] 文件名
  /// [mimeType] MIME 类型,默认为 application/json
  static void downloadFile(
    String content,
    String fileName, {
    String mimeType = 'application/json',
  }) {
    // 创建 Blob 对象
    final bytes = utf8.encode(content);
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );

    // 创建下载链接
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    // 添加到 DOM,触发点击,然后移除
    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);

    // 释放 URL 对象
    web.URL.revokeObjectURL(url);
  }

  /// 读取用户上传的文件内容
  ///
  /// [fileBytes] 文件字节数组
  /// 返回文件内容字符串
  static String readFileAsString(List<int> fileBytes) {
    return utf8.decode(fileBytes);
  }
}
