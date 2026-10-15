import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../data/saved_card.dart';
import '../../services/services.dart';
import '../../widgets/cobalt_header.dart';
import '../../widgets/profile_button.dart';
import '../profile/profile_screen.dart';
import '../shell/shell_controller.dart';
import 'library_empty.dart';
import 'saved_card_tile.dart';

/// Saved cards in a two-column grid.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _newestFirst = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      Services.of(context).library.load();
    }
  }

  void _openProfile() {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(
        // Already on Saved; popping back is enough.
        builder: (_) => ProfileScreen(onShowSaved: () {}),
      ),
    );
  }

  void _open(SavedCard card) => ShellScope.read(
    context,
  ).preview(card.passage, styleId: card.styleId, variantId: card.variantId);

  Future<void> _confirmRemove(SavedCard card) async {
    final library = Services.of(context).library;
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove card?'),
        content: Text('${card.reference} will be removed from your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove ?? false) await library.remove(card.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final library = Services.of(context).library;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CobaltHeader(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Saved',
                    style: SnippetFonts.display(
                      21,
                      color: c.white,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
                ProfileButton(onPressed: _openProfile),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: library,
              builder: (context, _) {
                if (!library.isLoaded) {
                  return Center(
                    child: CircularProgressIndicator(color: c.lime),
                  );
                }
                if (library.error != null && library.cards.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: Text(
                        'Your library could not be loaded. Check your '
                        'connection and try again.',
                        textAlign: TextAlign.center,
                        style: SnippetFonts.body(13.3, color: c.mist),
                      ),
                    ),
                  );
                }
                final cards = _newestFirst
                    ? library.cards
                    : library.cards.reversed.toList();
                if (cards.isEmpty) {
                  return LibraryEmpty(
                    onPickVerse: () =>
                        ShellScope.read(context).select(ShellTab.home),
                  );
                }
                return _grid(cards);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(List<SavedCard> cards) {
    final c = context.colors;
    final n = cards.length;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$n saved card${n == 1 ? '' : 's'}',
                    style: SnippetFonts.body(11.3, color: c.mist),
                  ),
                ),
                Material(
                  color: c.surfaceDark,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => setState(() => _newestFirst = !_newestFirst),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            _newestFirst ? 'Newest' : 'Oldest',
                            style: SnippetFonts.body(
                              10,
                              weight: FontWeight.w600,
                              color: c.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.swap_vert_rounded,
                            size: 14,
                            color: c.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16,
            6,
            16,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 18,
              childAspectRatio: 0.6,
            ),
            itemCount: n,
            itemBuilder: (context, i) => SavedCardTile(
              key: Key('saved-${cards[i].id}'),
              card: cards[i],
              onTap: () => _open(cards[i]),
              onLongPress: () => _confirmRemove(cards[i]),
            ),
          ),
        ),
      ],
    );
  }
}
