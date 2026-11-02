package com.arthur.snippet

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentResolver
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

/**
 * Writes a PNG into the gallery and returns its MediaStore content URI, then
 * opens that URI with ACTION_VIEW. Uses the same Pictures/Snippet location the
 * app already saves to, and does not ask for any storage permission of its own.
 */
object GalleryStore {
    const val CHANNEL = "com.arthur.snippet/gallery"

    private val main = Handler(Looper.getMainLooper())
    private val token = Regex("[^A-Za-z0-9_-]")

    fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "savePng" -> saveAsync(activity, call, result)
            "viewImage" -> {
                val uri = call.argument<String>("uri")
                result.success(uri != null && viewImage(activity, uri))
            }
            else -> result.notImplemented()
        }
    }

    private fun saveAsync(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val name = call.argument<String>("name") ?: "snippet"
        val album = call.argument<String>("album") ?: "Snippet"
        if (bytes == null || bytes.isEmpty()) {
            result.error("SAVE_FAILED", "Nothing to save", null)
            return
        }
        val appContext = activity.applicationContext
        Thread {
            try {
                val uri = savePng(appContext.contentResolver, bytes, name, album)
                reply(result) { result.success(uri) }
            } catch (t: Throwable) {
                reply(result) {
                    result.error("SAVE_FAILED", t.message ?: "Could not save the image", null)
                }
            }
        }.start()
    }

    private fun reply(result: MethodChannel.Result, block: () -> Unit) {
        main.post {
            try {
                block()
            } catch (_: RuntimeException) {
                // The engine can detach before the write finishes.
            }
        }
    }

    internal fun savePng(
        resolver: ContentResolver,
        bytes: ByteArray,
        rawName: String,
        rawAlbum: String,
    ): String {
        val name = fileToken(rawName)
        val album = fileToken(rawAlbum).ifEmpty { "Snippet" }
        val extension = ".png"
        val values = contentValues(name, album, extension)
        val uri = insertUnique(resolver, values, name, extension)
        try {
            resolver.openOutputStream(uri)?.use { out ->
                out.write(bytes)
                out.flush()
            } ?: throw IOException("Could not open the gallery file")
            publish(resolver, uri)
        } catch (e: Exception) {
            deleteQuietly(resolver, uri)
            throw e
        }
        return uri.toString()
    }

    private fun publish(resolver: ContentResolver, uri: Uri) {
        if (Build.VERSION.SDK_INT < 30) return
        val done = ContentValues()
        done.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, done, null, null)
    }

    @Suppress("DEPRECATION")
    private fun contentValues(name: String, album: String, extension: String): ContentValues {
        val values = ContentValues()
        if (Build.VERSION.SDK_INT <= 29) {
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                album,
            )
            if (!dir.exists()) dir.mkdirs()
            var path = ""
            val stem = dir.path + File.separator + name
            for (i in 0 until 50) {
                path = stem + (if (i == 0) "" else i.toString()) + extension
                if (!File(path).exists()) break
            }
            values.put(MediaStore.MediaColumns.DATA, path)
        } else {
            values.put(
                MediaStore.Images.Media.RELATIVE_PATH,
                Environment.DIRECTORY_PICTURES + File.separator + album,
            )
            values.put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        values.put(MediaStore.MediaColumns.DISPLAY_NAME, name + extension)
        values.put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
        return values
    }

    private fun insertUnique(
        resolver: ContentResolver,
        values: ContentValues,
        name: String,
        extension: String,
    ): Uri {
        var last: Exception = IOException("Could not save the image")
        for (suffix in 0 until 50) {
            values.put(
                MediaStore.MediaColumns.DISPLAY_NAME,
                name + (if (suffix == 0) "" else suffix.toString()) + extension,
            )
            try {
                val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                if (uri != null) return uri
                last = IOException("MediaStore insert returned null")
            } catch (e: IllegalStateException) {
                val message = e.message ?: ""
                if (!message.contains("Failed to build unique file")) throw e
                last = e
            }
        }
        throw last
    }

    private fun viewImage(activity: Activity, uriString: String): Boolean {
        val uri = try {
            Uri.parse(uriString)
        } catch (_: Exception) {
            return false
        }
        if (uri.scheme != "content") return false
        for (mime in arrayOf("image/*", "image/png")) {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                clipData = ClipData.newRawUri("image", uri)
            }
            try {
                activity.startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
                continue
            } catch (_: Exception) {
                return false
            }
        }
        return false
    }

    private fun deleteQuietly(resolver: ContentResolver, uri: Uri) {
        try {
            resolver.delete(uri, null, null)
        } catch (_: Exception) {
        }
    }

    private fun fileToken(raw: String): String {
        val cleaned = token.replace(raw.trim(), "_").trim('_')
        if (cleaned.isEmpty()) return "snippet"
        return cleaned.take(120)
    }
}
