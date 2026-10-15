import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../cards/card_style_overrides.dart';
import 'content_config_service.dart';

/// [ContentConfigService] backed by Firebase Remote Config.
///
/// Parameters (see remoteconfig.template.json):
/// - `featured_verses`: JSON array of references, e.g. `["PSA 46:10"]`.
/// - `announcement`: plain text; empty means none.
/// - `card_styles`: JSON changes to the card styles; see
///   [CardStyleOverrides]. `{}` means as bundled.
///
/// The first launch waits briefly for a fetch. After that the values
/// fetched on the previous launch are applied right away and a new fetch
/// runs in the background, so Home never waits on the network.
class FirebaseContentConfigService implements ContentConfigService {
  FirebaseContentConfigService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static const featuredVersesKey = 'featured_verses';
  static const announcementKey = 'announcement';
  static const cardStylesKey = 'card_styles';

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
        featuredVersesKey: jsonEncode([
          for (final v in defaultContentConfig.featuredVerses) v.ref,
        ]),
        announcementKey: '',
        cardStylesKey: '{}',
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
        featuredVersesJson: rc.getString(featuredVersesKey),
        announcement: rc.getString(announcementKey),
        cardStylesJson: rc.getString(cardStylesKey),
      );
    } catch (e) {
      debugPrint('Remote Config unavailable, using bundled content: $e');
      return defaultContentConfig;
    }
  }
}

/// Builds a [ContentConfig] from raw parameter values. Unreadable verse
/// references are skipped; if none are left the bundled verses are used.
ContentConfig parseRemoteContent({
  required String featuredVersesJson,
  required String announcement,
  String cardStylesJson = '',
}) {
  var verses = <FeaturedVerse>[];
  try {
    final decoded = jsonDecode(featuredVersesJson);
    if (decoded is List) {
      verses = [
        for (final ref in decoded.whereType<String>())
          ?FeaturedVerse.tryParse(ref),
      ];
    }
  } on FormatException catch (e) {
    debugPrint('Remote Config featured_verses is not JSON: $e');
  }
  final text = announcement.trim();
  return ContentConfig(
    featuredVerses: verses.isEmpty
        ? defaultContentConfig.featuredVerses
        : verses,
    announcement: text.isEmpty ? null : text,
    cardStyles: CardStyleOverrides.parse(cardStylesJson),
  );
}
