plugins {
    id("com.android.application")
    // Firebase plugin 연결 (Phase 3)
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // applicationId와 일치하도록 namespace 변경 (Firebase/Android 일관성)
    namespace = "com.silversr.appforge"
    compileSdk = flutter.compileSdkVersion
    // Firebase plugin 요구 (NDK mismatch 방지)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // 앱 고유 applicationId 설정 완료
        applicationId = "com.silversr.appforge"
        // Firebase Auth 요구사항
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
