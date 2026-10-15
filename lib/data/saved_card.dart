import 'package:flutter/foundation.dart';

import '../cards/card_content.dart';
import 'bible_models.dart';
import 'bible_repository.dart';

/// A card the user kept: the passage plus the look they chose.
@immutable
class SavedCard {
  const SavedCard({
    required this.id,
    required this.translationId,
    required this.range,
    required this.reference,
    required this.text,
    required this.styleId,
    required this.variantId,
    required this.savedAt,
  });

  factory SavedCard.fromPassage(
    Passage p, {
    required String styleId,
    required String variantId,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    return SavedCard(
      id: '${at.microsecondsSinceEpoch}',
      translationId: p.translationId,
      range: p.range,
      reference: p.reference,
      text: p.text,
      styleId: styleId,
      variantId: variantId,
      savedAt: at,
    );
  }

  factory SavedCard.fromJson(Map<String, dynamic> j) => SavedCard(
    id: j['id'] as String,
    translationId: j['translationId'] as String,
    range: VerseRange(
      bookId: j['bookId'] as String,
      chapter: j['chapter'] as int,
      startVerse: j['startVerse'] as int,
      endVerse: j['endVerse'] as int,
    ),
    reference: j['reference'] as String,
    text: j['text'] as String,
    styleId: j['styleId'] as String,
    variantId: j['variantId'] as String,
    savedAt: DateTime.parse(j['savedAt'] as String),
  );

  final String id;
  final String translationId;
  final VerseRange range;
  final String reference;
  final String text;
  final String styleId;
  final String variantId;
  final DateTime savedAt;

  Passage get passage => Passage(
    range: range,
    reference: reference,
    text: text,
    translationId: translationId,
  );

  CardContent get content => CardContent(
    text: text,
    reference: reference,
    translation: BibleRepository.shortNames[translationId] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'translationId': translationId,
    'bookId': range.bookId,
    'chapter': range.chapter,
    'startVerse': range.startVerse,
    'endVerse': range.endVerse,
    'reference': reference,
    'text': text,
    'styleId': styleId,
    'variantId': variantId,
    'savedAt': savedAt.toUtc().toIso8601String(),
  };
}
