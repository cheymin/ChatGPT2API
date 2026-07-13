# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# CachedNetworkImage
-keep class com.bumptech.glide.** { *; }

# Play Core (Flutter referencing SplitCompatApplication)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Kotlin metadata
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }

# SharedPreferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# WebView (webview_flutter)
-keep class io.flutter.plugins.webviewflutter.** { *; }
-dontwarn android.webkit.WebView
-dontwarn android.webkit.WebSettings
-dontwarn android.webkit.CookieManager
-dontwarn android.webkit.WebViewClient
-dontwarn android.webkit.JavascriptInterface
