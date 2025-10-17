/// Web 平台文件下载工具类
/// 使用条件导入在不同平台加载不同实现
///
/// - Web 平台: 使用 web_file_utils_web.dart (依赖 dart:js_interop 和 package:web)
/// - 其他平台: 使用 web_file_utils_stub.dart (桩实现,抛出 UnsupportedError)
library;

export 'web_file_utils_stub.dart'
    if (dart.library.js_interop) 'web_file_utils_web.dart';
