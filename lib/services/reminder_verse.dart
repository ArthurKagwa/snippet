import 'dart:convert';

import '../data/bible_models.dart';
import 'content_config_service.dart';

/// The dated passage carried by a notification, including after a cold launch.
class ReminderVerse {
  const ReminderVerse({
    required this.day,
    required this.range,
    required this.translationId,
    required this.reference,
    required this.text,
  });

  final DateTime day;
  final VerseRange range;
  final String translationId;
  final String reference;
  final String text;

  String get payload => jsonEncode({
    'day': localDateKey(day),
    'bookId': range.bookId,
    'chapter': range.chapter,
    'startVerse': range.startVerse,
    'endVerse': range.endVerse,
    'translationId': translationId,
    'reference': reference,
    'text': text,
  });

  static ReminderVerse? fromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final raw = jsonDecode(payload);
      if (raw is! Map<String, dynamic>) return null;
      final day = DateTime.tryParse(raw['day'] as String? ?? '');
      final book = raw['bookId'];
      final chapter = raw['chapter'];
      final start = raw['startVerse'];
      final end = raw['endVerse'];
      final translation = raw['translationId'];
      final reference = raw['reference'];
      final text = raw['text'];
      if (day == null ||
          book is! String ||
          chapter is! int ||
          start is! int ||
          end is! int ||
          chapter < 1 ||
          start < 1 ||
          end < start ||
          translation is! String ||
          reference is! String ||
          reference.isEmpty ||
          text is! String ||
          text.isEmpty) {
        return null;
      }
      return ReminderVerse(
        day: day,
        range: VerseRange(
          bookId: book,
          chapter: chapter,
          startVerse: start,
          endVerse: end,
        ),
        translationId: translation,
        reference: reference,
        text: text,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
