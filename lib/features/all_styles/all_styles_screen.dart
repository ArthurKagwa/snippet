import 'package:flutter/material.dart';

import '../../cards/card_catalog.dart';
import '../../cards/card_content.dart';
import '../../cards/card_style_spec.dart';
import '../../cards/verse_scale.dart';
import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../core/theme/snippet_motion.dart';
import '../../widgets/circle_button.dart';
import '../../widgets/cobalt_header.dart';
import 'filter_chips.dart';
import 'style_tile.dart';

/// Every style at once for the current verse. Pops with the chosen index,
/// after [onPick] has moved the swipe stack to it so the tile can fly in.
class AllStylesScreen extends StatefulWidget {
  const AllStylesScreen({
    super.key,
    required this.content,
    required this.selectedIndex,
    required this.variantOf,
    required this.onPick,
  });

  final CardContent content;
  final int selectedIndex;

  /// Current colourway per style index, so tiles match the swipe stack.
  final int Function(int styleIndex) variantOf;

  /// Called just before popping, so the destination card is already built
  /// when the hero flight starts.
  final ValueChanged<int> onPick;

  @override
  State<AllStylesScreen> createState() => _AllStylesScreenState();
}

class _AllStylesScreenState extends State<AllStylesScreen> {
  StyleTag? _filter;
  int? _picked;

  void _pick(int i) {
    if (_picked != null) return;
    setState(() => _picked = i);
    widget.onPick(i);
    Navigator.of(context).pop(i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final styles = VerseScales.stylesForVerse(
      CardCatalog.styles,
      widget.content,
    );
    // The outgoing grid of a filter fade keeps its own filter, so only the
    // current grid can offer a hero.
    final filter = _filter;
    final visible = [
      for (var i = 0; i < styles.length; i++)
        if (_filter == null || styles[i].tags.contains(_filter)) i,
    ];
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CobaltHeader(
            child: Row(
              children: [
                CircleButton(
                  tooltip: 'Back to swiping',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All styles',
                    style: SnippetFonts.display(
                      21,
                      color: c.white,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    widget.content.reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SnippetFonts.serifText(15, color: c.mist),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilterChips(
            selected: _filter,
            onChanged: (t) => setState(() => _filter = t),
          ),
          Expanded(
            // A new filter fades its results in (and starts at the top).
            child: AnimatedSwitcher(
              duration: SnippetMotion.swap,
              switchInCurve: SnippetMotion.easeOut,
              switchOutCurve: SnippetMotion.easeOut,
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              child: GridView.builder(
                key: ValueKey(_filter),
                padding: EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.66,
                ),
                itemCount: visible.length,
                itemBuilder: (context, n) {
                  final i = visible[n];
                  final style = styles[i];
                  return StyleTile(
                    key: Key('style-tile-${style.id}'),
                    style: style,
                    variant: style.variants[widget.variantOf(i)],
                    content: widget.content,
                    selected: i == widget.selectedIndex,
                    hero: i == _picked && filter == _filter,
                    onTap: () => _pick(i),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
