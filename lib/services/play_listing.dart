import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Play application id for Snippet. Store links are accepted only for this id.
const snippetApplicationId = 'com.arthur.snippet';

/// Opens the Play app on this app's listing.
final Uri snippetPlayMarketUri = Uri(
  scheme: 'market',
  host: 'details',
  queryParameters: const {'id': snippetApplicationId},
);

/// Opens this app's listing in a browser when the Play app is not installed.
final Uri snippetPlayHttpsUri = Uri(
  scheme: 'https',
  host: 'play.google.com',
  path: '/store/apps/details',
  queryParameters: const {'id': snippetApplicationId},
);

/// True only for this app's Play listing, as a market link or https URL.
///
/// Anything else (another package, http, a redirect, extra query parameters)
/// is refused. Remote Config cannot choose the destination.
bool isSnippetPlayListing(Uri uri) {
  if (uri.hasPort || uri.hasFragment || uri.userInfo.isNotEmpty) return false;
  if (uri.queryParameters.length != 1) return false;
  if (uri.queryParameters['id'] != snippetApplicationId) return false;
  if (uri.scheme == 'market') {
    return uri.host == 'details' && (uri.path.isEmpty || uri.path == '/');
  }
  if (uri.scheme == 'https') {
    return uri.host == 'play.google.com' && uri.path == '/store/apps/details';
  }
  return false;
}

/// Opens [snippetPlayMarketUri], then [snippetPlayHttpsUri] if that fails.
///
/// Returns false when neither opens. Does not throw.
Future<bool> openSnippetPlayListing({
  Future<bool> Function(Uri uri)? launch,
}) async {
  final open = launch ?? _launchExternal;
  for (final uri in [snippetPlayMarketUri, snippetPlayHttpsUri]) {
    if (!isSnippetPlayListing(uri)) {
      debugPrint('Refusing a Play link that is not this app: $uri');
      continue;
    }
    try {
      if (await open(uri)) return true;
    } catch (e) {
      debugPrint('Could not open Google Play: $e');
    }
  }
  return false;
}

Future<bool> _launchExternal(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// The Play listing for this app.
abstract class PlayListing {
  Future<bool> open();
}

class ExternalPlayListing implements PlayListing {
  const ExternalPlayListing();

  @override
  Future<bool> open() => openSnippetPlayListing();
}
