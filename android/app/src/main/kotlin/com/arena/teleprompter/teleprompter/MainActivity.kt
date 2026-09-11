package com.arena.teleprompter.teleprompter

import android.content.Intent
import android.media.MediaScannerConnection
import android.os.Environment
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hosts the tiny "keep the screen awake" channel used by the prompter.
 *
 * While a session is running the Dart side asks for the display to stay on;
 * leaving the prompter releases it again. No extra permission is required —
 * `FLAG_KEEP_SCREEN_ON` only applies to this app's own window.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val SCREEN_CHANNEL = "teleprompter/screen"
        const val GALLERY_CHANNEL = "com.teleprompter.app/gallery"
        const val ENABLE = "enableKeepAwake"
        const val DISABLE = "disableKeepAwake"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Keep screen awake channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_CHANNEL)
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

        // Gallery media scan channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GALLERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanMediaFile" -> {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            // Use MediaScannerConnection to scan the file
                            MediaScannerConnection.scanFile(
                                this,
                                arrayOf(path),
                                arrayOf("video/mp4"),
                                null
                            )
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENT", "Path is null", null)
                        }
                    }
                    "getVideosDirectory" -> {
                        try {
                            // Create Movies/Teleprompter directory
                            val moviesDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), "Teleprompter")
                            if (!moviesDir.exists()) {
                                moviesDir.mkdirs()
                            }
                            result.success(moviesDir.absolutePath)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to get videos directory: ${e.message}", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}


