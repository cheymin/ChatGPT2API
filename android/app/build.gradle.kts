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

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "5"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "3.0.0"

// ===== 签名配置：从 keystore.properties 读取，找不到则用默认值 =====
val keystoreProperties = Properties().apply {
    val f = rootProject.file("app/keystore.properties")
    if (f.exists()) {
        f.inputStream().use { load(it) }
    }
}

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

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: "cilicili"
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: "CiliCili2026"
            storeFile = file("cilicili.jks")
            storePassword = keystoreProperties.getProperty("storePassword") ?: "CiliCili2026"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
