plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.socialgeniex.ringsort"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.socialgeniex.ringsort"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Keystore: android/keystore/release.jks (generated for this app).
            // NOTE: passwords are build-local; keep the keystore file backed up.
            storeFile = file("../keystore/release.jks")
            storePassword = "ringsort2026"
            keyAlias = "ringsort"
            keyPassword = "ringsort2026"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/**",
                "**/LICENSE.txt",
                "**/NOTICE.txt",
                "commonMain/**",
                "nativeMain/**",
                "**/manifest",
                "**/*.knm",
                "**/*.kexe"
            )
        }
        jniLibs {
            pickFirsts += setOf("**/libc++_shared.so")
        }
    }

}

configurations.all {
    exclude(group = "androidx.datastore", module = "datastore-core-jvm")
}

flutter {
    source = "../.."
}
