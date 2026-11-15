package com.example.final_project

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import android.util.Log
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.buoy.erp/app_update"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (t: Throwable) {
            Log.e("MainActivity", "Warning during plugin registration", t)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getApkDownloadPath" -> {
                    try {
                        val file = File(cacheDir, "buoy-erp-update.apk")
                        result.success(file.absolutePath)
                    } catch (e: Exception) {
                        result.error("PATH_ERROR", e.localizedMessage, null)
                    }
                }
                "canInstallPackages" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                "openInstallPermissionSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.localizedMessage, null)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        try {
                            val file = File(filePath)
                            if (file.exists()) {
                                val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                    FileProvider.getUriForFile(
                                        this@MainActivity,
                                        "$packageName.fileProvider",
                                        file
                                    )
                                } else {
                                    Uri.fromFile(file)
                                }
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(uri, "application/vnd.android.package-archive")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.error("FILE_NOT_FOUND", "APK not found at $filePath", null)
                            }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Error triggering package installer", e)
                            result.error("INSTALL_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "filePath is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
