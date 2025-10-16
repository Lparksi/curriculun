import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// 条件导入:非 Web 平台使用的模块
import 'share_service_mobile.dart'
    if (dart.library.html) 'share_service_web.dart' as platform_impl;

/// 课程表分享服务
/// 提供将课程表导出为图片并分享的功能
/// 自动适配移动端(分享)和 Web 端(下载)
class ShareService {
  /// 捕获 Widget 为图片
  ///
  /// [boundaryKey] RepaintBoundary 的 GlobalKey
  /// [pixelRatio] 图片质量倍率,默认 3.0,值越高质量越好但文件越大
  ///
  /// 返回图片的字节数据
  static Future<Uint8List?> captureWidget(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      // 获取 RenderRepaintBoundary
      final RenderRepaintBoundary? boundary = boundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('ShareService: RenderRepaintBoundary 未找到');
        return null;
      }

      // 转换为图片
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      // 转换为 PNG 字节数据
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('ShareService: 图片字节数据转换失败');
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('ShareService: 截图失败 - $e');
      return null;
    }
  }

  /// 分享或下载课程表图片
  /// - 移动端: 使用系统分享功能
  /// - Web 端: 直接下载图片文件
  ///
  /// [boundaryKey] RepaintBoundary 的 GlobalKey
  /// [shareText] 分享时的附加文本(Web 端忽略)
  /// [subject] 分享主题(Web 端忽略)
  /// [fileName] 文件名
  ///
  /// 返回是否成功
  static Future<bool> shareCourseTable(
    GlobalKey boundaryKey, {
    String? shareText,
    String? subject,
    String? fileName,
  }) async {
    try {
      // 1. 捕获 Widget 为图片
      final imageBytes = await captureWidget(boundaryKey);
      if (imageBytes == null) {
        debugPrint('ShareService: 截图失败,无法分享');
        return false;
      }

      // 2. 根据平台选择不同的实现
      if (kIsWeb) {
        // Web 平台:直接下载
        return await platform_impl.downloadImage(
          imageBytes,
          fileName ?? 'course_table.png',
        );
      } else {
        // 移动平台:使用分享功能
        return await platform_impl.shareImage(
          imageBytes,
          fileName ?? 'course_table.png',
          shareText ?? '我的课程表',
          subject ?? '课程表分享',
        );
      }
    } catch (e) {
      debugPrint('ShareService: 操作失败 - $e');
      return false;
    }
  }

  /// 保存课程表图片
  /// - 移动端: 保存到应用文档目录
  /// - Web 端: 下载图片文件
  ///
  /// [boundaryKey] RepaintBoundary 的 GlobalKey
  /// [fileName] 文件名
  ///
  /// 返回保存的文件路径,如果失败返回 null
  static Future<String?> saveCourseTableToGallery(
    GlobalKey boundaryKey, {
    String? fileName,
  }) async {
    try {
      // 1. 捕获 Widget 为图片
      final imageBytes = await captureWidget(boundaryKey);
      if (imageBytes == null) {
        debugPrint('ShareService: 截图失败,无法保存');
        return null;
      }

      // 2. 根据平台选择不同的实现
      if (kIsWeb) {
        // Web 平台:直接下载
        final success = await platform_impl.downloadImage(
          imageBytes,
          fileName ?? 'course_table.png',
        );
        return success ? '已下载到浏览器默认下载目录' : null;
      } else {
        // 移动平台:保存到文档目录
        return await platform_impl.saveImageToDocuments(
          imageBytes,
          fileName ?? 'course_table.png',
        );
      }
    } catch (e) {
      debugPrint('ShareService: 保存失败 - $e');
      return null;
    }
  }
}
