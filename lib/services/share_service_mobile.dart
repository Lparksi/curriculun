import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 移动端分享实现
/// 使用 share_plus 提供的原生分享功能

/// 分享图片到其他应用
Future<bool> shareImage(
  Uint8List imageBytes,
  String fileName,
  String shareText,
  String subject,
) async {
  try {
    // 1. 保存到临时文件
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    // 2. 使用 share_plus 分享
    final xFile = XFile(filePath);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: shareText,
        subject: subject,
      ),
    );

    debugPrint('ShareService (Mobile): 分享状态 - ${result.status}');
    return result.status != ShareResultStatus.unavailable;
  } catch (e) {
    debugPrint('ShareService (Mobile): 分享失败 - $e');
    return false;
  }
}

/// 保存图片到文档目录
Future<String?> saveImageToDocuments(
  Uint8List imageBytes,
  String fileName,
) async {
  try {
    // 获取文档目录(持久化存储)
    final directory = await getApplicationDocumentsDirectory();

    // 创建文件路径
    final filePath = '${directory.path}/$fileName';

    // 写入文件
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    debugPrint('ShareService (Mobile): 图片已保存到 $filePath');
    return filePath;
  } catch (e) {
    debugPrint('ShareService (Mobile): 保存图片失败 - $e');
    return null;
  }
}

/// Web 端下载实现(移动端不使用,此处提供空实现)
Future<bool> downloadImage(Uint8List imageBytes, String fileName) async {
  throw UnsupportedError('downloadImage is only supported on Web platform');
}
