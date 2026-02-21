package com.example.attendance

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.attendance/shared_data"
    private var sharedVcfPath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle intent if app was launched from share intent
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSharedVcfPath" -> {
                        val path = sharedVcfPath
                        sharedVcfPath = null  // Clear after reading
                        result.success(path)
                    }
                    else -> result.notImplemented()
                }
            }
        
        // Handle intent if already ready
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // When app is already running and user shares a file
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        
        if (Intent.ACTION_SEND == intent.action) {
            val type = intent.type
            
            // Check if it's a text-based MIME type (VCF files)
            if (type != null && (
                type.startsWith("text/") || 
                type == "application/octet-stream" ||
                type.startsWith("*")
            )) {
                val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM)
                }
                
                uri?.let {
                    val path = copyUriToCache(it)
                    if (path != null) {
                        sharedVcfPath = path
                    }
                }
            }
        }
    }

    private fun copyUriToCache(uri: Uri): String? {
        return try {
            // Use ContentResolver to read the file from URI
            contentResolver.openInputStream(uri)?.use { input ->
                // Create a temporary file in app's cache directory
                val tempFile = File(cacheDir, "shared_vcf_${System.currentTimeMillis()}.vcf")
                FileOutputStream(tempFile).use { output ->
                    input.copyTo(output)
                }
                return tempFile.absolutePath
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
