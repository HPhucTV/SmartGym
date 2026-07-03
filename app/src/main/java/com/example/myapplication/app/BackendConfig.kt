package com.example.myapplication.app

import android.os.Build
import java.net.URI

object BackendConfig {
    @Volatile
    var customServerUrl: String? = null
        set(value) {
            field = normalizeServerUrl(value)
        }

    val baseUrl: String?
        get() = resolveBackendBaseUrl(customServerUrl, isEmulator())

    private fun isEmulator(): Boolean {
        val brand = Build.BRAND ?: ""
        val device = Build.DEVICE ?: ""
        val fingerprint = Build.FINGERPRINT ?: ""
        val hardware = Build.HARDWARE ?: ""
        val model = Build.MODEL ?: ""
        val manufacturer = Build.MANUFACTURER ?: ""
        val product = Build.PRODUCT ?: ""

        return (brand.startsWith("generic") && device.startsWith("generic"))
                || fingerprint.startsWith("generic")
                || fingerprint.startsWith("unknown")
                || hardware.contains("goldfish")
                || hardware.contains("ranchu")
                || model.contains("google_sdk")
                || model.contains("Emulator")
                || model.contains("Android SDK built for x86")
                || manufacturer.contains("Genymotion")
                || product.contains("sdk_google")
                || product.contains("google_sdk")
                || product.contains("sdk")
                || product.contains("sdk_x86")
                || product.contains("vbox86p")
                || product.contains("emulator")
                || product.contains("simulator")
    }

}

internal fun resolveBackendBaseUrl(customUrl: String?, emulator: Boolean): String? =
    normalizeServerUrl(customUrl) ?: if (emulator) EMULATOR_BACKEND_URL else null

internal fun normalizeServerUrl(value: String?): String? {
    val trimmed = value?.trim()?.trimEnd('/')?.takeIf { it.isNotEmpty() } ?: return null
    val hasScheme = trimmed.contains("://")
    val candidate = if (!hasScheme) "http://$trimmed" else trimmed
    val uri = runCatching { URI(candidate) }.getOrNull() ?: return null
    if (uri.scheme?.lowercase() !in setOf("http", "https")) return null
    if (uri.host.isNullOrBlank() || uri.rawUserInfo != null || uri.rawQuery != null || uri.rawFragment != null) {
        return null
    }
    return candidate
}

private const val EMULATOR_BACKEND_URL = "http://10.0.2.2:3000"
