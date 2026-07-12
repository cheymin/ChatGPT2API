import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "2"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "2.0.0"

// 读取 Flutter 引擎版本
val flutterSdkPath = localProperties.getProperty("flutter.sdk") ?: ""
val engineVersionFile = file("$flutterSdkPath/bin/cache/engine.stamp")
val engineVersion = if (engineVersionFile.exists()) engineVersionFile.readText().trim() else ""

android {
    namespace = "com.cheymin.cilicili"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin", "src/main/java")
        }
    }

    defaultConfig {
        applicationId = "com.cheymin.cilicili"
        minSdk = 21
        targetSdk = 34
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// Flutter 引擎 Maven 仓库
repositories {
    maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
}

// 显式添加 Flutter embedding 依赖（确保 FlutterActivity 可被编译）
dependencies {
    if (engineVersion.isNotEmpty()) {
        "releaseImplementation"("io.flutter:flutter_embedding_release:1.0.0-$engineVersion")
        "debugImplementation"("io.flutter:flutter_embedding_debug:1.0.0-$engineVersion")
    }
}

flutter {
    source = "../.."
}
