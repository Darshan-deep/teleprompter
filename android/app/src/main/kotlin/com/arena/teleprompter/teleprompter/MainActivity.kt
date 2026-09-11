package com.arena.teleprompter.teleprompter

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the tiny "keep the screen awake" channel used by the prompter.
 *
 * While a session is running the Dart side asks for the display to stay on;
 * leaving the prompter releases it again. No extra permission is required —
 * `FLAG_KEEP_SCREEN_ON` only applies to this app's own window.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "teleprompter/screen"
        const val ENABLE = "enableKeepAwake"
        const val DISABLE = "disableKeepAwake"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    ENABLE -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    DISABLE -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
