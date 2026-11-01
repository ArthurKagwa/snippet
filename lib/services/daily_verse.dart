import '../data/bible_models.dart';
import '../data/bible_repository.dart';
import 'content_config_service.dart';

/// The one resolver for a day's verse, shared by Home and reminders: the
/// calendar entry, else the configured fallback, else Genesis 1:1.
Future<Passage?> loadDailyVerse({
  required BibleRepository bible,
  required ContentConfig config,
  required String translationId,
  required DateTime day,
}) async {
  for (final verse in [
    ?config.verseOfTheDay(day),
    config.fallbackVerse,
    genesisFallback,
  ]) {
    final passage = await bible.passage(translationId, verse.range);
    if (passage != null) return passage;
  }
  return null;
}
