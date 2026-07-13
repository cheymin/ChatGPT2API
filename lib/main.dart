import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/bili_dio.dart';
import 'utils/account_manager.dart';
import 'utils/storage.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化 media_kit（libmpv 视频播放器）
  MediaKit.ensureInitialized();
  // 初始化本地存储
  await StorageService.init();
  await AccountManager.init();
  // 初始化 Dio 网络层
  await BiliDio.instance.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider()..init(),
      child: const CiliCiliApp(),
    ),
  );
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
