import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/course_table_page.dart';
import 'services/app_theme_service.dart';
import 'services/firebase_init_service.dart';
import 'services/firebase_consent_service.dart';
import 'utils/material_icon_loader.dart';
import 'widgets/firebase_consent_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 条件初始化 Firebase（根据用户同意）
  await FirebaseInitService.initialize();

  await MaterialIconLoader.ensureLoaded();
  final initialThemeMode = await AppThemeService.loadThemeMode();
  runApp(MyApp(initialThemeMode: initialThemeMode));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialThemeMode = ThemeMode.system});

  final ThemeMode initialThemeMode;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeMode = widget.initialThemeMode;
    _updateSystemUiOverlay();
    _checkFirebaseConsent();
  }

  /// 检查是否需要显示 Firebase 同意对话框
  Future<void> _checkFirebaseConsent() async {
    final consent = await FirebaseConsentService.loadConsent();

    // 如果已经显示过对话框，不再显示
    if (consent.hasShown) {
      return;
    }

    // 延迟显示对话框，确保 UI 已经构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await FirebaseConsentDialog.show(context);
    });
  }

  void _onThemeModeChanged(ThemeMode mode) {
    if (mode == _themeMode) {
      return;
    }
    setState(() {
      _themeMode = mode;
      _updateSystemUiOverlay();
    });
    AppThemeService.saveThemeMode(mode);
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (_themeMode == ThemeMode.system) {
      _updateSystemUiOverlay();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _updateSystemUiOverlay() {
    final isDark = switch (_themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '课程表',
      debugShowCheckedModeBanner: false,
      // 添加本地化支持
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'), // 中文简体
        Locale('en', 'US'), // 英文
      ],
      locale: const Locale('zh', 'CN'), // 默认使用中文
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6BA3FF)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          contentTextStyle: TextStyle(fontSize: 14),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF335CFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          contentTextStyle: TextStyle(fontSize: 14),
        ),
      ),
      themeMode: _themeMode,
      home: CourseTablePage(
        themeMode: _themeMode,
        onThemeModeChanged: _onThemeModeChanged,
      ),
    );
  }
}
