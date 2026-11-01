import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../cards/card_style_overrides.dart';
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
///
/// The first launch waits briefly for a fetch. After that the values
/// fetched on the previous launch are applied right away and a new fetch
/// runs in the background, so Home never waits on the network.
class FirebaseContentConfigService implements ContentConfigService {
  FirebaseContentConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static const verseCalendarKey = 'verse_calendar';
  static const fallbackVerseKey = 'fallback_verse';
  static const announcementKey = 'announcement';
  static const cardStylesKey = 'card_styles';
  static const inviteMessageKey = 'invite_message';
  static const shareCaptionKey = 'share_caption';

  final FirebaseRemoteConfig _remoteConfig;
  Future<ContentConfig>? _loaded;

  @override
  Future<ContentConfig> load() => _loaded ??= _load();

  Future<ContentConfig> _load() async {
    final rc = _remoteConfig;
    try {
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 12),
        ),
      );
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
      });
      if (rc.lastFetchStatus == RemoteConfigFetchStatus.noFetchYet) {
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
      return parseRemoteContent(
        verseCalendarJson: rc.getString(verseCalendarKey),
        fallbackVerse: rc.getString(fallbackVerseKey),
        announcement: rc.getString(announcementKey),
        cardStylesJson: rc.getString(cardStylesKey),
        inviteMessage: rc.getString(inviteMessageKey),
        shareCaption: rc.getString(shareCaptionKey),
      );
    } catch (e) {
      debugPrint('Remote Config unavailable, using bundled content: $e');
      return defaultContentConfig;
    }
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
  );
}
