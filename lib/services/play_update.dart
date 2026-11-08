import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'android_update_policy.dart';
import 'play_listing.dart';

/// What happened when the user asked to update.
enum UpdateAttempt {
  /// Play's immediate update UI was shown. The app does not also open the store.
  play,

  /// The Play listing was opened because an immediate update was not available.
  store,

  /// Neither worked. The required-update screen stays up.
  failed,
}

/// Result of asking Play for an immediate update of this install.
enum ImmediateUpdateStatus {
  /// The user accepted. Play restarts the app into the new build.
  completed,

  /// The user left Play's immediate update UI. Stay on the required screen.
  cancelled,

  /// Play has no immediate update for this install (sideload, or none published).
  unavailable,

  /// Play's update API failed.
  failed,
}

/// Reads this install's Android version code. Null when it is not Android
/// or the code cannot be read. A null result must not block the app.
abstract class AndroidBuildReader {
  Future<int?> readVersionCode();
}

/// Play immediate in-app updates for this application only.
abstract class AndroidUpdateFlow {
  /// Starts an immediate update when Play offers one.
  Future<ImmediateUpdateStatus> startImmediate();

  /// Continues an immediate update Play already started. Does not open the store.
  Future<void> resumeInProgress();
}

/// Tries Play's immediate update, then this app's Play listing.
///
/// Immediate is used only when Play says an update of this install is available
/// and an immediate flow is allowed. Cancellation stays on the required screen.
/// Any other result opens the store listing.
Future<UpdateAttempt> requestAndroidUpdate({
  required AndroidUpdateFlow flow,
  required PlayListing listing,
}) async {
  try {
    final status = await flow.startImmediate();
    switch (status) {
      case ImmediateUpdateStatus.completed:
      case ImmediateUpdateStatus.cancelled:
        return UpdateAttempt.play;
      case ImmediateUpdateStatus.unavailable:
      case ImmediateUpdateStatus.failed:
        break;
    }
  } catch (e) {
    debugPrint('Play immediate update failed: $e');
  }
  try {
    if (await listing.open()) return UpdateAttempt.store;
  } catch (e) {
    debugPrint('Could not open the Play listing: $e');
  }
  return UpdateAttempt.failed;
}

const _playUpdateChannel = MethodChannel('com.arthur.snippet/play_update');

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Version code from the Android package manager.
class PlatformAndroidBuild implements AndroidBuildReader {
  const PlatformAndroidBuild();

  @override
  Future<int?> readVersionCode() async {
    if (!_isAndroid) return null;
    try {
      final value = await _playUpdateChannel.invokeMethod<int>('versionCode');
      if (value == null) return null;
      return parseMinAndroidBuild('$value');
    } catch (e) {
      debugPrint('Could not read the Android build: $e');
      return null;
    }
  }
}

/// Play Core immediate updates through [PlayUpdate] on Android.
///
/// On any other platform, or when the channel is missing, this reports the
/// update unavailable so the caller can open the store listing instead.
class PlatformAndroidUpdate implements AndroidUpdateFlow {
  const PlatformAndroidUpdate();

  @override
  Future<ImmediateUpdateStatus> startImmediate() async {
    if (!_isAndroid) return ImmediateUpdateStatus.unavailable;
    try {
      final prepared = await _playUpdateChannel.invokeMethod<String>(
        'prepareImmediate',
      );
      if (prepared != 'immediate' && prepared != 'in_progress') {
        return prepared == 'failed'
            ? ImmediateUpdateStatus.failed
            : ImmediateUpdateStatus.unavailable;
      }
      return _status(
        await _playUpdateChannel.invokeMethod<String>('performImmediate'),
      );
    } catch (e) {
      debugPrint('Play immediate update failed: $e');
      return ImmediateUpdateStatus.failed;
    }
  }

  @override
  Future<void> resumeInProgress() async {
    if (!_isAndroid) return;
    try {
      final prepared = await _playUpdateChannel.invokeMethod<String>(
        'prepareImmediate',
      );
      if (prepared != 'in_progress') return;
      await _playUpdateChannel.invokeMethod<String>('performImmediate');
    } catch (e) {
      debugPrint('Could not resume the Play update: $e');
    }
  }

  ImmediateUpdateStatus _status(String? value) {
    return switch (value) {
      'completed' => ImmediateUpdateStatus.completed,
      'cancelled' => ImmediateUpdateStatus.cancelled,
      'unavailable' => ImmediateUpdateStatus.unavailable,
      _ => ImmediateUpdateStatus.failed,
    };
  }
}
