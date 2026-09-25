package com.example.document_management

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.graphics.BitmapFactory
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val ocrExecutor = Executors.newSingleThreadExecutor()
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "document_vault/offline_ocr")
            .setMethodCallHandler { call, result ->
                if (call.method != "recognize") { result.notImplemented(); return@setMethodCallHandler }
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null || bytes.size > 20 * 1024 * 1024) {
                    result.error("invalid_image", "Choose an image up to 20 MB.", null)
                    return@setMethodCallHandler
                }
                ocrExecutor.execute {
                    try {
                        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
                        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) throw IllegalArgumentException()
                        var sample = 1
                        while (bounds.outWidth / sample > 2400 || bounds.outHeight / sample > 2400) sample *= 2
                        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size,
                            BitmapFactory.Options().apply { inSampleSize = sample }) ?: throw IllegalArgumentException()
                        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                        recognizer.process(InputImage.fromBitmap(bitmap, 0))
                            .addOnSuccessListener { text -> result.success(text.text) }
                            .addOnFailureListener { result.error("ocr_failed", "Could not read this image.", null) }
                            .addOnCompleteListener { recognizer.close(); bitmap.recycle() }
                    } catch (_: Exception) {
                        runOnUiThread { result.error("invalid_image", "Could not decode this image.", null) }
                    }
                }
            }
    }
    override fun onDestroy() {
        ocrExecutor.shutdown()
        super.onDestroy()
    }
}
