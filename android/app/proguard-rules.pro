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
