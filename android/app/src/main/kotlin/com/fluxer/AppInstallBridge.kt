package com.fluxer

import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/**
 * Why an update archive must not be handed to the installer, or null if it may be.
 * Certificates are compared as sets of SHA-256 digests. An archive whose certificates
 * could not be read is let through: the system installer still refuses an update of
 * the same package that is signed with a different key.
 */
internal fun updateArchiveRejection(
    installedPackage: String,
    installedCerts: Set<String>,
    archivePackage: String?,
    archiveCerts: Set<String>,
): String? = when {
    archivePackage == null -> "The file is not a readable APK"
    archivePackage != installedPackage -> "The APK is for a different app ($archivePackage)"
    archiveCerts.isNotEmpty() && installedCerts.isNotEmpty() && archiveCerts != installedCerts ->
        "The APK is signed with a different key than the installed app"
    else -> null
}

/** Whether [file] is an APK directly inside [updatesDir], the only folder the FileProvider exposes. */
internal fun isUpdateArchivePath(file: File, updatesDir: File): Boolean {
    val canonical = file.canonicalFile
    return canonical.parentFile == updatesDir.canonicalFile && canonical.name.endsWith(".apk")
}

class AppInstallBridge(
    private val context: Context,
) {
    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_CAN_REQUEST_PACKAGE_INSTALLS -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(context.packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                METHOD_OPEN_INSTALL_PERMISSION_SETTINGS -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:${context.packageName}")
                            ).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(true)
                    }
                }
                METHOD_INSTALL_PACKAGE -> {
                    val filePath = call.argument<String>(ARG_FILE_PATH)
                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_PATH", "File path is required", null)
                        return@setMethodCallHandler
                    }
                    val file = File(filePath)
                    if (!isUpdateArchivePath(file, File(context.cacheDir, UPDATES_DIR_NAME))) {
                        result.error("INVALID_PATH", "Only downloaded updates can be installed", null)
                        return@setMethodCallHandler
                    }
                    if (!file.exists()) {
                        result.error("NOT_FOUND", "APK file does not exist", null)
                        return@setMethodCallHandler
                    }
                    // Parsing and verifying a full APK is too slow for the main thread.
                    Thread {
                        val rejection = try {
                            archiveRejection(file)
                        } catch (e: Exception) {
                            "The APK could not be checked: ${e.message}"
                        }
                        Handler(Looper.getMainLooper()).post {
                            if (rejection != null) {
                                // A refused download is useless and large; the next attempt downloads again.
                                file.delete()
                                result.error("UNTRUSTED_APK", rejection, null)
                            } else {
                                launchInstaller(file, result)
                            }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun launchInstaller(file: File, result: MethodChannel.Result) {
        try {
            val apkUri: Uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_FAILED", e.message, null)
        }
    }

    private fun archiveRejection(file: File): String? {
        val packageManager = context.packageManager
        val archive = signingFlags().firstNotNullOfOrNull { flags ->
            packageManager.getPackageArchiveInfo(file.absolutePath, flags)
                ?.takeIf { certDigests(it).isNotEmpty() }
        } ?: packageManager.getPackageArchiveInfo(file.absolutePath, 0)
        val installed = signingFlags().firstNotNullOfOrNull { flags ->
            packageManager.getPackageInfo(context.packageName, flags)
                .takeIf { certDigests(it).isNotEmpty() }
        }
        return updateArchiveRejection(
            installedPackage = context.packageName,
            installedCerts = installed?.let(::certDigests).orEmpty(),
            archivePackage = archive?.packageName,
            archiveCerts = archive?.let(::certDigests).orEmpty(),
        )
    }

    // Some Android versions return no signingInfo for an archive, so the older flag is the fallback.
    @Suppress("DEPRECATION")
    private fun signingFlags(): List<Int> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            listOf(PackageManager.GET_SIGNING_CERTIFICATES, PackageManager.GET_SIGNATURES)
        } else {
            listOf(PackageManager.GET_SIGNATURES)
        }

    @Suppress("DEPRECATION")
    private fun certDigests(info: PackageInfo): Set<String> {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && info.signingInfo != null) {
            info.signingInfo?.apkContentsSigners
        } else {
            info.signatures
        }
        return signatures.orEmpty().map { signature ->
            MessageDigest.getInstance("SHA-256").digest(signature.toByteArray())
                .joinToString("") { "%02x".format(it) }
        }.toSet()
    }

    companion object {
        const val CHANNEL_NAME = "fluxer_app/app_install"
        const val METHOD_CAN_REQUEST_PACKAGE_INSTALLS = "canRequestPackageInstalls"
        const val METHOD_OPEN_INSTALL_PERMISSION_SETTINGS = "openInstallPermissionSettings"
        const val METHOD_INSTALL_PACKAGE = "installPackage"
        const val ARG_FILE_PATH = "filePath"

        // Matches AppUpdateService's download folder and file_paths.xml.
        const val UPDATES_DIR_NAME = "updates"
    }
}
