import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../data/app_settings.dart';
import '../../data/bible_models.dart';
import '../../services/services.dart';
import '../../widgets/cobalt_header.dart';
import '../../widgets/profile_button.dart';
import '../../widgets/snippet_wordmark.dart';
import '../profile/profile_screen.dart';
import '../shell/shell_controller.dart';
import 'book_picker_sheet.dart';
import 'verse_of_day.dart';
import 'verse_picker_panel.dart';

/// Home: verse of the day on top, the verse picker in the stone panel.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _translationId = 'kjv';
  List<Book> _books = const [];
  VerseRange _range = const VerseRange(
    bookId: 'PSA',
    chapter: 46,
    startVerse: 10,
  );
  Passage? _passage;
  Passage? _votd;
  String _votdPull = '';
  bool _loading = true;
  Object? _error;
  bool _started = false;

  Services get _services => Services.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _init();
    }
  }

  Future<void> _init() async {
    final s = _services;
    try {
      await s.settings.load();
      _translationId = s.settings.defaultTranslationId;
      await _loadTranslation();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadTranslation() async {
    final s = _services;
    final books = await s.bible.books(_translationId);
    final config = await s.contentConfig.load();
    final passage = await s.bible.passage(_translationId, _range);
    Passage? votd;
    var pull = '';
    final featured = config.verseOfTheDay(DateTime.now());
    if (featured != null) {
      final r = featured.range;
      votd = await s.bible.passage(_translationId, r);
      final last = await s.bible.passage(
        _translationId,
        r.copyWith(startVerse: r.endVerse),
      );
      pull = last?.text ?? votd?.text ?? '';
    }
    if (!mounted) return;
    _share(passage);
    setState(() {
      _books = books;
      _passage = passage;
      _votd = votd;
      _votdPull = pull;
    });
  }

  Book get _book => _books.firstWhere((b) => b.id == _range.bookId);

  /// Keeps the wheels inside the book's real chapter and verse counts.
  VerseRange _clamp(VerseRange r) {
    final book = _books.firstWhere((b) => b.id == r.bookId);
    final chapter = r.chapter.clamp(1, book.chapterCount);
    final verses = book.verseCount(chapter);
    final start = r.startVerse.clamp(1, verses);
    return VerseRange(
      bookId: r.bookId,
      chapter: chapter,
      startVerse: start,
      endVerse: r.endVerse.clamp(start, verses),
    );
  }

  Future<void> _setRange(VerseRange range) async {
    final r = _clamp(range);
    setState(() => _range = r);
    final p = await _services.bible.passage(_translationId, r);
    if (mounted && r == _range) {
      _share(p);
      setState(() => _passage = p);
    }
  }

  Future<void> _setTranslation(String id) async {
    if (id == _translationId) return;
    setState(() => _translationId = id);
    await _loadTranslation();
  }

  Future<void> _pickBook() async {
    final id = await showBookPicker(
      context,
      books: _books,
      selectedId: _range.bookId,
    );
    if (id != null && id != _range.bookId) {
      _setRange(VerseRange(bookId: id, chapter: 1, startVerse: 1));
    }
  }

  void _openSwipe(Passage p) {
    _services.settings.addRecent(
      RecentVerse(range: p.range, label: p.reference),
    );
    ShellScope.read(context).preview(p);
  }

  /// Keeps the Styles tab on the verse picked here.
  void _share(Passage? p) {
    if (p != null) ShellScope.read(context).setPassage(p);
  }

  /// Returns the route's Future so the button ignores a double tap.
  Future<void> _openProfile() {
    final navigator = Navigator.of(context);
    final shell = ShellScope.read(context);
    return navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileScreen(onShowSaved: () => shell.select(ShellTab.saved)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CobaltHeader(
            child: Row(
              children: [
                const SnippetWordmark(),
                const Spacer(),
                ProfileButton(onPressed: _openProfile),
              ],
            ),
          ),
          if (_error != null)
            Expanded(
              child: Center(
                child: Text(
                  'Could not load Bible text: $_error',
                  style: TextStyle(color: c.white),
                ),
              ),
            )
          else if (_loading)
            Expanded(
              child: Center(child: CircularProgressIndicator(color: c.lime)),
            )
          else ...[
            if (_votd != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
                child: VerseOfDay(
                  passage: _votd!,
                  pullQuote: _votdPull,
                  onSwipe: () => _openSwipe(_votd!),
                ),
              ),
            Expanded(child: _panel()),
          ],
        ],
      ),
    );
  }

  Widget _panel() {
    final settings = _services.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => VersePickerPanel(
        translationIds: _services.bible.translationIds,
        translationId: _translationId,
        book: _book,
        range: _range,
        passage: _passage,
        recent: settings.recent,
        onTranslation: _setTranslation,
        onPickBook: _pickBook,
        onChapter: (ch) => _setRange(
          VerseRange(bookId: _range.bookId, chapter: ch, startVerse: 1),
        ),
        onStart: (v) => _setRange(
          _range.copyWith(
            startVerse: v,
            endVerse: _range.endVerse < v ? v : _range.endVerse,
          ),
        ),
        onEnd: (v) => _setRange(
          _range.copyWith(
            endVerse: v,
            startVerse: _range.startVerse > v ? v : _range.startVerse,
          ),
        ),
        onRecent: (r) => _setRange(r.range),
        onSwipe: _passage == null ? null : () => _openSwipe(_passage!),
      ),
    );
  }
}
