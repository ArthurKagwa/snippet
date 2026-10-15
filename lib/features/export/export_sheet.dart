import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../cards/card_content.dart';
import '../../cards/card_palette.dart';
import '../../cards/card_shape.dart';
import '../../cards/card_style_spec.dart';
import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../services/services.dart';
import '../../widgets/arch_sheet.dart';
import '../../widgets/circle_button.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/snippet_switch.dart';
import '../../widgets/toast.dart';
import 'shape_option.dart';

/// "Share it": pick a shape, optionally add the mark, save or share a PNG.
/// Never needs an account.
Future<void> showExportSheet(
  BuildContext context, {
  required CardContent content,
  required CardStyleSpec style,
  required CardVariant variant,
}) => showArchSheet<void>(
  context,
  padding: const EdgeInsets.fromLTRB(24, 52, 24, 16),
  builder: (_) => ExportSheet(content: content, style: style, variant: variant),
);

class ExportSheet extends StatefulWidget {
  const ExportSheet({
    super.key,
    required this.content,
    required this.style,
    required this.variant,
  });

  final CardContent content;
  final CardStyleSpec style;
  final CardVariant variant;

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  final GlobalKey _boundaryKey = GlobalKey();
  late CardShape _shape = Services.of(context).settings.defaultShape;
  late bool _mark = Services.of(context).settings.showMark;

  /// 'save' or 'share' while that export runs; everything else waits.
  String? _running;

  bool get _busy => _running != null;

  static const Map<CardShape, double> _previewWidth = {
    CardShape.feed: 84,
    CardShape.portrait: 80,
    CardShape.story: 72,
  };

  String get _fileName {
    final slug = widget.content.reference.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return 'snippet_${slug}_${_shape.name}';
  }

  Future<void> _run(
    String id,
    Future<void> Function(Services s, Uint8List png) action,
  ) async {
    if (_busy) return;
    final services = Services.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _running = id);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ratio = _shape.pixelWidth / boundary.size.width;
      final png = await services.export.capturePng(boundary, pixelRatio: ratio);
      await action(services, png);
    } catch (e) {
      debugPrint('Export failed: $e');
      showToast(messenger, 'Could not export the image. Try again.');
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  Future<void> _saveImage() => _run('save', (s, png) async {
    final messenger = ScaffoldMessenger.of(context);
    await s.export.saveToGallery(png, name: _fileName);
    showToast(messenger, 'Saved to Photos');
  });

  Future<void> _share() => _run('share', (s, png) async {
    final config = await s.contentConfig.load();
    await s.export.share(
      png,
      name: _fileName,
      text: config.captionFor(widget.content),
    );
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Share it',
                style: SnippetFonts.display(
                  32,
                  color: c.ink,
                  letterSpacing: -1.3,
                  height: 1,
                ),
              ),
            ),
            CircleButton(
              tooltip: 'Close',
              icon: Icons.close_rounded,
              onPressed: () => Navigator.of(context).pop(),
              background: c.stone2,
              foreground: c.ink,
              borderColor: c.stone2,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Each shape gets its own layout, so nothing gets cropped.',
          style: SnippetFonts.body(11.5, color: c.inkDim),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final s in CardShape.values)
              Expanded(
                child: ShapeOption(
                  key: Key('shape-${s.name}'),
                  shape: s,
                  content: widget.content,
                  style: widget.style,
                  variant: widget.variant,
                  showMark: _mark,
                  selected: s == _shape,
                  width: _previewWidth[s]!,
                  boundaryKey: s == _shape ? _boundaryKey : null,
                  onTap: _busy ? null : () => setState(() => _shape = s),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: c.stone2, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Small Snippet mark',
                      style: SnippetFonts.body(12, color: c.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PNG · ${_shape.pixelWidth} × ${_shape.pixelHeight} px',
                      style: SnippetFonts.body(8.7, color: c.inkDim),
                    ),
                  ],
                ),
              ),
              SnippetSwitch(
                semanticLabel: 'Small Snippet mark',
                value: _mark,
                onChanged: (v) {
                  if (!_busy) setState(() => _mark = v);
                },
                onTrack: c.cobalt,
                onThumb: c.white,
                offTrack: c.stone2,
                offThumb: c.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              flex: 10,
              child: PillButton(
                key: const Key('save-image'),
                label: 'Save image',
                icon: Icons.download_rounded,
                onPressed: _busy ? null : _saveImage,
                busy: _running == 'save',
                foreground: c.ink,
                fontSize: 12.7,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 13,
              child: PillButton(
                key: const Key('share-image'),
                label: 'Share',
                icon: Icons.share_rounded,
                onPressed: _busy ? null : _share,
                busy: _running == 'share',
                background: c.cobalt,
                foreground: c.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
