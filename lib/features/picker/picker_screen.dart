import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/bible_models.dart';
import '../../data/bible_repository.dart';
import '../../services/content_config_service.dart';
import '../../services/services.dart';
import '../card_editor/card_editor_screen.dart';
import 'account_sheet.dart';

/// Translation toggle + book -> chapter -> verse range picker.
class PickerScreen extends StatefulWidget {
  const PickerScreen({super.key});

  @override
  State<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends State<PickerScreen> {
  String _translationId = 'kjv';
  List<Book> _books = const [];
  VerseRange? _range;
  Passage? _passage;
  ContentConfig _config = const ContentConfig();
  bool _loading = true;
  Object? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _init();
    }
  }

  Future<void> _init() async {
    final services = Services.of(context);
    try {
      final config = await services.contentConfig.load();
      final books = await services.bible.books(_translationId);
      if (!mounted) return;
      _config = config;
      _books = books;
      _range = const VerseRange(bookId: 'JOH', chapter: 3, startVerse: 16);
      await _refreshPassage();
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Book get _book => _books.firstWhere((b) => b.id == _range!.bookId);

  Future<void> _refreshPassage() async {
    final p = await Services.of(context).bible.passage(_translationId, _range!);
    if (mounted) setState(() => _passage = p);
  }

  Future<void> _setTranslation(String id) async {
    final bible = Services.of(context).bible;
    final books = await bible.books(id);
    if (!mounted) return;
    setState(() {
      _translationId = id;
      _books = books;
    });
    await _refreshPassage();
  }

  Future<void> _update(VerseRange r) async {
    setState(() => _range = r);
    await _refreshPassage();
  }

  void _setBook(String id) {
    _update(VerseRange(bookId: id, chapter: 1, startVerse: 1));
  }

  void _setChapter(int c) {
    _update(VerseRange(bookId: _range!.bookId, chapter: c, startVerse: 1));
  }

  void _setStart(int v) {
    final r = _range!;
    _update(
      r.copyWith(startVerse: v, endVerse: r.endVerse < v ? v : r.endVerse),
    );
  }

  void _setEnd(int v) => _update(_range!.copyWith(endVerse: v));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTheme.appName),
        actions: [
          IconButton(
            tooltip: 'Account',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => showAccountSheet(context),
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text('Could not load Bible text: $_error'))
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final r = _range!;
    final book = _book;
    final verseCount = book.verseCount(r.chapter);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(AppTheme.tagline, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          key: const Key('translation-toggle'),
          segments: [
            for (final id in Services.of(context).bible.translationIds)
              ButtonSegment(
                value: id,
                label: Text(BibleRepository.shortNames[id] ?? id),
              ),
          ],
          selected: {_translationId},
          onSelectionChanged: (s) => _setTranslation(s.first),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: const Key('book-dropdown'),
          initialValue: r.bookId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Book'),
          items: [
            for (final b in _books)
              DropdownMenuItem(value: b.id, child: Text(b.name)),
          ],
          onChanged: (v) => v == null ? null : _setBook(v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('chapter-${r.bookId}-${r.chapter}'),
                initialValue: r.chapter,
                decoration: const InputDecoration(labelText: 'Chapter'),
                items: [
                  for (var c = 1; c <= book.chapterCount; c++)
                    DropdownMenuItem(value: c, child: Text('$c')),
                ],
                onChanged: (v) => v == null ? null : _setChapter(v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('start-${r.bookId}-${r.chapter}-${r.startVerse}'),
                initialValue: r.startVerse,
                decoration: const InputDecoration(labelText: 'From verse'),
                items: [
                  for (var v = 1; v <= verseCount; v++)
                    DropdownMenuItem(value: v, child: Text('$v')),
                ],
                onChanged: (v) => v == null ? null : _setStart(v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey(
                  'end-${r.bookId}-${r.chapter}-${r.startVerse}-${r.endVerse}',
                ),
                initialValue: r.endVerse,
                decoration: const InputDecoration(labelText: 'To verse'),
                items: [
                  for (var v = r.startVerse; v <= verseCount; v++)
                    DropdownMenuItem(value: v, child: Text('$v')),
                ],
                onChanged: (v) => v == null ? null : _setEnd(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_config.featuredVerses.isNotEmpty) ...[
          Text('Suggestions', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in _config.featuredVerses) _featuredChip(f),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _passage == null
                ? const Text('No text for this selection.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _passage!.text,
                        key: const Key('passage-text'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_passage!.reference} '
                        '(${BibleRepository.shortNames[_translationId]})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('create-card'),
          onPressed: _passage == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CardEditorScreen(passage: _passage!),
                  ),
                ),
          icon: const Icon(Icons.style_outlined),
          label: const Text('Create card'),
        ),
      ],
    );
  }

  Widget _featuredChip(FeaturedVerse f) {
    final name = _books.firstWhere((b) => b.id == f.bookId).name;
    final label = BibleRepository.formatReference(
      name,
      VerseRange(
        bookId: f.bookId,
        chapter: f.chapter,
        startVerse: f.startVerse,
        endVerse: f.endVerse,
      ),
    );
    return ActionChip(
      label: Text(label),
      onPressed: () => _update(
        VerseRange(
          bookId: f.bookId,
          chapter: f.chapter,
          startVerse: f.startVerse,
          endVerse: f.endVerse,
        ),
      ),
    );
  }
}
