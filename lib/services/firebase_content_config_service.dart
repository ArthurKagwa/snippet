import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../cards/card_style_overrides.dart';
import 'android_update_policy.dart';
import 'content_config_service.dart';

/// [ContentConfigService] backed by Firebase Remote Config.
///
/// Parameters (see remoteconfig.template.json):
/// - `verse_calendar`: JSON object of local dates to references, e.g.
///   `{"2026-10-21": "ISA 40:31"}`.
/// - `fallback_verse`: reference for days missing from the calendar; empty or
///   unreadable means Genesis 1:1.
/// - `announcement`: plain text; empty means none.
/// - `card_styles`: JSON changes to the card styles; see
///   [CardStyleOverrides]. `{}` means as bundled.
/// - `invite_message`: text for "Invite a friend"; empty means bundled.
/// - `share_caption`: caption sent with a shared card, with placeholders
///   (see [ContentConfig.shareCaption]); empty means bundled.
/// - `min_android_build`: Play version code. Empty or unreadable means this
///   install is allowed. Android builds below a valid value must update.
/// - `android_update_title` and `android_update_message`: plain text for that
///   screen. Empty or unreadable means the built-in copy.
///
/// The first launch waits briefly for a fetch. After that the values
/// fetched on the previous launch are applied right away and a new fetch
/// runs in the background, so Home never waits on the network. A later
/// [refresh] fetches again so a required-update check can see a new minimum.
class FirebaseContentConfigService implements ContentConfigService {
  FirebaseContentConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static const verseCalendarKey = 'verse_calendar';
  static const fallbackVerseKey = 'fallback_verse';
  static const announcementKey = 'announcement';
  static const cardStylesKey = 'card_styles';
  static const inviteMessageKey = 'invite_message';
  static const shareCaptionKey = 'share_caption';
  static const minAndroidBuildKey = 'min_android_build';
  static const androidUpdateTitleKey = 'android_update_title';
  static const androidUpdateMessageKey = 'android_update_message';

  final FirebaseRemoteConfig _remoteConfig;
  Future<ContentConfig>? _loaded;

  @override
  Future<ContentConfig> load() => _loaded ??= _read(force: false);

  @override
  Future<ContentConfig> refresh() async {
    final config = await _read(force: true);
    _loaded = Future.value(config);
    return config;
  }

  Future<ContentConfig> _read({required bool force}) async {
    final rc = _remoteConfig;
    try {
      await _applySettings(rc, force: false);
      await rc.setDefaults({
        verseCalendarKey: jsonEncode({
          for (final e in defaultContentConfig.verseCalendar.entries)
            e.key: e.value.ref,
        }),
        fallbackVerseKey: defaultContentConfig.fallbackVerse.ref,
        announcementKey: '',
        cardStylesKey: '{}',
        inviteMessageKey: defaultInviteMessage,
        shareCaptionKey: defaultShareCaption,
        minAndroidBuildKey: '',
        androidUpdateTitleKey: '',
        androidUpdateMessageKey: '',
      });
      if (force) {
        await _applySettings(rc, force: true);
        try {
          await rc.fetchAndActivate().timeout(const Duration(seconds: 8));
        } catch (e) {
          debugPrint('Remote Config refresh failed: $e');
        }
        await _applySettings(rc, force: false);
      } else if (rc.lastFetchStatus == RemoteConfigFetchStatus.noFetchYet) {
        try {
          await rc.fetchAndActivate().timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('Remote Config first fetch failed: $e');
        }
      } else {
        await rc.activate();
        unawaited(
          rc.fetch().catchError(
            (Object e) => debugPrint('Remote Config fetch failed: $e'),
          ),
        );
      }
      return _parse(rc);
    } catch (e) {
      debugPrint('Remote Config unavailable, using bundled content: $e');
      if (force) rethrow;
      return defaultContentConfig;
    }
  }

  Future<void> _applySettings(FirebaseRemoteConfig rc, {required bool force}) {
    return rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: Duration(seconds: force ? 8 : 10),
        minimumFetchInterval: force
            ? Duration.zero
            : kDebugMode
            ? const Duration(minutes: 1)
            : const Duration(hours: 12),
      ),
    );
  }

  ContentConfig _parse(FirebaseRemoteConfig rc) {
    return parseRemoteContent(
      verseCalendarJson: rc.getString(verseCalendarKey),
      fallbackVerse: rc.getString(fallbackVerseKey),
      announcement: rc.getString(announcementKey),
      cardStylesJson: rc.getString(cardStylesKey),
      inviteMessage: rc.getString(inviteMessageKey),
      shareCaption: rc.getString(shareCaptionKey),
      minAndroidBuild: rc.getString(minAndroidBuildKey),
      androidUpdateTitle: rc.getString(androidUpdateTitleKey),
      androidUpdateMessage: rc.getString(androidUpdateMessageKey),
    );
  }
}

/// Builds a [ContentConfig] from raw parameter values. Calendar entries with
/// an unreadable date or reference are skipped, leaving that day on the
/// fallback verse; an empty or unreadable fallback means Genesis 1:1.
/// An empty invite message or share caption falls back to the bundled one.
ContentConfig parseRemoteContent({
  required String verseCalendarJson,
  String fallbackVerse = '',
  required String announcement,
  String cardStylesJson = '',
  String inviteMessage = '',
  String shareCaption = '',
  String minAndroidBuild = '',
  String androidUpdateTitle = '',
  String androidUpdateMessage = '',
}) {
  final calendar = <String, FeaturedVerse>{};
  try {
    final decoded = jsonDecode(verseCalendarJson);
    if (decoded is Map) {
      for (final MapEntry(:key, :value) in decoded.entries) {
        final date = key is String ? DateTime.tryParse(key) : null;
        final verse = value is String ? FeaturedVerse.tryParse(value) : null;
        if (date == null || verse == null || localDateKey(date) != key) {
          continue;
        }
        calendar[key as String] = verse;
      }
    }
  } on FormatException catch (e) {
    debugPrint('Remote Config verse_calendar is not JSON: $e');
  }
  final text = announcement.trim();
  final invite = inviteMessage.trim();
  final caption = shareCaption.trim();
  return ContentConfig(
    verseCalendar: calendar,
    fallbackVerse: FeaturedVerse.tryParse(fallbackVerse) ?? genesisFallback,
    announcement: text.isEmpty ? null : text,
    cardStyles: CardStyleOverrides.parse(cardStylesJson),
    inviteMessage: invite.isEmpty ? defaultInviteMessage : invite,
    shareCaption: caption.isEmpty ? defaultShareCaption : caption,
    androidUpdate: parseAndroidUpdatePolicy(
      minAndroidBuild: minAndroidBuild,
      title: androidUpdateTitle,
      message: androidUpdateMessage,
    ),
  );
}
