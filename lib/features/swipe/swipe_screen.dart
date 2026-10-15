import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../cards/card_catalog.dart';
import '../../cards/card_content.dart';
import '../../core/theme/snippet_colors.dart';
import '../../data/bible_models.dart';
import '../../data/bible_repository.dart';
import '../../data/saved_card.dart';
import '../../services/services.dart';
import '../all_styles/all_styles_screen.dart';
import '../auth/sign_in_sheet.dart';
import '../export/export_sheet.dart';
import '../library/library_screen.dart';
import 'style_page.dart';
import 'style_panel.dart';
import 'style_track.dart';
import 'swipe_header.dart';
import 'swipe_hint.dart';

/// Swipe up for the next style, sideways for the next colourway.
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({
    super.key,
    required this.passage,
    this.initialStyleId,
    this.initialVariantId,
  });

  final Passage passage;
  final String? initialStyleId;
  final String? initialVariantId;

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final _styles = CardCatalog.styles;
  late int _styleIndex = CardCatalog.indexOf(widget.initialStyleId);
  late final PageController _styleController = PageController(
    initialPage: _styleIndex,
  );
  late final Map<int, int> _variantOf = {
    _styleIndex: _styles[_styleIndex].variantIndex(widget.initialVariantId),
  };
  final Map<int, PageController> _variantControllers = {};
  bool _sideways = false;

  late final CardContent _content = CardContent(
    text: widget.passage.text,
    reference: widget.passage.reference,
    translation: BibleRepository.shortNames[widget.passage.translationId] ?? '',
  );

  int _variantIndex(int style) => _variantOf[style] ?? 0;

  PageController _variantController(int style) =>
      _variantControllers.putIfAbsent(
        style,
        () => PageController(initialPage: _variantIndex(style)),
      );

  @override
  void dispose() {
    _styleController.dispose();
    for (final c in _variantControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectVariant(int i) {
    final controller = _variantController(_styleIndex);
    if (controller.hasClients) {
      controller.animateToPage(
        i,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
    setState(() => _variantOf[_styleIndex] = i);
  }

  Future<void> _openAllStyles() async {
    final picked = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => AllStylesScreen(
          content: _content,
          selectedIndex: _styleIndex,
          variantOf: _variantIndex,
        ),
      ),
    );
    if (picked != null && mounted && _styleController.hasClients) {
      _styleController.jumpToPage(picked);
    }
  }

  Future<void> _save() async {
    final services = Services.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (!await ensureSignedIn(context)) return;
    final style = _styles[_styleIndex];
    try {
      await services.library.add(
        SavedCard.fromPassage(
          widget.passage,
          styleId: style.id,
          variantId: style.variants[_variantIndex(_styleIndex)].id,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Saved to your library'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => navigator.push(
              MaterialPageRoute<void>(builder: (_) => const LibraryScreen()),
            ),
          ),
        ),
      );
  }

  void _export() {
    final style = _styles[_styleIndex];
    showExportSheet(
      context,
      content: _content,
      style: style,
      variant: style.variants[_variantIndex(_styleIndex)],
    );
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.horizontal) return false;
    final dragging = n is ScrollStartNotification
        ? n.dragDetails != null
        : n is ScrollUpdateNotification
        ? _sideways
        : false;
    if (dragging != _sideways) setState(() => _sideways = dragging);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    final style = _styles[_styleIndex];
    final hints = Services.of(context).settings;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top + 8 + 40 + 8,
            child: ColoredBox(color: c.cobalt),
          ),
          Column(
            children: [
              SizedBox(height: top + 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SwipeHeader(
                  reference: widget.passage.reference,
                  translation: _content.translation,
                  onBack: () => Navigator.of(context).maybePop(),
                  onAllStyles: _openAllStyles,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    const hintSpace = 40.0;
                    var h = math.min(
                      380.0,
                      box.maxHeight - StylePage.peekDepth - hintSpace,
                    );
                    var w = h * 0.8;
                    if (w > box.maxWidth - 56) {
                      w = box.maxWidth - 56;
                      h = w / 0.8;
                    }
                    final cardSize = Size(w, h);
                    return Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: _onScroll,
                          child: PageView.builder(
                            key: const Key('style-pager'),
                            controller: _styleController,
                            scrollDirection: Axis.vertical,
                            itemCount: _styles.length,
                            onPageChanged: (i) => setState(() {
                              _styleIndex = i;
                              _sideways = false;
                            }),
                            itemBuilder: (context, i) => StylePage(
                              style: _styles[i],
                              nextStyle: i + 1 < _styles.length
                                  ? _styles[i + 1]
                                  : null,
                              content: _content,
                              controller: _variantController(i),
                              cardSize: cardSize,
                              onVariantChanged: (v) =>
                                  setState(() => _variantOf[i] = v),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 9,
                          top: h * 0.14,
                          child: AnimatedBuilder(
                            animation: _styleController,
                            builder: (context, _) => StyleTrack(
                              count: _styles.length,
                              height: h * 0.74,
                              position:
                                  _styleController.hasClients &&
                                      _styleController.position.haveDimensions
                                  ? _styleController.page ?? 0
                                  : _styleIndex.toDouble(),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: h + StylePage.peekDepth + 12,
                          child: ListenableBuilder(
                            listenable: hints,
                            builder: (context, _) => hints.swipeHints
                                ? SwipeHint(
                                    sideways: _sideways,
                                    isLast: _styleIndex == _styles.length - 1,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              StylePanel(
                style: style,
                variantIndex: _variantIndex(_styleIndex),
                onVariant: _selectVariant,
                onSave: _save,
                onExport: _export,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
