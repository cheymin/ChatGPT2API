import 'package:flutter/material.dart';

/// UI 风格枚举：Google Material 3 或 Apple iOS 风格
enum UiStyle { google, apple }

/// 主题提供者：管理主题模式、UI 风格、自定义主色与字体
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  UiStyle _uiStyle = UiStyle.google;
  Color? _customPrimaryColor;
  String? _customFontFamily;

  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  UiStyle get uiStyle => _uiStyle;
  set uiStyle(UiStyle style) {
    _uiStyle = style;
    notifyListeners();
  }

  Color? get customPrimaryColor => _customPrimaryColor;
  set customPrimaryColor(Color? color) {
    _customPrimaryColor = color;
    notifyListeners();
  }

  String? get customFontFamily => _customFontFamily;
  set customFontFamily(String? family) {
    _customFontFamily = family;
    notifyListeners();
  }

  bool get isGoogle => _uiStyle == UiStyle.google;
  bool get isApple => _uiStyle == UiStyle.apple;

  Future<void> init() async {
    _loadFromStorage();
  }

  void syncInit() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    // 后续可扩展：从 StorageService 读取持久化设置
  }
}

/// 主题工厂：根据 [UiStyle] 与亮度生成对应的 [ThemeData]
class AppTheme {
  AppTheme._();

  // ===== Google Material 3 颜色 =====
  static const Color googlePrimary = Color(0xFF1A73E8);
  static const Color googleSurface = Color(0xFFFEFBFF);
  static const Color googleSurfaceVariant = Color(0xFFE1E2EC);
  static const Color googleDarkSurface = Color(0xFF1B1B1F);
  static const Color googleDarkPrimary = Color(0xFFA4C8FF);

  // ===== Apple iOS 颜色 =====
  static const Color applePrimary = Color(0xFF007AFF);
  static const Color appleBackground = Color(0xFFF2F2F7);
  static const Color appleSurface = Color(0xFFFFFFFF);
  static const Color appleDarkBackground = Color(0xFF000000);
  static const Color appleDarkSurface = Color(0xFF1C1C1E);
  static const Color appleDarkPrimary = Color(0xFF0A84FF);

  // ===== 账号头像色板（9 色） =====
  static const List<Color> _accountPalette = [
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF795548),
  ];

  /// 根据字符串 hash 返回 9 色调色板中的一个颜色（用于账号头像/标识）
  static Color accountColor(String key) {
    int hash = 0;
    for (int i = 0; i < key.length; i++) {
      hash = (31 * hash + key.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return _accountPalette[hash % _accountPalette.length];
  }

  /// 格式化播放/弹幕数量（万、亿）
  /// - 12345 -> "1.2万"
  /// - 340000000 -> "3.4亿"
  static String formatCount(int count) {
    if (count < 0) return '0';
    if (count >= 100000000) {
      final v = count / 100000000;
      return '${v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}亿';
    } else if (count >= 10000) {
      final v = count / 10000;
      return '${v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  /// 格式化时长（秒）为 MM:SS 或 HH:MM:SS
  static String formatDuration(int seconds) {
    if (seconds < 0) seconds = 0;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }

  // ===================== Google Material 3 主题 =====================

  static ThemeData googleLight({Color? customPrimary, String? fontFamily}) {
    final primary = customPrimary ?? googlePrimary;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      surface: googleSurface,
      surfaceContainerHighest: googleSurfaceVariant,
    );
    return _googleFromScheme(scheme, Brightness.light, primary, fontFamily);
  }

  static ThemeData googleDark({Color? customPrimary, String? fontFamily}) {
    final primary = customPrimary ?? googleDarkPrimary;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      surface: googleDarkSurface,
    );
    return _googleFromScheme(scheme, Brightness.dark, primary, fontFamily);
  }

  static ThemeData _googleFromScheme(
    ColorScheme scheme,
    Brightness brightness,
    Color primary,
    String? fontFamily,
  ) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        color: scheme.surface,
        elevation: isDark ? 1 : 2,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: const StadiumBorder()),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: const StadiumBorder()),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: primary,
        surfaceTintColor: Colors.transparent,
        labelTextStyle:
            WidgetStateProperty.all(const TextStyle(fontSize: 12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        shape: const StadiumBorder(),
      ),
    );
  }

  // ===================== Apple iOS 风格主题 =====================

  static ThemeData appleLight({Color? customPrimary, String? fontFamily}) {
    final primary = customPrimary ?? applePrimary;
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primary,
      onSecondary: Colors.white,
      tertiary: primary,
      onTertiary: Colors.white,
      error: const Color(0xFFFF3B30),
      onError: Colors.white,
      surface: appleSurface,
      onSurface: const Color(0xFF1C1C1E),
      surfaceContainerHighest: appleBackground,
      onSurfaceVariant: const Color(0xFF3C3C43),
    );
    return _appleFromScheme(scheme, Brightness.light, primary, fontFamily);
  }

  static ThemeData appleDark({Color? customPrimary, String? fontFamily}) {
    final primary = customPrimary ?? appleDarkPrimary;
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primary,
      onSecondary: Colors.white,
      tertiary: primary,
      onTertiary: Colors.white,
      error: const Color(0xFFFF453A),
      onError: Colors.white,
      surface: appleDarkSurface,
      onSurface: Colors.white,
      surfaceContainerHighest: const Color(0xFF2C2C2E),
      onSurfaceVariant: const Color(0xFFEBEBF5),
    );
    return _appleFromScheme(scheme, Brightness.dark, primary, fontFamily);
  }

  static ThemeData _appleFromScheme(
    ColorScheme scheme,
    Brightness brightness,
    Color primary,
    String? fontFamily,
  ) {
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? appleDarkBackground : appleBackground;
    // 0.5px 发丝分割线 & 普通分割线颜色：通过 HSL 从 surface 派生
    final dividerColor = isDark
        ? _lighten(scheme.surface, 0.08)
        : _darken(scheme.surface, 0.08);
    final hairlineColor = isDark
        ? _lighten(scheme.surface, 0.12)
        : _darken(scheme.surface, 0.12);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bgColor,
      canvasColor: bgColor,
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 0.5,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
          fontFamily: fontFamily,
        ),
      ),
      cardTheme: CardTheme(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: hairlineColor, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgColor,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 56,
        labelTextStyle:
            WidgetStateProperty.all(const TextStyle(fontSize: 10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hairlineColor, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hairlineColor, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: hairlineColor, width: 0.5),
        ),
      ),
    );
  }

  // ===================== 统一入口 =====================

  /// 根据风格与亮度解析主题
  static ThemeData resolve(
    UiStyle style,
    Brightness brightness, {
    Color? customPrimary,
    String? fontFamily,
  }) {
    if (style == UiStyle.apple) {
      return brightness == Brightness.dark
          ? appleDark(customPrimary: customPrimary, fontFamily: fontFamily)
          : appleLight(customPrimary: customPrimary, fontFamily: fontFamily);
    }
    return brightness == Brightness.dark
        ? googleDark(customPrimary: customPrimary, fontFamily: fontFamily)
        : googleLight(customPrimary: customPrimary, fontFamily: fontFamily);
  }

  // ===================== HSL 颜色工具 =====================

  /// 通过 HSL 提亮颜色（amount 范围 0.0 ~ 1.0）
  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// 通过 HSL 加深颜色（amount 范围 0.0 ~ 1.0）
  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
