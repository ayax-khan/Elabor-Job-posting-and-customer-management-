package com.example.elabor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // This registers all Flutter plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // You can add additional platform-specific code here if needed
        // For example, to handle camera permissions:
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "channel_name").setMethodCallHandler { call, result ->
            when (call.method) {
                // Add platform-specific method handlers here
                else -> result.notImplemented()
            }
        }
    }
}