import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/card_style.dart';
import '../../data/bible_models.dart';
import '../../data/bible_repository.dart';
import '../../services/services.dart';
import 'quote_card.dart';

/// Preview + customize the card, then export as PNG (save or share).
class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({super.key, required this.passage});

  final Passage passage;

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  CardStyle _style = CardStyle.all.first;
  CardFont _font = CardFont.all.first;
  double _fontSize = 26;
  bool _busy = false;

  String get _fileName {
    final slug = widget.passage.reference.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return 'snippet_$slug';
  }

  Future<void> _export(
    Future<void> Function(Services s, Uint8List png) action,
  ) async {
    final services = Services.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final png = await services.export.capturePng(boundary, pixelRatio: 3);
      await action(services, png);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label =
        BibleRepository.shortNames[widget.passage.translationId] ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Card')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: QuoteCard(
              passage: widget.passage,
              style: _style,
              font: _font,
              fontSize: _fontSize,
              translationLabel: label,
            ),
          ),
          const SizedBox(height: 16),
          Text('Theme', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in CardStyle.all)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      key: Key('style-${s.id}'),
                      onTap: () => setState(() => _style = s),
                      child: Container(
                        width: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: s.gradient),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: s == _style ? 3 : 1,
                            color: s == _style
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black26,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text('Aa', style: TextStyle(color: s.textColor)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Font', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final f in CardFont.all)
                ChoiceChip(
                  key: Key('font-${f.id}'),
                  label: Text(f.name),
                  selected: f == _font,
                  onSelected: (_) => setState(() => _font = f),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.text_fields, size: 18),
              Expanded(
                child: Slider(
                  min: 16,
                  max: 40,
                  value: _fontSize,
                  onChanged: (v) => setState(() => _fontSize = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('export-png'),
                  onPressed: _busy
                      ? null
                      : () => _export((s, png) async {
                          final messenger = ScaffoldMessenger.of(context);
                          await s.export.saveToGallery(png, name: _fileName);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Saved PNG to gallery'),
                            ),
                          );
                        }),
                  icon: const Icon(Icons.download),
                  label: const Text('Export PNG'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('share-png'),
                  onPressed: _busy
                      ? null
                      : () => _export(
                          (s, png) => s.export.share(
                            png,
                            name: _fileName,
                            text: '${widget.passage.reference} ($label)',
                          ),
                        ),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
