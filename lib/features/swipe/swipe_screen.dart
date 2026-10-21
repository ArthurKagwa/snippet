import 'package:flutter/material.dart';

import '../../cards/card_catalog.dart';
import '../../cards/card_content.dart';
import '../../core/theme/snippet_colors.dart';
import '../../data/bible_models.dart';
import '../../data/bible_repository.dart';
import '../../data/saved_card.dart';
import '../../services/services.dart';
import '../../widgets/toast.dart';
import '../all_styles/all_styles_screen.dart';
import '../auth/sign_in_sheet.dart';
import '../export/export_sheet.dart';
import '../profile/profile_screen.dart';
import '../shell/shell_controller.dart';
import 'style_panel.dart';
import 'swipe_header.dart';
import 'swipe_stage.dart';
import 'swipe_translation_toggle.dart';

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
  bool _saving = false;
  bool _exportOpen = false;
  bool _askingSignIn = false;
  bool _allStylesOpen = false;
  late final ShellController _shell = ShellScope.read(context);

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
  void initState() {
    super.initState();
    _shell.addListener(_onShell);
    // The nav may have asked before this screen existed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onShell());
  }

  void _onShell() {
    if (mounted && _shell.takeAllStylesRequest()) _openAllStyles();
  }

  @override
  void dispose() {
    _shell.removeListener(_onShell);
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
    if (_allStylesOpen) return;
    _allStylesOpen = true;
    try {
      await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (_) => AllStylesScreen(
            content: _content,
            selectedIndex: _styleIndex,
            variantOf: _variantIndex,
            // Jump before the pop so the picked card is there to land on.
            onPick: (i) {
              if (_styleController.hasClients) _styleController.jumpToPage(i);
            },
          ),
        ),
      );
    } finally {
      _allStylesOpen = false;
    }
  }

  Future<void> _openProfile() {
    final navigator = Navigator.of(context, rootNavigator: true);
    return navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileScreen(onShowSaved: () => _shell.select(ShellTab.saved)),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || _askingSignIn) return;
    final services = Services.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final shell = ShellScope.read(context);
    // Captured now so a swipe mid-save cannot change what gets saved.
    final style = _styles[_styleIndex];
    final variant = style.variants[_variantIndex(_styleIndex)];
    // The sign-in sheet waits on the user, so no spinner yet; just ignore
    // repeat taps.
    _askingSignIn = true;
    final bool signedIn;
    try {
      signedIn = await ensureSignedIn(context);
    } finally {
      _askingSignIn = false;
    }
    if (!signedIn || !mounted) return;
    setState(() => _saving = true);
    try {
      await services.library.add(
        SavedCard.fromPassage(
          widget.passage,
          styleId: style.id,
          variantId: variant.id,
        ),
      );
    } catch (e) {
      debugPrint('Could not save card: $e');
      showToast(messenger, 'Could not save this card. Try again.');
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    showToast(
      messenger,
      'Saved to your library',
      actionLabel: 'View',
      onAction: () => shell.select(ShellTab.saved),
    );
  }

  /// Not awaited by the button (the sheet covers it), but a second tap
  /// while the sheet is opening is ignored.
  void _export() {
    if (_exportOpen || _saving) return;
    _exportOpen = true;
    final style = _styles[_styleIndex];
    showExportSheet(
      context,
      content: _content,
      style: style,
      variant: style.variants[_variantIndex(_styleIndex)],
    ).whenComplete(() => _exportOpen = false);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.horizontal) return false;
    // Only start and end flip the hint; anything else mid-drag (like the
    // direction notice) would switch it back off and rebuild the screen.
    final bool dragging;
    if (n is ScrollStartNotification) {
      dragging = n.dragDetails != null;
    } else if (n is ScrollEndNotification) {
      dragging = false;
    } else {
      return false;
    }
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
                  translationToggle: SwipeTranslationToggle(
                    passage: widget.passage,
                  ),
                  onBack: () => ShellScope.read(context).select(ShellTab.home),
                  onProfile: _openProfile,
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
                saving: _saving,
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
