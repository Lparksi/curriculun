import 'dart:convert';

/// Web 平台文件下载工具类的桩实现
/// 在非 Web 平台(Android/iOS)上使用,抛出不支持错误
class WebFileUtils {
  /// 触发浏览器下载文件
  ///
  /// 在非 Web 平台抛出 UnsupportedError
  static void downloadFile(
    String content,
    String fileName, {
    String mimeType = 'application/json',
  }) {
    throw UnsupportedError('此方法仅支持 Web 平台');
  }

  /// 读取用户上传的文件内容
  ///
  /// [fileBytes] 文件字节数组
  /// 返回文件内容字符串
  static String readFileAsString(List<int> fileBytes) {
    return utf8.decode(fileBytes);
  }
}
