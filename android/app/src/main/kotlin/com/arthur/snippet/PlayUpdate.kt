package com.arthur.snippet

import android.app.Activity
import android.content.IntentSender
import android.content.pm.PackageManager
import android.os.Build
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.model.ActivityResult
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Version code and Play immediate updates for this application only.
 *
 * Play's client updates the package that is installed. This object still
 * refuses to start that flow unless the running package is Snippet, and it
 * never starts a flexible update (those let the current build keep running).
 * When Play has no immediate update, Dart opens the Play listing instead.
 */
object PlayUpdate {
    const val CHANNEL = "com.arthur.snippet/play_update"
    private const val PACKAGE = "com.arthur.snippet"
    private const val REQUEST = 7341

    private var pending: MethodChannel.Result? = null

    fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "versionCode" -> result.success(versionCode(activity))
            "prepareImmediate" -> prepare(activity, result)
            "performImmediate" -> perform(activity, result)
            else -> result.notImplemented()
        }
    }

    /**
     * @return true when [requestCode] belongs to this flow, so the activity
     * does not also deliver it to Flutter plugins.
     */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST) return false
        val status = when (resultCode) {
            Activity.RESULT_OK -> "completed"
            Activity.RESULT_CANCELED -> "cancelled"
            ActivityResult.RESULT_IN_APP_UPDATE_FAILED -> "failed"
            else -> "failed"
        }
        reply(status)
        return true
    }

    private fun versionCode(activity: Activity): Int? {
        return try {
            val info = if (Build.VERSION.SDK_INT >= 33) {
                activity.packageManager.getPackageInfo(
                    activity.packageName,
                    PackageManager.PackageInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                activity.packageManager.getPackageInfo(activity.packageName, 0)
            }
            val code = if (Build.VERSION.SDK_INT >= 28) {
                info.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                info.versionCode.toLong()
            }
            if (code <= 0L || code > 2100000000L) null else code.toInt()
        } catch (_: Exception) {
            null
        }
    }

    private fun prepare(activity: Activity, result: MethodChannel.Result) {
        if (!isSnippet(activity)) {
            result.success("unavailable")
            return
        }
        AppUpdateManagerFactory.create(activity).appUpdateInfo
            .addOnSuccessListener { info -> result.success(classify(info)) }
            .addOnFailureListener { result.success("failed") }
    }

    private fun perform(activity: Activity, result: MethodChannel.Result) {
        if (pending != null || !isSnippet(activity)) {
            result.success(if (pending != null) "failed" else "unavailable")
            return
        }
        val manager = AppUpdateManagerFactory.create(activity)
        manager.appUpdateInfo
            .addOnSuccessListener { info ->
                if (!canStartImmediate(info)) {
                    result.success("unavailable")
                    return@addOnSuccessListener
                }
                pending = result
                try {
                    @Suppress("DEPRECATION")
                    val started = manager.startUpdateFlowForResult(
                        info,
                        activity,
                        AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build(),
                        REQUEST,
                    )
                    if (!started) reply("failed")
                } catch (_: IntentSender.SendIntentException) {
                    reply("failed")
                } catch (_: Exception) {
                    reply("failed")
                }
            }
            .addOnFailureListener { result.success("failed") }
    }

    private fun canStartImmediate(info: AppUpdateInfo): Boolean {
        val availability = info.updateAvailability()
        if (availability == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS) {
            return true
        }
        return availability == UpdateAvailability.UPDATE_AVAILABLE &&
            info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
    }

    private fun classify(info: AppUpdateInfo): String {
        return when (info.updateAvailability()) {
            UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS -> "in_progress"
            UpdateAvailability.UPDATE_AVAILABLE ->
                if (info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
                    "immediate"
                } else {
                    "unavailable"
                }
            else -> "unavailable"
        }
    }

    private fun isSnippet(activity: Activity): Boolean = activity.packageName == PACKAGE

    private fun reply(status: String) {
        val result = pending ?: return
        pending = null
        result.success(status)
    }
}
