import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "2"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "2.0.0"
val engineVersion = localProperties.getProperty("flutter.engineVersion") ?: ""

android {
    namespace = "com.cheymin.cilicili"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
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

// 显式添加 Flutter Maven 仓库
repositories {
    maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
}

// 直接在构建脚本顶层添加 embedding 依赖（不用 afterEvaluate，确保在任务配置前生效）
dependencies {
    if (engineVersion.isNotEmpty()) {
        "releaseApi"("io.flutter:flutter_embedding_release:1.0.0-$engineVersion")
        "debugApi"("io.flutter:flutter_embedding_debug:1.0.0-$engineVersion")
        println("CiliCili: Added Flutter embedding dependency with engine version: $engineVersion")
    } else {
        println("CiliCili: WARNING - flutter.engineVersion not set in local.properties!")
    }
}

flutter {
    source = "../.."
}
