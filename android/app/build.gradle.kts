plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

flutter {
    source = "../.."
}

//
// 👉 Force desugar_jdk_libs 2.1.4 everywhere in this module
//
configurations.all {
    resolutionStrategy.force("com.android.tools:desugar_jdk_libs:2.1.4")
}

android {
    namespace = "com.example.notify_app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.notify_app"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // Debug should never shrink
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Keep minify off (no code shrinking), so we must also keep resource shrinking off
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    packagingOptions {
        resources.excludes += "/META-INF/{LICENSE*,NOTICE*,AL2.0,LGPL2.1}"
    }
}

dependencies {
    // ✅ Must be 2.1.4 or newer
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Do NOT add raw Firebase implementations here; FlutterFire manages them.
}
