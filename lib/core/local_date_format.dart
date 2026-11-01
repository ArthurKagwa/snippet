import 'dart:ui';

import 'package:intl/intl.dart';

/// "Wednesday, 21 October 2026" in the phone's language and region (en_GB
/// here), not the app's English-only Material locale. Unknown locales fall
/// back to US English.
String localFullDate(DateTime day, {Locale? locale}) {
  final tag = (locale ?? PlatformDispatcher.instance.locale).toLanguageTag();
  final verified = Intl.verifiedLocale(
    tag,
    DateFormat.localeExists,
    onFailure: (_) => 'en_US',
  );
  return DateFormat.yMMMMEEEEd(verified).format(day);
}
