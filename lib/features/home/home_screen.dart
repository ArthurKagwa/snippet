import 'dart:async';

import 'package:flutter/material.dart';

import '../../cards/card_catalog.dart';
import '../../core/theme/snippet_colors.dart';
import '../../data/app_settings.dart';
import '../../data/bible_models.dart';
import '../../services/content_config_service.dart';
import '../../services/daily_verse.dart';
import '../../services/services.dart';
import '../../services/verse_reminder_sync.dart';
import '../../services/verse_reminder_service.dart';
import '../shell/shell_controller.dart';
import 'book_picker_sheet.dart';
import 'daily_verse_listener.dart';
import 'home_greeting.dart';
import 'home_header.dart';
import 'verse_of_day.dart';
import 'verse_picker_panel.dart';

/// Home selects today's verse, falling back to Genesis 1:1 when unavailable.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _translationId = 'kjv';
  List<Book> _books = const [];
  VerseRange _range = genesisFallback.range;
  Passage? _passage;
  Passage? _votd;
  String? _announcement;
  bool _loading = true;
  Object? _error;
  bool _started = false;
  DateTime _today = DateUtils.dateOnly(DateTime.now());
  int _request = 0;
  ShellController? _shell;

  /// Today's tapped notification; it was scheduled from an older config, so
  /// it outranks a calendar edit made since, until the day ends.
  ReminderVerse? _tapped;

  Services get _services => Services.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _shell = ShellScope.read(context)..addListener(_followSwipe);
      _init();
    }
  }

  Future<void> _init() async {
    final s = _services;
    try {
      await s.settings.load();
      if (!mounted) return;
      _translationId = s.settings.defaultTranslationId;
      final launch = await s.reminders.launchVerse();
      if (!mounted) return;
      await _rememberNotification(launch);
      await _loadTranslation(selectDaily: launch == null || _isToday(launch));
      syncAppVerseReminders(_services);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _shell?.removeListener(_followSwipe);
    super.dispose();
  }

  bool _isToday(ReminderVerse verse) =>
      DateUtils.isSameDay(verse.day, _services.now());

  Future<void> _rememberNotification(ReminderVerse? verse) async {
    final s = _services;
    if (verse == null ||
        !s.bible.translationIds.contains(verse.translationId)) {
      return;
    }
    final passage = await s.bible.passage(verse.translationId, verse.range);
    if (passage == null || !mounted) return;
    if (_isToday(verse)) _tapped = verse;
    _range = passage.range;
    _translationId = passage.translationId;
  }

  Future<void> _onNotification(ReminderVerse? verse) async {
    _shell!.select(ShellTab.home);
    await _rememberNotification(verse);
    if (mounted) {
      await _loadTranslation(selectDaily: verse == null || _isToday(verse));
    }
  }

  /// Rolls Home to the new local day; same-day ticks and resumes are no-ops so
  /// a version picked in Styles is not overwritten.
  void _refreshDay() {
    if (_loading || _error != null) return;
    if (DateUtils.isSameDay(_today, _services.now())) return;
    final shared = _shell!.passage;
    final onDaily = (shared?.range ?? _range) == _votd?.range;
    if (shared != null) {
      _range = shared.range;
      _translationId = shared.translationId;
    }
    _loadTranslation(selectDaily: onDaily);
    syncAppVerseReminders(_services);
  }

  void _followSwipe() {
    final p = _shell!.passage;
    if (_shell!.tab != ShellTab.home || p == null || _loading) return;
    if (p.range == _range && p.translationId == _translationId) return;
    _range = p.range;
    _translationId = p.translationId;
    _loadTranslation();
  }

  Future<void> _loadTranslation({bool selectDaily = false}) async {
    final request = ++_request;
    final s = _services;
    final id = _translationId;
    final day = DateUtils.dateOnly(s.now());
    final books = await s.bible.books(id);
    final config = await s.contentConfig.load();
    CardCatalog.apply(config.cardStyles);
    final tapped = _tapped;
    final votd =
        (tapped != null && DateUtils.isSameDay(tapped.day, day)
            ? await s.bible.passage(id, tapped.range)
            : null) ??
        await loadDailyVerse(
          bible: s.bible,
          config: config,
          translationId: id,
          day: day,
        );
    final range = selectDaily ? votd?.range ?? genesisFallback.range : _range;
    final passage = await s.bible.passage(id, range);
    if (!mounted || request != _request) return;
    setState(() {
      _today = day;
      _range = range;
      _books = books;
      _passage = passage;
      _votd = votd;
      _announcement = config.announcement;
    });
    _share(passage);
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
    final request = ++_request;
    final r = _clamp(range);
    setState(() => _range = r);
    final p = await _services.bible.passage(_translationId, r);
    if (mounted && request == _request) {
      _share(p);
      setState(() => _passage = p);
    }
  }

  Future<void> _setTranslation(String id) async {
    if (id == _translationId) return;
    setState(() => _translationId = id);
    _services.settings.defaultTranslationId = id;
    await _loadTranslation();
    syncAppVerseReminders(_services);
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DailyVerseListener(
      onRefresh: _refreshDay,
      onNotification: _onNotification,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(announcement: _announcement),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: HomeGreeting(),
              ),
              if (_votd != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: VerseOfDay(
                    passage: _votd!,
                    day: _today,
                    onSelect: () => _setRange(_votd!.range),
                  ),
                ),
              Expanded(child: _panel()),
            ],
          ],
        ),
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
