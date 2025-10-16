import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Web 端下载实现
/// 使用浏览器的下载功能

/// 下载图片文件到浏览器默认下载目录
Future<bool> downloadImage(Uint8List imageBytes, String fileName) async {
  try {
    // 1. 创建 Blob 对象
    final blob = web.Blob(
      [imageBytes.toJS as JSAny].toJS,
      web.BlobPropertyBag(type: 'image/png'),
    );

    // 2. 创建下载链接
    final url = web.URL.createObjectURL(blob);

    // 3. 创建隐藏的 <a> 元素并触发下载
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    web.document.body!.appendChild(anchor);
    anchor.click();

    // 4. 清理
    web.document.body!.removeChild(anchor);
    web.URL.revokeObjectURL(url);

    debugPrint('ShareService (Web): 下载成功 - $fileName');
    return true;
  } catch (e) {
    debugPrint('ShareService (Web): 下载失败 - $e');
    return false;
  }
}

/// 移动端分享功能(Web 端不支持,使用下载替代)
Future<bool> shareImage(
  Uint8List imageBytes,
  String fileName,
  String shareText,
  String subject,
) async {
  // Web 端使用下载替代分享
  return downloadImage(imageBytes, fileName);
}

/// 移动端保存功能(Web 端不支持,使用下载替代)
Future<String?> saveImageToDocuments(
  Uint8List imageBytes,
  String fileName,
) async {
  // Web 端使用下载替代保存
  final success = await downloadImage(imageBytes, fileName);
  return success ? '已下载到浏览器默认下载目录' : null;
}
