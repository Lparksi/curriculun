import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curriculum/services/settings_service.dart';
import 'package:curriculum/models/semester_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService', () {
    setUp(() async {
      // 重置 SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    // ========== 学期管理测试 (6个) ==========
    group('学期管理', () {
      test('getAllSemesters - 首次加载返回默认学期', () async {
        // Given: 空的本地存储
        SharedPreferences.setMockInitialValues({});

        // When: 获取所有学期
        final semesters = await SettingsService.getAllSemesters();

        // Then: 返回包含默认学期的列表
        expect(semesters, hasLength(1));
        expect(semesters[0].name, equals('默认学期'));
      });

      test('getAllSemesters - 加载已保存的学期列表', () async {
        // Given: 已保存的学期数据
        final semester1 = SemesterSettings(
          id: 'test_semester_1',
          name: '2024秋季学期',
          startDate: DateTime(2024, 9, 1),
          totalWeeks: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final semester2 = SemesterSettings(
          id: 'test_semester_2',
          name: '2025春季学期',
          startDate: DateTime(2025, 3, 1),
          totalWeeks: 18,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await SettingsService.addSemester(semester1);
        await SettingsService.addSemester(semester2);

        // When: 重新获取
        final semesters = await SettingsService.getAllSemesters();

        // Then: 正确加载所有学期
        expect(semesters.length, greaterThanOrEqualTo(2));
        expect(
          semesters.any((s) => s.name == '2024秋季学期'),
          isTrue,
        );
        expect(
          semesters.any((s) => s.name == '2025春季学期'),
          isTrue,
        );
      });

      test('addSemester - 成功添加新学期', () async {
        // Given: 空的学期列表
        SharedPreferences.setMockInitialValues({});

        final newSemester = SemesterSettings(
          id: 'new_semester',
          name: '新学期',
          startDate: DateTime(2025, 9, 1),
          totalWeeks: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // When: 添加新学期
        await SettingsService.addSemester(newSemester);

        // Then: 学期已保存
        final semesters = await SettingsService.getAllSemesters();
        expect(
          semesters.any((s) => s.name == '新学期'),
          isTrue,
        );
      });

      test('updateSemester - 更新学期信息', () async {
        // Given: 已有学期
        final originalSemester = SemesterSettings(
          id: 'test_semester',
          name: '原始学期',
          startDate: DateTime(2024, 9, 1),
          totalWeeks: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await SettingsService.addSemester(originalSemester);

        // When: 更新学期信息
        final updatedSemester = originalSemester.copyWith(
          name: '更新后学期',
          totalWeeks: 18,
        );

        await SettingsService.updateSemester(updatedSemester);

        // Then: 学期信息已更新
        final semesters = await SettingsService.getAllSemesters();
        final found = semesters.firstWhere((s) => s.id == 'test_semester');
        expect(found.name, equals('更新后学期'));
        expect(found.totalWeeks, equals(18));
      });

      test('deleteSemester - 删除学期', () async {
        // Given: 多个学期
        final semester1 = SemesterSettings(
          id: 'semester_1',
          name: '学期1',
          startDate: DateTime(2024, 9, 1),
          totalWeeks: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final semester2 = SemesterSettings(
          id: 'semester_2',
          name: '学期2',
          startDate: DateTime(2025, 3, 1),
          totalWeeks: 18,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await SettingsService.addSemester(semester1);
        await SettingsService.addSemester(semester2);

        // When: 删除第一个学期
        final deleted = await SettingsService.deleteSemester('semester_1');

        // Then: 删除成功
        expect(deleted, isTrue);

        final semesters = await SettingsService.getAllSemesters();
        expect(
          semesters.any((s) => s.id == 'semester_1'),
          isFalse,
        );
        expect(
          semesters.any((s) => s.id == 'semester_2'),
          isTrue,
        );
      });

      test('deleteSemester - 不允许删除唯一的学期', () async {
        // Given: 只有一个学期
        SharedPreferences.setMockInitialValues({});
        final semesters = await SettingsService.getAllSemesters();
        expect(semesters, hasLength(1));

        final onlySemesterId = semesters[0].id;

        // When: 尝试删除唯一的学期
        final deleted = await SettingsService.deleteSemester(onlySemesterId);

        // Then: 删除失败
        expect(deleted, isFalse);

        // 学期仍然存在
        final remainingSemesters = await SettingsService.getAllSemesters();
        expect(remainingSemesters, hasLength(1));
      });
    });

    // ========== 激活学期测试 (4个) ==========
    group('激活学期', () {
      test('getActiveSemester - 返回当前激活的学期', () async {
        // Given: 多个学期，设置其中一个为激活
        final semester1 = SemesterSettings(
          id: 'semester_1',
          name: '学期1',
          startDate: DateTime(2024, 9, 1),
          totalWeeks: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final semester2 = SemesterSettings(
          id: 'semester_2',
          name: '学期2',
          startDate: DateTime(2025, 3, 1),
          totalWeeks: 18,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await SettingsService.addSemester(semester1);
        await SettingsService.addSemester(semester2);
        await SettingsService.setActiveSemesterId('semester_2');

        // When: 获取激活学期
        final activeSemester = await SettingsService.getActiveSemester();

        // Then: 返回正确的激活学期
        expect(activeSemester.id, equals('semester_2'));
        expect(activeSemester.name, equals('学期2'));
      });

      test('setActiveSemesterId - 设置激活学期', () async {
        // Given: 多个学期
        final semester1 = SemesterSettings(
          id: 'semester_1',
          name: '学期1',
          startDate: DateTime(2024, 9, 1),
          totalWeeks: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await SettingsService.addSemester(semester1);

        // When: 设置激活学期
        await SettingsService.setActiveSemesterId('semester_1');

        // Then: 激活学期已设置
        final activeSemesterId = await SettingsService.getActiveSemesterId();
        expect(activeSemesterId, equals('semester_1'));
      });

      test('getActiveSemester - 无激活学期时返回第一个', () async {
        // Given: 有学期但没有设置激活学期
        SharedPreferences.setMockInitialValues({});

        // When: 获取激活学期
        final activeSemester = await SettingsService.getActiveSemester();

        // Then: 返回第一个学期（默认学期）
        expect(activeSemester, isNotNull);
        expect(activeSemester.name, equals('默认学期'));

        // 并且自动设置为激活
        final activeSemesterId = await SettingsService.getActiveSemesterId();
        expect(activeSemesterId, isNotNull);
      });

      test('deleteSemester - 删除激活学期时自动切换', () async {
        // Given: 多个学期，第一个是激活的
        final semester1 = SemesterSettings(
          id: 'semester_1',
          name: '学期1',
          startDate: DateTime(2024, 9, 1),
          totalWeeks: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final semester2 = SemesterSettings(
          id: 'semester_2',
          name: '学期2',
          startDate: DateTime(2025, 3, 1),
          totalWeeks: 18,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await SettingsService.addSemester(semester1);
        await SettingsService.addSemester(semester2);
        await SettingsService.setActiveSemesterId('semester_1');

        // When: 删除激活学期
        await SettingsService.deleteSemester('semester_1');

        // Then: 自动切换到另一个学期
        final activeSemesterId = await SettingsService.getActiveSemesterId();
        expect(activeSemesterId, isNot(equals('semester_1')));
        expect(activeSemesterId, isNotNull);
      });
    });

    // ========== 数据迁移测试 (3个) 🔥 关键功能 ==========
    group('数据迁移', () {
      test('_migrateOldSettings - 成功迁移旧版单学期数据', () async {
        // Given: 旧格式的学期数据
        final oldSettings = {
          'startDate': DateTime(2024, 9, 1).toIso8601String(),
          'totalWeeks': 16,
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('semester_settings', jsonEncode(oldSettings));

        // When: 获取所有学期（触发迁移）
        final semesters = await SettingsService.getAllSemesters();

        // Then: 成功迁移
        expect(semesters, hasLength(1));
        expect(semesters[0].name, equals('已迁移学期'));
        expect(semesters[0].totalWeeks, equals(16));
        expect(
          semesters[0].startDate.year,
          equals(2024),
        );
        expect(
          semesters[0].startDate.month,
          equals(9),
        );
      });

      test('_migrateOldSettings - 迁移后删除旧数据', () async {
        // Given: 旧格式的学期数据
        final oldSettings = {
          'startDate': DateTime(2024, 9, 1).toIso8601String(),
          'totalWeeks': 16,
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('semester_settings', jsonEncode(oldSettings));

        // When: 触发迁移
        await SettingsService.getAllSemesters();

        // Then: 旧数据已删除
        final oldData = prefs.getString('semester_settings');
        expect(oldData, isNull);

        // 新数据已保存
        final newData = prefs.getString('semesters_list');
        expect(newData, isNotNull);
      });

      test('_migrateOldSettings - 迁移失败返回null（通过默认学期）', () async {
        // Given: 无效的旧数据
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('semester_settings', 'invalid json');

        // When: 尝试迁移
        final semesters = await SettingsService.getAllSemesters();

        // Then: 返回默认学期（迁移失败但不崩溃）
        expect(semesters, hasLength(1));
        expect(semesters[0].name, equals('默认学期'));
      });
    });

    // ========== 学期复制测试 (2个) ==========
    group('学期复制', () {
      test('duplicateSemester - 成功复制学期', () async {
        // Given: 已有学期
        final sourceSemester = SemesterSettings(
          id: 'source_semester',
          name: '源学期',
          startDate: DateTime(2024, 9, 1),
          totalWeeks: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await SettingsService.addSemester(sourceSemester);

        // When: 复制学期
        final duplicated =
            await SettingsService.duplicateSemester('source_semester');

        // Then: 复制成功
        expect(duplicated.name, equals('源学期 (副本)'));
        expect(duplicated.totalWeeks, equals(16));
        expect(duplicated.id, isNot(equals('source_semester')));

        // 两个学期都存在
        final semesters = await SettingsService.getAllSemesters();
        expect(
          semesters.any((s) => s.id == 'source_semester'),
          isTrue,
        );
        expect(
          semesters.any((s) => s.id == duplicated.id),
          isTrue,
        );
      });

      test('duplicateSemester - 源学期不存在时抛出异常', () async {
        // Given: 不存在的学期ID
        SharedPreferences.setMockInitialValues({});

        // When & Then: 抛出异常
        expect(
          () => SettingsService.duplicateSemester('non_existent_semester'),
          throwsException,
        );
      });
    });

    // ========== 其他功能测试 ==========
    group('其他功能', () {
      test('clearAllSemesters - 清除所有学期数据', () async {
        // Given: 已有学期数据
        final semester = SemesterSettings(
          id: 'test_semester',
          name: '测试学期',
          startDate: DateTime(2024, 9, 1),
          totalWeeks: 16,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await SettingsService.addSemester(semester);
        await SettingsService.setActiveSemesterId('test_semester');

        // When: 清除所有数据
        await SettingsService.clearAllSemesters();

        // Then: 数据已清除
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('semesters_list'), isNull);
        expect(prefs.getString('active_semester_id'), isNull);
        expect(prefs.getString('semester_settings'), isNull);
      });

      test('generateSemesterId - 生成唯一ID', () async {
        // When: 生成多个ID（添加延迟确保时间戳不同）
        final id1 = SettingsService.generateSemesterId();
        await Future.delayed(const Duration(milliseconds: 10));
        final id2 = SettingsService.generateSemesterId();

        // Then: ID不同
        expect(id1, isNot(equals(id2)));
        expect(id1, startsWith('semester_'));
        expect(id2, startsWith('semester_'));
      });
    });
  });
}
