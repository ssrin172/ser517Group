package com.example.uwbprivacyapp


import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.example.uwbprivacyapp.ui.theme.UWB_ProjectTheme
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.uwb/channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkUWB") {
                result.success(checkUwbSupport())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun checkUwbSupport(): String {
        val packageManager: PackageManager = packageManager
        val deviceSupportsUWB = packageManager.hasSystemFeature("android.hardware.uwb")
        Log.d("UWB Check", if (deviceSupportsUWB) "Yes" else "No")
        return if (deviceSupportsUWB) "UWB is supported" else "UWB is not supported"
    }
}
