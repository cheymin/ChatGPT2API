import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/bili_dio.dart';
import 'utils/account_manager.dart';
import 'utils/storage.dart';
import 'utils/theme.dart';

void main() {
  _registerErrorHandlers();

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await _safeInit();

    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider()..syncInit(),
        child: const CiliCiliApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    debugPrint('🚨 Zone Error: $error\n$stack');
  });
}

void _registerErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 FlutterError: ${details.exceptionAsString()}');
    debugPrint(details.stack?.toString() ?? '');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('🚨 PlatformError: $error\n$stack');
    return true;
  };
}

Future<void> _safeInit() async {
  try {
    await StorageService.init();
  } catch (e, s) {
    debugPrint('⚠️ StorageService.init failed: $e\n$s');
  }

  try {
    await AccountManager.init();
  } catch (e, s) {
    debugPrint('⚠️ AccountManager.init failed: $e\n$s');
  }

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } catch (e, s) {
    debugPrint('⚠️ setPreferredOrientations failed: $e\n$s');
  }
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
      home: const HomeScreen(),
    );
  }
}
