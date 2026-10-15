import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders a [RepaintBoundary] to PNG and saves or shares it; also shares
/// plain text through the system share sheet.
abstract class ExportService {
  Future<Uint8List> capturePng(
    RenderRepaintBoundary boundary, {
    double pixelRatio,
  });
  Future<void> saveToGallery(Uint8List png, {required String name});
  Future<void> share(Uint8List png, {required String name, String? text});
  Future<void> shareText(String text);
}

class DeviceExportService implements ExportService {
  const DeviceExportService();

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
  Future<void> saveToGallery(Uint8List png, {required String name}) async {
    if (!await Gal.hasAccess(toAlbum: true)) {
      if (!await Gal.requestAccess(toAlbum: true)) {
        throw StateError('Gallery permission denied');
      }
    }
    await Gal.putImageBytes(png, album: 'Snippet', name: name);
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
