import 'package:flutter_test/flutter_test.dart';
import 'package:curriculum/utils/performance_tracker.dart';

void main() {
  group('PerformanceTracker Tests', () {
    setUp(() {
      // 测试环境中 Firebase 通常未初始化
    });

    group('Firebase 未启用时的行为', () {
      test('Firebase 未启用时 isEnabled 返回 false', () {
        // Given
        final tracker = PerformanceTracker.instance;

        // Then - 测试环境和 debug 模式下应该禁用
        expect(tracker.isEnabled, isFalse,
            reason: '测试环境下性能跟踪应该禁用');
      });

      test('Firebase 未启用时 startTrace 返回 null 且不崩溃', () async {
        // Given
        final tracker = PerformanceTracker.instance;

        // When
        final trace = await tracker.startTrace('test_trace');

        // Then
        expect(trace, isNull, reason: 'Firebase 未启用时应返回 null');
      });

      test('Firebase 未启用时 stopTrace 不崩溃', () async {
        // Given
        final tracker = PerformanceTracker.instance;

        // When & Then - 不应抛出异常
        expect(
          () async => await tracker.stopTrace(null, 'test_trace'),
          returnsNormally,
          reason: '传入 null trace 应该安全处理',
        );
      });

      test('Firebase 未启用时 addMetric 不崩溃', () {
        // Given
        final tracker = PerformanceTracker.instance;

        // When & Then - 不应抛出异常
        expect(
          () => tracker.addMetric(null, 'test_metric', 100),
          returnsNormally,
          reason: '传入 null trace 应该安全处理',
        );
      });

      test('Firebase 未启用时 addAttribute 不崩溃', () {
        // Given
        final tracker = PerformanceTracker.instance;

        // When & Then - 不应抛出异常
        expect(
          () => tracker.addAttribute(null, 'test_attr', 'value'),
          returnsNormally,
          reason: '传入 null trace 应该安全处理',
        );
      });
    });

    group('traceAsync 方法', () {
      test('traceAsync - 成功执行异步操作（Firebase 未启用）', () async {
        // Given
        final tracker = PerformanceTracker.instance;
        int executionCount = 0;

        // When
        final result = await tracker.traceAsync(
          traceName: 'test_async',
          operation: () async {
            executionCount++;
            await Future.delayed(const Duration(milliseconds: 10));
            return 'success';
          },
        );

        // Then
        expect(result, equals('success'));
        expect(executionCount, equals(1), reason: '操作应该被执行一次');
      });

      test('traceAsync - 带属性执行（Firebase 未启用）', () async {
        // Given
        final tracker = PerformanceTracker.instance;

        // When
        final result = await tracker.traceAsync(
          traceName: 'test_async_with_attrs',
          operation: () async => 42,
          attributes: {
            'user_id': '123',
            'screen': 'home',
          },
        );

        // Then
        expect(result, equals(42));
      });

      test('traceAsync - 带完成回调执行（Firebase 未启用）', () async {
        // Given
        final tracker = PerformanceTracker.instance;
        bool callbackExecuted = false;

        // When
        final result = await tracker.traceAsync(
          traceName: 'test_async_with_callback',
          operation: () async => [1, 2, 3],
          onComplete: (trace, result) {
            callbackExecuted = true;
            // 在真实场景中，这里会添加指标
            // tracker.addMetric(trace, 'item_count', result.length);
          },
        );

        // Then
        expect(result, equals([1, 2, 3]));
        // 注意：由于 trace 是 null，callback 应该被跳过
        expect(callbackExecuted, isFalse,
            reason: 'Firebase 未启用时 callback 应该被跳过');
      });

      test('traceAsync - 操作失败时重新抛出异常', () async {
        // Given
        final tracker = PerformanceTracker.instance;

        // When & Then
        expect(
          () => tracker.traceAsync(
            traceName: 'test_async_error',
            operation: () async {
              throw Exception('Test error');
            },
          ),
          throwsException,
          reason: '应该重新抛出操作中的异常',
        );
      });
    });

    group('traceSync 方法', () {
      test('traceSync - 成功执行同步操作（Firebase 未启用）', () async {
        // Given
        final tracker = PerformanceTracker.instance;
        int executionCount = 0;

        // When
        final result = await tracker.traceSync(
          traceName: 'test_sync',
          operation: () {
            executionCount++;
            return 'sync_success';
          },
        );

        // Then
        expect(result, equals('sync_success'));
        expect(executionCount, equals(1), reason: '操作应该被执行一次');
      });

      test('traceSync - 带属性执行（Firebase 未启用）', () async {
        // Given
        final tracker = PerformanceTracker.instance;

        // When
        final result = await tracker.traceSync(
          traceName: 'test_sync_with_attrs',
          operation: () => 100,
          attributes: {
            'operation_type': 'calculation',
          },
        );

        // Then
        expect(result, equals(100));
      });

      test('traceSync - 操作失败时重新抛出异常', () async {
        // Given
        final tracker = PerformanceTracker.instance;

        // When & Then
        expect(
          () => tracker.traceSync(
            traceName: 'test_sync_error',
            operation: () {
              throw StateError('Test sync error');
            },
          ),
          throwsStateError,
          reason: '应该重新抛出操作中的异常',
        );
      });
    });

    group('单例模式', () {
      test('instance 返回相同的实例', () {
        // When
        final instance1 = PerformanceTracker.instance;
        final instance2 = PerformanceTracker.instance;

        // Then
        expect(identical(instance1, instance2), isTrue,
            reason: '应该返回相同的单例实例');
      });
    });

    group('性能跟踪名称常量', () {
      test('PerformanceTraces 定义了常用的跟踪名称', () {
        // Then - 验证关键的跟踪名称常量存在
        expect(PerformanceTraces.loadCourses, equals('load_courses'));
        expect(PerformanceTraces.saveCourses, equals('save_courses'));
        expect(PerformanceTraces.loadSettings, equals('load_semester_settings'));
        expect(PerformanceTraces.exportConfig, equals('export_config'));
        expect(PerformanceTraces.importConfig, equals('import_config'));
      });

      test('所有跟踪名称使用 snake_case 命名', () {
        // Then - 验证命名规范
        final traceNames = [
          PerformanceTraces.loadCourses,
          PerformanceTraces.saveCourses,
          PerformanceTraces.addCourse,
          PerformanceTraces.updateCourse,
          PerformanceTraces.deleteCourse,
          PerformanceTraces.loadSettings,
          PerformanceTraces.saveSettings,
          PerformanceTraces.loadTimeTables,
          PerformanceTraces.saveTimeTables,
          PerformanceTraces.getActiveTimeTable,
          PerformanceTraces.renderCourseTable,
          PerformanceTraces.openCourseDetail,
          PerformanceTraces.openCourseEdit,
          PerformanceTraces.exportConfig,
          PerformanceTraces.importConfig,
          PerformanceTraces.backupToCloud,
          PerformanceTraces.restoreFromCloud,
          PerformanceTraces.listCloudBackups,
          PerformanceTraces.deleteCloudBackup,
          PerformanceTraces.previewCloudBackup,
          PerformanceTraces.testCloudConnection,
        ];

        for (final name in traceNames) {
          expect(
            name,
            matches(RegExp(r'^[a-z][a-z0-9_]*$')),
            reason: '跟踪名称应该使用 snake_case 格式: $name',
          );
        }
      });
    });

    group('集成测试场景', () {
      test('traceAsync - 模拟课程加载场景', () async {
        // Given
        final tracker = PerformanceTracker.instance;

        // When - 模拟课程加载
        final courses = await tracker.traceAsync(
          traceName: PerformanceTraces.loadCourses,
          operation: () async {
            // 模拟从存储加载
            await Future.delayed(const Duration(milliseconds: 50));
            return ['数学', '英语', '物理'];
          },
          attributes: {
            'source': 'local_storage',
            'semester_id': 'sem_2024_1',
          },
          onComplete: (trace, result) {
            // 在真实场景中会添加课程数量指标
            // tracker.addMetric(trace, 'course_count', result.length);
          },
        );

        // Then
        expect(courses, hasLength(3));
        expect(courses, contains('数学'));
      });

      test('traceAsync - 模拟数据导出场景', () async {
        // Given
        final tracker = PerformanceTracker.instance;

        // When - 模拟数据导出
        final exported = await tracker.traceAsync(
          traceName: PerformanceTraces.exportConfig,
          operation: () async {
            // 模拟数据序列化
            await Future.delayed(const Duration(milliseconds: 30));
            return {'courses': [], 'semesters': [], 'timeTables': []};
          },
          attributes: {
            'format': 'json',
            'include_courses': 'true',
            'include_semesters': 'true',
          },
        );

        // Then
        expect(exported, isA<Map<String, dynamic>>());
        expect(exported.keys, hasLength(3));
      });

      test('traceAsync - 模拟错误处理场景', () async {
        // Given
        final tracker = PerformanceTracker.instance;
        bool errorCaught = false;

        // When & Then
        try {
          await tracker.traceAsync(
            traceName: PerformanceTraces.backupToCloud,
            operation: () async {
              await Future.delayed(const Duration(milliseconds: 20));
              throw Exception('Network error');
            },
            attributes: {
              'destination': 'webdav',
            },
          );
        } catch (e) {
          errorCaught = true;
          expect(e.toString(), contains('Network error'));
        }

        expect(errorCaught, isTrue, reason: '应该捕获到异常');
      });
    });

    group('性能测试', () {
      test('traceAsync - 批量操作性能', () async {
        // Given
        final tracker = PerformanceTracker.instance;
        final stopwatch = Stopwatch()..start();

        // When - 执行100次跟踪操作
        for (int i = 0; i < 100; i++) {
          await tracker.traceAsync(
            traceName: 'perf_test_$i',
            operation: () async => i,
          );
        }

        stopwatch.stop();

        // Then - 应该在合理时间内完成（100ms）
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: '100次跟踪操作应在100ms内完成',
        );
      });

      test('traceSync - 同步操作性能', () async {
        // Given
        final tracker = PerformanceTracker.instance;
        final stopwatch = Stopwatch()..start();

        // When - 执行100次同步跟踪操作
        for (int i = 0; i < 100; i++) {
          await tracker.traceSync(
            traceName: 'perf_test_sync_$i',
            operation: () => i * 2,
          );
        }

        stopwatch.stop();

        // Then - 应该在合理时间内完成（50ms）
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(50),
          reason: '100次同步跟踪操作应在50ms内完成',
        );
      });
    });
  });
}
