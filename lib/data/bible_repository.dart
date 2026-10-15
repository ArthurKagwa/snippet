import 'dart:convert';

import 'package:flutter/services.dart';

import 'bible_models.dart';

/// Loads bundled translations from assets and answers verse queries.
///
/// Texts are public domain (KJV, WEB) and live in `assets/bibles/`.
class BibleRepository {
  BibleRepository({
    AssetBundle? bundle,
    this.translationIds = const ['kjv', 'web'],
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final List<String> translationIds;
  final Map<String, Translation> _cache = {};

  static const Map<String, String> shortNames = {'kjv': 'KJV', 'web': 'WEB'};

  Future<Translation> translation(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final raw = await _bundle.loadString('assets/bibles/$id.json');
    final parsed = Translation.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    return _cache[id] = parsed;
  }

  Future<List<Book>> books(String translationId) async =>
      (await translation(translationId)).books;

  /// Returns the passage for [range], or null if the range is invalid.
  /// Verses missing in the translation are skipped.
  Future<Passage?> passage(String translationId, VerseRange range) async {
    final t = await translation(translationId);
    final book = t.bookById(range.bookId);
    if (book == null) return null;
    if (range.chapter < 1 || range.chapter > book.chapterCount) return null;
    final count = book.verseCount(range.chapter);
    if (range.startVerse < 1 ||
        range.endVerse < range.startVerse ||
        range.endVerse > count) {
      return null;
    }
    final verses = book.chapters[range.chapter - 1]
        .sublist(range.startVerse - 1, range.endVerse)
        .where((v) => v.isNotEmpty);
    final text = verses.join(' ');
    if (text.isEmpty) return null;
    return Passage(
      reference: formatReference(book.name, range),
      text: text,
      translationId: translationId,
    );
  }

  static String formatReference(String bookName, VerseRange r) {
    final verses = r.startVerse == r.endVerse
        ? '${r.startVerse}'
        : '${r.startVerse}-${r.endVerse}';
    return '$bookName ${r.chapter}:$verses';
  }
}
