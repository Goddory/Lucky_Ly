package com.example.lucky_ly_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "WJ_arcore_check")
            .setMethodCallHandler { call, result ->
                if (call.method == "checkAvailability") {
                    // Check if Google Play Services for AR (ARCore) is installed
                    val isInstalled = try {
                        packageManager.getPackageInfo("com.google.ar.core", 0)
                        true
                    } catch (e: Exception) {
                        false
                    }
                    result.success(isInstalled)
                } else {
                    result.notImplemented()
                }
            }
    }
}
