/// Whether this Android install must update before the rest of the app.
///
/// [minBuild] is a Play version code. Null means Remote Config did not give
/// a usable minimum, so the install is allowed. The same rule applies when
/// the installed version code cannot be read.
class AndroidUpdatePolicy {
  const AndroidUpdatePolicy({
    this.minBuild,
    this.title = defaultTitle,
    this.message = defaultMessage,
  });

  /// No minimum. The built-in copy is unused until a minimum is set.
  static const none = AndroidUpdatePolicy();

  static const defaultTitle = 'Update Snippet';
  static const defaultMessage =
      'This version of Snippet is no longer supported. '
      'Update it on Google Play to keep reading and sharing verses.';

  /// Play's highest allowed version code.
  static const maxVersionCode = 2100000000;

  final int? minBuild;
  final String title;
  final String message;

  /// True when [installedBuild] is a known version code below [minBuild].
  bool blocks(int? installedBuild) {
    final min = minBuild;
    final installed = installedBuild;
    if (min == null || installed == null) return false;
    return installed < min;
  }
}

/// A positive Play version code, or null when [raw] is empty or not one.
///
/// Rejects 0, signs, decimals, leading zeros and values Play will not accept,
/// so a bad Remote Config value never blocks the app.
int? parseMinAndroidBuild(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final value = int.tryParse(text);
  if (value == null ||
      value <= 0 ||
      value > AndroidUpdatePolicy.maxVersionCode) {
    return null;
  }
  if (value.toString() != text) return null;
  return value;
}

/// Title for the required-update screen. Blank or unsuitable text uses the
/// built-in title.
String parseAndroidUpdateTitle(String raw) =>
    _plainCopy(raw, maxLength: 80, fallback: AndroidUpdatePolicy.defaultTitle);

/// Message for the required-update screen. Blank or unsuitable text uses the
/// built-in message. Newlines are kept; other control characters are not.
String parseAndroidUpdateMessage(String raw) => _plainCopy(
  raw,
  maxLength: 400,
  fallback: AndroidUpdatePolicy.defaultMessage,
  allowNewlines: true,
);

String _plainCopy(
  String raw, {
  required int maxLength,
  required String fallback,
  bool allowNewlines = false,
}) {
  final text = raw.trim();
  if (text.isEmpty || text.length > maxLength) return fallback;
  for (final unit in text.runes) {
    if (allowNewlines && unit == 0x0A) continue;
    if (unit < 0x20 || unit == 0x7F) return fallback;
  }
  return text;
}

/// Builds the Android update policy from Remote Config strings.
AndroidUpdatePolicy parseAndroidUpdatePolicy({
  String minAndroidBuild = '',
  String title = '',
  String message = '',
}) {
  return AndroidUpdatePolicy(
    minBuild: parseMinAndroidBuild(minAndroidBuild),
    title: parseAndroidUpdateTitle(title),
    message: parseAndroidUpdateMessage(message),
  );
}
