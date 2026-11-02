import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'gallery_channel.dart';

/// A saved image the confirmation can open, when the platform can point at it.
@immutable
class SavedGalleryImage {
  const SavedGalleryImage.contentUri(this.uri) : photosApp = false;

  /// iOS cannot return the new photo from the gallery plugin, and there is
  /// no public API that opens that one item. The Photos app is the fallback.
  const SavedGalleryImage.photosApp() : uri = null, photosApp = true;

  /// MediaStore content URI. Null when [photosApp] is set.
  final String? uri;

  final bool photosApp;

  bool get canView {
    final value = uri;
    if (photosApp) return true;
    return value != null && value.startsWith('content:');
  }

  /// Android only offers View when [contentUri] is a content URI. Other
  /// platforms open the Photos app.
  static SavedGalleryImage? fromSave({
    required bool android,
    String? contentUri,
  }) {
    if (!android) return const SavedGalleryImage.photosApp();
    if (contentUri != null && contentUri.startsWith('content:')) {
      return SavedGalleryImage.contentUri(contentUri);
    }
    return null;
  }
}

/// Renders a [RepaintBoundary] to PNG and saves or shares it; also shares
/// plain text through the system share sheet.
abstract class ExportService {
  Future<Uint8List> capturePng(
    RenderRepaintBoundary boundary, {
    double pixelRatio,
  });

  /// Null when the image was saved but nothing can be opened.
  Future<SavedGalleryImage?> saveToGallery(
    Uint8List png, {
    required String name,
  });

  /// Opens [saved]. False when no app can show it. Never throws.
  Future<bool> openSaved(SavedGalleryImage saved);

  Future<void> share(Uint8List png, {required String name, String? text});
  Future<void> shareText(String text);
}

class DeviceExportService implements ExportService {
  const DeviceExportService({this.gallery = const GalleryChannel()});

  final GalleryChannel gallery;

  @override
  Future<Uint8List> capturePng(
    RenderRepaintBoundary boundary, {
    double pixelRatio = 3,
  }) async {
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('Could not encode PNG');
    return data.buffer.asUint8List();
  }

  @override
  Future<SavedGalleryImage?> saveToGallery(
    Uint8List png, {
    required String name,
  }) async {
    if (!await Gal.hasAccess(toAlbum: true)) {
      if (!await Gal.requestAccess(toAlbum: true)) {
        throw StateError('Gallery permission denied');
      }
    }
    if (Platform.isAndroid) {
      try {
        final uri = await gallery.savePng(png, name: name, album: 'Snippet');
        return SavedGalleryImage.fromSave(android: true, contentUri: uri);
      } on MissingPluginException {
        await Gal.putImageBytes(png, album: 'Snippet', name: name);
        return null;
      }
    }
    await Gal.putImageBytes(png, album: 'Snippet', name: name);
    return SavedGalleryImage.fromSave(android: false, contentUri: null);
  }

  @override
  Future<bool> openSaved(SavedGalleryImage saved) async {
    try {
      final uri = saved.uri;
      if (uri != null && saved.canView) return await gallery.view(uri);
      if (saved.photosApp) {
        await Gal.open();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Could not open the saved image: $e');
      return false;
    }
  }

  @override
  Future<void> share(
    Uint8List png, {
    required String name,
    String? text,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name.png');
    await file.writeAsBytes(png, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
      ),
    );
  }

  @override
  Future<void> shareText(String text) =>
      SharePlus.instance.share(ShareParams(text: text));
}
