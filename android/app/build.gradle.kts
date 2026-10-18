import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "co.trackfree.solforge"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    val storeFilePath = keystoreProperties.getProperty("storeFile")
    val resolvedStoreFile = if (storeFilePath != null) rootProject.file(storeFilePath) else null
    val hasValidKeystore = keystorePropertiesFile.exists() && resolvedStoreFile != null && resolvedStoreFile.exists()

    signingConfigs {
        create("release") {
            if (hasValidKeystore) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = resolvedStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "co.trackfree.solforge"
        minSdk = 28 // Android 9+
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // A release signed with the debug key can't be uploaded to Play (or worse,
    // gets uploaded under the wrong key), so release builds fail without the
    // upload keystore. For a local-only test build, opt in explicitly with
    // `flutter build apk --release -P allowDebugSigning=true`
    // (never use it for a build you upload).
    val allowDebugSigning = (project.findProperty("allowDebugSigning") as String?) == "true"
    gradle.taskGraph.whenReady {
        val buildsRelease = allTasks.any { task ->
            task.project == project &&
                (task.name.startsWith("assemble") || task.name.startsWith("bundle")) &&
                task.name.endsWith("Release")
        }
        if (buildsRelease && !hasValidKeystore && !allowDebugSigning) {
            throw GradleException(
                "Release signing is not configured: android/key.properties or its " +
                    "storeFile is missing. See docs/play_store_deployment_guide.md. " +
                    "(For a local-only test build: flutter build apk --release -P allowDebugSigning=true)"
            )
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasValidKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
