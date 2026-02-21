package com.example.nanospark

import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.util.Base64
import android.util.Log
import java.io.ByteArrayOutputStream
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "installed_apps_channel").setMethodCallHandler { call, result ->
            if (call.method == "getInstalledApps") {
                try {
                    val pm = packageManager
                    val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                    Log.d("InstalledAppsChannel", "Fetched "+apps.size+" installed apps")
                    val appList = mutableListOf<Map<String, Any?>>()
                    for (app in apps) {
                        val appName = pm.getApplicationLabel(app).toString()
                        val packageName = app.packageName
                        var iconBase64: String? = null
                        try {
                            val iconDrawable = pm.getApplicationIcon(app)
                            if (iconDrawable is BitmapDrawable) {
                                val bitmap = iconDrawable.bitmap
                                val stream = ByteArrayOutputStream()
                                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                                val byteArray = stream.toByteArray()
                                iconBase64 = Base64.encodeToString(byteArray, Base64.DEFAULT)
                            }
                        } catch (iconEx: Exception) {
                            Log.w("InstalledAppsChannel", "Failed to get icon for $packageName", iconEx)
                        }
                        appList.add(mapOf(
                            "name" to appName,
                            "packageName" to packageName,
                            "icon" to iconBase64,
                            "isSystemApp" to (app.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM != 0)
                        ))
                    }
                    Log.d("InstalledAppsChannel", "Returning appList size: "+appList.size)
                    result.success(appList)
                } catch (e: Exception) {
                    Log.e("InstalledAppsChannel", "Error fetching installed apps", e)
                    result.error("error", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
