import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/bili_dio.dart';
import 'utils/account_manager.dart';
import 'utils/storage.dart';
import 'utils/theme.dart';

/// 全局错误捕获：避免任何未捕获的同步/异步异常导致 App 闪退
void _registerErrorHandlers() {
  // Flutter 框架错误（Widget 构建异常等）
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 FlutterError: ${details.exceptionAsString()}');
    debugPrint(details.stack?.toString() ?? '');
  };

  // Dart isolate 外抛出的异步错误
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('🚨 PlatformError: $error\n$stack');
    return true; // true = 已处理，不要崩溃
  };
}

Future<void> _bootstrap() async {
  // 必须最先调用
  WidgetsFlutterBinding.ensureInitialized();

  // 本地存储（失败也不阻塞，只是没缓存）
  try {
    await StorageService.init();
  } catch (e, s) {
    debugPrint('⚠️ StorageService.init 失败: $e\n$s');
  }

  // 多账号管理器（依赖 SharedPreferences，单独初始化以容错）
  try {
    await AccountManager.init();
  } catch (e, s) {
    debugPrint('⚠️ AccountManager.init 失败: $e\n$s');
  }

  // media_kit 初始化（libmpv）。失败也允许继续，视频详情页会回退到占位 UI
  try {
    MediaKit.ensureInitialized();
  } catch (e, s) {
    debugPrint('⚠️ MediaKit.ensureInitialized 失败: $e\n$s');
  }

  // Dio 网络层初始化。失败也允许继续，网络请求会按需兜底
  try {
    await BiliDio.instance.init();
  } catch (e, s) {
    debugPrint('⚠️ BiliDio.init 失败: $e\n$s');
  }
}

void main() {
  _registerErrorHandlers();

  // runZonedGuarded：捕获所有未处理的异步错误，防闪退
  runZonedGuarded<Future<void>>(() async {
    await _bootstrap();

    // 方向：默认不强制，让用户自由旋转（电视系统默认就是横屏）
    // 之前强制 landscapeLeft/landscapeRight 会导致部分电视/平板方向异常崩溃
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (e, s) {
      debugPrint('⚠️ setPreferredOrientations 失败: $e\n$s');
    }

    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider()..init(),
        child: const CiliCiliApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    debugPrint('🚨 Zone Error: $error\n$stack');
  });
}

class CiliCiliApp extends StatelessWidget {
  const CiliCiliApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'CiliCili',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.resolve(
        themeProvider.uiStyle,
        Brightness.light,
        customPrimary: themeProvider.customPrimaryColor,
        fontFamily: themeProvider.customFontFamily,
      ),
      darkTheme: AppTheme.resolve(
        themeProvider.uiStyle,
        Brightness.dark,
        customPrimary: themeProvider.customPrimaryColor,
        fontFamily: themeProvider.customFontFamily,
      ),
      themeMode: themeProvider.themeMode,
      // 启动时显示一个简单的加载占位，避免黑屏被系统误判崩溃
      builder: (context, child) {
        return Material(
          child: child ?? const _SplashFallback(),
        );
      },
      home: const HomeScreen(),
    );
  }
}

/// 启动加载占位（极简，避免任何依赖导致再次闪退）
class _SplashFallback extends StatelessWidget {
  const _SplashFallback();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
