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
import '../shell/shell_controller.dart';
import 'style_panel.dart';
import 'swipe_header.dart';
import 'swipe_stage.dart';

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

  /// Follows the passage, so a new verse keeps the current style.
  CardContent get _content => CardContent(
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
    final shell = ShellScope.read(context);
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
            onPressed: () => shell.select(ShellTab.saved),
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
                  onBack: () => ShellScope.read(context).select(ShellTab.home),
                  onAllStyles: _openAllStyles,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SwipeStage(
                  styles: _styles,
                  styleIndex: _styleIndex,
                  content: _content,
                  styleController: _styleController,
                  variantController: _variantController,
                  sideways: _sideways,
                  onScroll: _onScroll,
                  onStyleChanged: (i) => setState(() {
                    _styleIndex = i;
                    _sideways = false;
                  }),
                  onVariantChanged: (style, v) =>
                      setState(() => _variantOf[style] = v),
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
