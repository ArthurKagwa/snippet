package com.arthur.snippet

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PlayUpdate.CHANNEL)
            .setMethodCallHandler { call, result ->
                PlayUpdate.handle(this, call, result)
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GalleryStore.CHANNEL)
            .setMethodCallHandler { call, result ->
                GalleryStore.handle(this, call, result)
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (PlayUpdate.onActivityResult(requestCode, resultCode)) return
        super.onActivityResult(requestCode, resultCode, data)
    }
}
