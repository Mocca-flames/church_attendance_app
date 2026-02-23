package com.example.attendance

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.attendance/shared_data"
    private var sharedVcfPath: String? = null
    private var methodChannel: MethodChannel? = null
    private var pendingIntent: Intent? = null

    companion object {
        private const val TAG = "VCFShareIntent"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate called with intent: $intent")
        // Process intent immediately in onCreate (Flutter calls configureFlutterEngine before onCreate)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "configureFlutterEngine called")
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedVcfPath" -> {
                    val path = sharedVcfPath
                    Log.d(TAG, "getSharedVcfPath called, returning: $path")
                    sharedVcfPath = null  // Clear after reading
                    result.success(path)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent called with action: ${intent.action}, type: ${intent.type}")
        // When app is already running and user shares a file
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            Log.d(TAG, "handleIntent called with null intent")
            return
        }
        
        Log.d(TAG, "handleIntent called with action: ${intent.action}, type: ${intent.type}")
        
        if (Intent.ACTION_SEND == intent.action) {
            val type = intent.type
            
            Log.d(TAG, "Detected SEND action, MIME type: $type")
            
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
                
                Log.d(TAG, "URI from intent: $uri")
                
                uri?.let {
                    val path = copyUriToCache(it)
                    if (path != null) {
                        Log.d(TAG, "Successfully copied VCF to: $path")
                        sharedVcfPath = path
                        
                        // Notify Flutter immediately that a VCF is available
                        notifyFlutterVcfReceived(path)
                    } else {
                        Log.e(TAG, "Failed to copy VCF from URI: $uri")
                    }
                }
            } else {
                Log.w(TAG, "MIME type not supported: $type")
            }
        } else {
            Log.w(TAG, "Unknown action: ${intent.action}")
        }
    }

    private fun notifyFlutterVcfReceived(path: String) {
        try {
            methodChannel?.invokeMethod("onVcfReceived", mapOf("path" to path))
            Log.d(TAG, "Notified Flutter about VCF at: $path")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to notify Flutter: ${e.message}")
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
