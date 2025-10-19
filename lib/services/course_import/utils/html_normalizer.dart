import 'dart:convert';

/// 将 WebView 或后端导出的 HTML 字符串标准化。
/// - 处理 JSON 字面量包装（例如 `"..."`）；
/// - 还原 `\u003C`、`\u003E` 等编码；
/// - 清理多余的转义符。
String normalizeHtml(String raw) {
  var result = raw.trim();
  if (result.isEmpty) {
    return result;
  }

  // 尝试解析 JSON 字符串包装。
  if (_looksLikeJsonString(result)) {
    try {
      final decoded = jsonDecode(result);
      if (decoded is String) {
        result = decoded;
      }
    } on FormatException {
      // 忽略，继续使用原值。
    }
  }

  // 处理常见的字符编码。
  result = result
      .replaceAll(r'\u003C', '<')
      .replaceAll(r'\u003E', '>')
      .replaceAll(r'\u0026', '&')
      .replaceAll(r'\u0027', '\'')
      .replaceAll(r'\u0022', '"');

  // 去掉重复的转义。
  result = result.replaceAll(r'\"', '"').replaceAll(r"\'", "'");
  return result;
}

bool _looksLikeJsonString(String value) {
  if (value.length < 2) return false;
  final first = value[0];
  final last = value[value.length - 1];
  return (first == '"' && last == '"') || (first == "'" && last == "'");
}
