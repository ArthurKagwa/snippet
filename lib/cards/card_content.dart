import 'package:flutter/foundation.dart';

/// The words on a card.
@immutable
class CardContent {
  const CardContent({
    required this.text,
    required this.reference,
    required this.translation,
  });

  /// Verse text.
  final String text;

  /// Display reference, e.g. "Psalm 46:10".
  final String reference;

  /// Short translation label, e.g. "KJV".
  final String translation;

  /// "PSALM 46:10 · KJV"
  String get referenceLine =>
      '${reference.toUpperCase()}${translation.isEmpty ? '' : ' · $translation'}';

  /// The book part of [reference]: "Song of Solomon" from "Song of
  /// Solomon 1:1". The whole reference when it carries no chapter:verse.
  String get referenceBook => _chapterVerse.firstMatch(_ref)?.group(1) ?? _ref;

  /// The chapter and verse: "46:10", "23:1–3". Empty when [reference]
  /// carries none, so a card can set it on its own line instead of
  /// dropping it when the book name is long.
  String get referenceNumbers => _chapterVerse.firstMatch(_ref)?.group(2) ?? '';

  String get _ref => reference.trim();

  /// A trailing "chapter:verse" or "chapter:verse–verse".
  static final RegExp _chapterVerse = RegExp(
    r'^(.*\S)\s+(\d+:\d+(?:[–-]\d+)?)$',
  );
}
