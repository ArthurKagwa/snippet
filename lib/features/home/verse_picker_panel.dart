import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../data/app_settings.dart';
import '../../data/bible_models.dart';
import '../../data/bible_repository.dart';
import '../../widgets/arch_panel.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/pill_toggle.dart';
import 'book_button.dart';
import 'number_wheel.dart';
import 'recent_row.dart';
import 'wheel_box.dart';

/// The stone "Pick a verse" panel on Home. Stateless: Home owns the range.
class VersePickerPanel extends StatelessWidget {
  const VersePickerPanel({
    super.key,
    required this.translationIds,
    required this.translationId,
    required this.book,
    required this.range,
    required this.passage,
    required this.recent,
    required this.onTranslation,
    required this.onPickBook,
    required this.onChapter,
    required this.onStart,
    required this.onEnd,
    required this.onRecent,
    required this.onSwipe,
  });

  final List<String> translationIds;
  final String translationId;
  final Book book;
  final VerseRange range;
  final Passage? passage;
  final List<RecentVerse> recent;
  final ValueChanged<String> onTranslation;
  final VoidCallback onPickBook;
  final ValueChanged<int> onChapter;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onEnd;
  final ValueChanged<RecentVerse> onRecent;
  final VoidCallback? onSwipe;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final verseCount = book.verseCount(range.chapter);
    return ArchPanel(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pick a verse',
                          style: SnippetFonts.display(
                            26,
                            color: c.ink,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        ),
                      ),
                      PillToggle<String>(
                        key: const Key('translation-toggle'),
                        semanticLabel: 'Translation',
                        options: translationIds,
                        selected: translationId,
                        onChanged: onTranslation,
                        labelOf: (id) => BibleRepository.shortNames[id] ?? id,
                        track: c.stone2,
                        selectedFill: c.cobalt,
                        selectedText: c.white,
                        text: c.ink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BookButton(name: book.name, onTap: onPickBook),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: WheelBox(
                          label: 'Chapter',
                          child: NumberWheel(
                            key: ValueKey('chapter-${book.id}'),
                            semanticLabel: 'Chapter',
                            min: 1,
                            max: book.chapterCount,
                            value: range.chapter,
                            onChanged: onChapter,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: WheelBox(
                          label: 'Verses',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              NumberWheel(
                                key: ValueKey(
                                  'from-${book.id}-${range.chapter}',
                                ),
                                semanticLabel: 'From verse',
                                width: 52,
                                min: 1,
                                max: verseCount,
                                value: range.startVerse,
                                onChanged: onStart,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  'to',
                                  style: SnippetFonts.display(
                                    14,
                                    weight: FontWeight.w700,
                                    color: c.ink,
                                  ),
                                ),
                              ),
                              NumberWheel(
                                key: ValueKey('to-${book.id}-${range.chapter}'),
                                semanticLabel: 'To verse',
                                width: 52,
                                min: 1,
                                max: verseCount,
                                value: range.endVerse,
                                onChanged: onEnd,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    passage == null
                        ? 'No text for this selection.'
                        : '“${passage!.text}”',
                    key: const Key('passage-text'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: SnippetFonts.serifText(
                      18,
                      color: c.ink,
                      height: 1.25,
                    ),
                  ),
                  if (recent.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    RecentRow(recent: recent, onTap: onRecent),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: PillButton(
                key: const Key('swipe-styles'),
                label: 'Preview',
                icon: Icons.arrow_forward_rounded,
                onPressed: onSwipe,
                background: c.cobalt,
                foreground: c.white,
                height: 54,
                fontSize: 15.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
