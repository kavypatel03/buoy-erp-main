package com.example.final_project

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.util.Log

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (t: Throwable) {
            Log.e("MainActivity", "Warning during plugin registration", t)
        }
    }
}
