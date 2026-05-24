import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = file("../key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
    println(">>> storeFile = ${"$"}{keyProperties[\"storeFile\"]}")
    println(">>> keyAlias  = ${"$"}{keyProperties[\"keyAlias\"]}")
} else {
    println("WARNING: key.properties not found at ${keyPropertiesFile.absolutePath}")
}

android {
    namespace = "com.geoflow.mygeoflow"
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
        applicationId = "com.geoflow.mygeoflow"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"]?.toString() ?: ""
            keyPassword = keyProperties["keyPassword"]?.toString() ?: ""
            storeFile = keyProperties["storeFile"]?.toString()?.let { file(it) }
            storePassword = keyProperties["storePassword"]?.toString() ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
