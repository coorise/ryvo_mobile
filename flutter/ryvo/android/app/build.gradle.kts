import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val deployTarget = (
    project.findProperty("deployTarget") as String?
        ?: System.getenv("RYVO_DEPLOY_TARGET")
        ?: "local"
    ).lowercase()

fun readMapsKeyFromDartDefines(): String {
    val file = rootProject.file("../dart_defines.json")
    if (!file.exists()) return ""
    val match = Regex(""""GOOGLE_MAPS_API_KEY"\s*:\s*"([^"]*)"""")
        .find(file.readText())
    return match?.groupValues?.get(1)?.trim().orEmpty()
}

val googleMapsApiKey = (
    project.findProperty("googleMapsApiKey") as String?
        ?: System.getenv("GOOGLE_MAPS_API_KEY")
        ?: readMapsKeyFromDartDefines()
    ).trim()

val appId = when (deployTarget) {
    "prod" -> "com.ryvo.client"
    "dev" -> "com.ryvo.client.dev"
    else -> "com.ryvo.client.local"
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file(".keys/$deployTarget/key.properties")
val releaseSigningReady = keystorePropertiesFile.exists().also { found ->
    if (found) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = appId
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = appId
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseSigningReady) {
                signingConfigs.getByName("release")
            } else {
                println("WARN: No .keys/$deployTarget/key.properties — using debug signing.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
