package com.unnati.Freelancer

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.unnati.freelancer/navigation"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Optimize for all devices - enable hardware acceleration
        window.setFlags(
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        )
        
        // Keep screen on during critical operations (optional)
        // window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up method channel for platform-specific navigation
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "minimizeApp" -> {
                    // Move app to background instead of closing
                    moveTaskToBack(true)
                    result.success(true)
                }
                "exitApp" -> {
                    // Exit app completely
                    finishAndRemoveTask()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    

    
    override fun onPause() {
        super.onPause()
        // Cleanup or save state if needed for low-memory devices
    }
    
    override fun onResume() {
        super.onResume()
        // Restore state if needed
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Final cleanup
    }
}

