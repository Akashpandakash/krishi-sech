import java.net.URI
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun decodedDartDefines(): Map<String, String> {
    val encoded = providers.gradleProperty("dart-defines").orNull.orEmpty()
    if (encoded.isBlank()) return emptyMap()
    return encoded.split(',').mapNotNull { value ->
        runCatching {
            String(Base64.getDecoder().decode(value), Charsets.UTF_8)
        }.getOrNull()?.let { decoded ->
            val separator = decoded.indexOf('=')
            if (separator <= 0) null
            else decoded.substring(0, separator) to decoded.substring(separator + 1)
        }
    }.toMap()
}

fun isPrivateProductionHost(host: String): Boolean {
    val normalized = host.lowercase()
    if (normalized == "localhost" || normalized == "10.0.2.2" || normalized == "::1") {
        return true
    }
    val parts = normalized.split('.').mapNotNull(String::toIntOrNull)
    if (parts.size != 4) return false
    return parts[0] == 10 ||
        parts[0] == 127 ||
        parts[0] == 0 ||
        (parts[0] == 169 && parts[1] == 254) ||
        (parts[0] == 172 && parts[1] in 16..31) ||
        (parts[0] == 192 && parts[1] == 168)
}

val validateFlutterEnvironment by tasks.registering {
    group = "verification"
    description = "Reject unsafe staging and production Flutter configuration."
    doLast {
        val defines = decodedDartDefines()
        val environment = defines["APP_ENV"] ?: "development"
        if (environment !in setOf("development", "staging", "production")) {
            throw GradleException("APP_ENV must be development, staging, or production")
        }
        if (environment == "development") return@doLast
        val rawApiUrl = defines["API_BASE_URL"]
            ?: throw GradleException("API_BASE_URL is required for $environment")
        val apiUrl = runCatching { URI(rawApiUrl) }.getOrElse {
            throw GradleException("API_BASE_URL must be an absolute URL")
        }
        if (apiUrl.scheme != "https" || apiUrl.host.isNullOrBlank()) {
            throw GradleException("$environment API_BASE_URL must use HTTPS")
        }
        if (environment == "production") {
            if (isPrivateProductionHost(apiUrl.host)) {
                throw GradleException("Production API_BASE_URL cannot use localhost, emulator, or a private LAN IP")
            }
            if (defines["DEMO_LOGIN_ENABLED"]?.toBooleanStrictOrNull() != false) {
                throw GradleException("DEMO_LOGIN_ENABLED must be false in production")
            }
            if (defines["DEBUG_OTP_ENABLED"]?.toBooleanStrictOrNull() != false) {
                throw GradleException("DEBUG_OTP_ENABLED must be false in production")
            }
        }
    }
}

tasks.named("preBuild").configure {
    dependsOn(validateFlutterEnvironment)
}

android {
    namespace = "com.krishisech.app.krishi_sech"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.krishisech.app.krishi_sech"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Production signing is injected by the release pipeline. Never
            // silently ship an artifact signed with the shared debug key.
            signingConfig = null
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
