import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../data/bible_models.dart';
import '../../widgets/arch_sheet.dart';

/// Lets the user pick a book; resolves to its id, or null if dismissed.
Future<String?> showBookPicker(
  BuildContext context, {
  required List<Book> books,
  required String selectedId,
}) => showArchSheet<String>(
  context,
  builder: (_) => _BookPicker(books: books, selectedId: selectedId),
);

class _BookPicker extends StatelessWidget {
  const _BookPicker({required this.books, required this.selectedId});

  final List<Book> books;
  final String selectedId;

  /// Protestant canon: the first 39 books are the Old Testament.
  static const int _oldTestamentCount = 39;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final split = books.length.clamp(0, _oldTestamentCount);
    Widget section(String title, List<Book> list) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: SnippetFonts.display(
            9,
            weight: FontWeight.w700,
            color: c.inkDim,
            letterSpacing: 1.7,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final b in list)
              _BookChip(
                book: b,
                selected: b.id == selectedId,
                onTap: () => Navigator.of(context).pop(b.id),
              ),
          ],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pick a book',
          style: SnippetFonts.display(26, color: c.ink, letterSpacing: -1),
        ),
        const SizedBox(height: 20),
        section('Old Testament', books.sublist(0, split)),
        if (books.length > split) ...[
          const SizedBox(height: 22),
          section('New Testament', books.sublist(split)),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _BookChip extends StatelessWidget {
  const _BookChip({
    required this.book,
    required this.selected,
    required this.onTap,
  });

  final Book book;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.cobalt : c.stone2,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            book.name,
            style: SnippetFonts.body(
              13,
              weight: FontWeight.w600,
              color: selected ? c.white : c.ink,
            ),
          ),
        ),
      ),
    );
  }
}
