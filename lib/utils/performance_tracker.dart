import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Firebase Performance Monitoring 工具类
/// 用于跟踪应用关键操作的性能
class PerformanceTracker {
  // 单例模式
  PerformanceTracker._();
  static final PerformanceTracker _instance = PerformanceTracker._();
  static PerformanceTracker get instance => _instance;

  FirebasePerformance? _performance;

  FirebasePerformance? get performance {
    // 懒加载，仅在 Firebase 已初始化时获取实例
    if (_performance == null) {
      try {
        if (Firebase.apps.isNotEmpty) {
          _performance = FirebasePerformance.instance;
        }
      } catch (e) {
        debugPrint('⚠️ [Performance] Firebase 未初始化，性能监控已禁用');
      }
    }
    return _performance;
  }

  // 是否启用性能监控（需要 Firebase 已初始化且在 release 模式下）
  bool get isEnabled => kReleaseMode && performance != null;

  /// 开始自定义跟踪
  /// [name] 跟踪名称，建议使用清晰的命名规范，如：load_courses, save_settings
  Future<Trace?> startTrace(String name) async {
    if (!isEnabled || performance == null) {
      debugPrint('⏱️ [Performance] $name (跟踪已禁用)');
      return null;
    }

    try {
      final trace = performance!.newTrace(name);
      await trace.start();
      debugPrint('⏱️ [Performance] 开始跟踪: $name');
      return trace;
    } catch (e) {
      debugPrint('❌ [Performance] 启动跟踪失败: $name - $e');
      return null;
    }
  }

  /// 停止跟踪
  Future<void> stopTrace(Trace? trace, [String? traceName]) async {
    if (trace == null) return;

    try {
      await trace.stop();
      if (traceName != null) {
        debugPrint('✅ [Performance] 停止跟踪: $traceName');
      } else {
        debugPrint('✅ [Performance] 跟踪已停止');
      }
    } catch (e) {
      debugPrint('❌ [Performance] 停止跟踪失败: $e');
    }
  }

  /// 为跟踪添加自定义指标
  /// [trace] 跟踪实例
  /// [metricName] 指标名称
  /// [value] 指标值
  void addMetric(Trace? trace, String metricName, int value) {
    if (trace == null) return;

    try {
      trace.setMetric(metricName, value);
      debugPrint('📊 [Performance] 添加指标: $metricName = $value');
    } catch (e) {
      debugPrint('❌ [Performance] 添加指标失败: $e');
    }
  }

  /// 为跟踪添加自定义属性
  /// [trace] 跟踪实例
  /// [attributeName] 属性名称
  /// [value] 属性值
  void addAttribute(Trace? trace, String attributeName, String value) {
    if (trace == null) return;

    try {
      trace.putAttribute(attributeName, value);
      debugPrint('🏷️ [Performance] 添加属性: $attributeName = $value');
    } catch (e) {
      debugPrint('❌ [Performance] 添加属性失败: $e');
    }
  }

  /// 便捷方法：执行带性能跟踪的异步操作
  /// [traceName] 跟踪名称
  /// [operation] 要执行的异步操作
  /// [attributes] 自定义属性（可选）
  /// [onComplete] 完成时的回调，可用于添加指标（可选）
  Future<T> traceAsync<T>({
    required String traceName,
    required Future<T> Function() operation,
    Map<String, String>? attributes,
    void Function(Trace trace, T result)? onComplete,
  }) async {
    final trace = await startTrace(traceName);

    // 添加自定义属性
    if (attributes != null && trace != null) {
      attributes.forEach((key, value) {
        addAttribute(trace, key, value);
      });
    }

    try {
      final result = await operation();

      // 执行完成回调（可用于添加指标）
      if (onComplete != null && trace != null) {
        onComplete(trace, result);
      }

      return result;
    } catch (e) {
      // 记录错误
      if (trace != null) {
        addAttribute(trace, 'error', e.toString());
      }
      rethrow;
    } finally {
      await stopTrace(trace, traceName);
    }
  }

  /// 便捷方法：执行带性能跟踪的同步操作
  /// [traceName] 跟踪名称
  /// [operation] 要执行的同步操作
  /// [attributes] 自定义属性（可选）
  /// [onComplete] 完成时的回调，可用于添加指标（可选）
  Future<T> traceSync<T>({
    required String traceName,
    required T Function() operation,
    Map<String, String>? attributes,
    void Function(Trace trace, T result)? onComplete,
  }) async {
    final trace = await startTrace(traceName);

    // 添加自定义属性
    if (attributes != null && trace != null) {
      attributes.forEach((key, value) {
        addAttribute(trace, key, value);
      });
    }

    try {
      final result = operation();

      // 执行完成回调（可用于添加指标）
      if (onComplete != null && trace != null) {
        onComplete(trace, result);
      }

      return result;
    } catch (e) {
      // 记录错误
      if (trace != null) {
        addAttribute(trace, 'error', e.toString());
      }
      rethrow;
    } finally {
      await stopTrace(trace, traceName);
    }
  }

  /// 设置性能监控是否启用
  /// 注意：这只影响数据收集，不影响性能
  Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    if (performance == null) {
      debugPrint('⚠️ [Performance] Firebase 未初始化，无法设置性能数据收集');
      return;
    }

    try {
      await performance!.setPerformanceCollectionEnabled(enabled);
      debugPrint('📊 [Performance] 性能数据收集: ${enabled ? "已启用" : "已禁用"}');
    } catch (e) {
      debugPrint('❌ [Performance] 设置性能数据收集失败: $e');
    }
  }

  /// 创建 HTTP 请求跟踪
  /// [url] 请求 URL
  /// [method] HTTP 方法（GET, POST 等）
  Future<HttpMetric?> createHttpMetric(
    String url,
    HttpMethod method,
  ) async {
    if (!isEnabled || performance == null) {
      debugPrint('🌐 [Performance] HTTP 请求跟踪已禁用');
      return null;
    }

    try {
      final metric = performance!.newHttpMetric(url, method);
      debugPrint('🌐 [Performance] 创建 HTTP 跟踪: $method $url');
      return metric;
    } catch (e) {
      debugPrint('❌ [Performance] 创建 HTTP 跟踪失败: $e');
      return null;
    }
  }

  /// 便捷方法：跟踪 HTTP 请求
  Future<T> traceHttpRequest<T>({
    required String url,
    required HttpMethod method,
    required Future<T> Function() request,
    Map<String, String>? attributes,
  }) async {
    final metric = await createHttpMetric(url, method);

    if (metric != null) {
      // 添加自定义属性
      if (attributes != null) {
        attributes.forEach((key, value) {
          metric.putAttribute(key, value);
        });
      }

      await metric.start();
    }

    try {
      final result = await request();

      // 设置响应成功
      if (metric != null) {
        metric.httpResponseCode = 200;
      }

      return result;
    } catch (e) {
      // 设置响应失败
      if (metric != null) {
        metric.httpResponseCode = 500;
      }
      rethrow;
    } finally {
      await metric?.stop();
    }
  }
}

// 常用的跟踪名称常量
class PerformanceTraces {
  // 课程相关
  static const String loadCourses = 'load_courses';
  static const String saveCourses = 'save_courses';
  static const String addCourse = 'add_course';
  static const String updateCourse = 'update_course';
  static const String deleteCourse = 'delete_course';

  // 设置相关
  static const String loadSettings = 'load_semester_settings';
  static const String saveSettings = 'save_semester_settings';

  // 时间表相关
  static const String loadTimeTables = 'load_time_tables';
  static const String saveTimeTables = 'save_time_tables';
  static const String getActiveTimeTable = 'get_active_time_table';

  // UI 相关
  static const String renderCourseTable = 'render_course_table';
  static const String openCourseDetail = 'open_course_detail';
  static const String openCourseEdit = 'open_course_edit';

  // 数据导入导出
  static const String exportConfig = 'export_config';
  static const String importConfig = 'import_config';
  static const String backupToCloud = 'backup_to_cloud';
  static const String restoreFromCloud = 'restore_from_cloud';
  static const String listCloudBackups = 'list_cloud_backups';
  static const String deleteCloudBackup = 'delete_cloud_backup';
  static const String previewCloudBackup = 'preview_cloud_backup';
  static const String testCloudConnection = 'test_cloud_connection';
}
