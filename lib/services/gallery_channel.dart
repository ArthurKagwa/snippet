import 'package:flutter/services.dart';

/// Saves a PNG into Android's MediaStore and opens the content URI it returns.
///
/// The channel is Android-only. Callers treat a missing plugin or a missing
/// URI as "saved, but nothing to open" and keep the plain confirmation.
class GalleryChannel {
  const GalleryChannel([
    this.channel = const MethodChannel('com.arthur.snippet/gallery'),
  ]);

  final MethodChannel channel;

  /// Content URI (`content:…`), or null when the save did not hand one back.
  /// Throws [PlatformException] when the save itself fails.
  Future<String?> savePng(
    Uint8List png, {
    required String name,
    required String album,
  }) async {
    final uri = await channel.invokeMethod<String>('savePng', {
      'bytes': png,
      'name': name,
      'album': album,
    });
    if (uri == null || !uri.startsWith('content:')) return null;
    return uri;
  }

  /// False when no app can view [uri], or the platform call fails.
  Future<bool> view(String uri) async {
    if (!uri.startsWith('content:')) return false;
    try {
      return await channel.invokeMethod<bool>('viewImage', {'uri': uri}) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
