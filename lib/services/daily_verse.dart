import '../data/bible_models.dart';
import '../data/bible_repository.dart';
import 'content_config_service.dart';

const genesisFallbackRange = VerseRange(
  bookId: 'GEN',
  chapter: 1,
  startVerse: 1,
);

/// Home and reminders resolve the same daily passage and fallback.
Future<Passage?> loadDailyVerse({
  required BibleRepository bible,
  required ContentConfig config,
  required String translationId,
  required DateTime day,
}) async {
  final featured = config.verseOfTheDay(day);
  if (featured != null) {
    final passage = await bible.passage(translationId, featured.range);
    if (passage != null) return passage;
  }
  return bible.passage(translationId, genesisFallbackRange);
}
