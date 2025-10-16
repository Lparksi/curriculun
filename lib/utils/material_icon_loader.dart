import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 手动预加载 Material Icons 字体，避免部分平台加载失败导致图标缺失。
@immutable
class MaterialIconLoader {
  const MaterialIconLoader._();

  static bool _loaded = false;

  /// 确保 Material Icons 字体已注册。
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final loader = FontLoader(_fontFamily)
      ..addFont(rootBundle.load(_fontAssetPath));
    await loader.load();
    _loaded = true;
  }

  static const String _fontFamily = 'MaterialIcons';
  static const String _fontAssetPath = 'assets/fonts/MaterialIcons-Regular.otf';
}
