import 'package:flutter/material.dart';

import '../../cards/card_catalog.dart';
import '../../cards/card_content.dart';
import '../../cards/card_style_spec.dart';
import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../widgets/circle_button.dart';
import '../../widgets/cobalt_header.dart';
import 'filter_chips.dart';
import 'style_tile.dart';

/// Every style at once for the current verse. Pops with the chosen index.
class AllStylesScreen extends StatefulWidget {
  const AllStylesScreen({
    super.key,
    required this.content,
    required this.selectedIndex,
    required this.variantOf,
  });

  final CardContent content;
  final int selectedIndex;

  /// Current colourway per style index, so tiles match the swipe stack.
  final int Function(int styleIndex) variantOf;

  @override
  State<AllStylesScreen> createState() => _AllStylesScreenState();
}

class _AllStylesScreenState extends State<AllStylesScreen> {
  StyleTag? _filter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final styles = CardCatalog.styles;
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
            child: GridView.builder(
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
                  onTap: () => Navigator.of(context).pop(i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
