import '../data/bible_models.dart';

/// Remotely updatable content (verse suggestions, announcements, themes).
class ContentConfig {
  const ContentConfig({this.featuredVerses = const [], this.announcement});

  /// Suggested verses; one is shown each day as the verse of the day.
  final List<FeaturedVerse> featuredVerses;
  final String? announcement;

  FeaturedVerse? verseOfTheDay(DateTime day) {
    if (featuredVerses.isEmpty) return null;
    final dayIndex = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(2024)).inDays;
    return featuredVerses[dayIndex % featuredVerses.length];
  }
}

class FeaturedVerse {
  const FeaturedVerse(
    this.bookId,
    this.chapter,
    this.startVerse, [
    this.endVerse,
  ]);

  final String bookId;
  final int chapter;
  final int startVerse;
  final int? endVerse;

  VerseRange get range => VerseRange(
    bookId: bookId,
    chapter: chapter,
    startVerse: startVerse,
    endVerse: endVerse,
  );
}

/// Source of hot-updatable content.
///
/// Swap [LocalContentConfigService] for a Firebase Remote Config / Firestore
/// implementation later; callers only depend on this interface.
abstract class ContentConfigService {
  Future<ContentConfig> load();
}

class LocalContentConfigService implements ContentConfigService {
  const LocalContentConfigService();

  @override
  Future<ContentConfig> load() async => const ContentConfig(
    featuredVerses: [
      FeaturedVerse('LAM', 3, 22, 23),
      FeaturedVerse('PSA', 46, 10),
      FeaturedVerse('ISA', 40, 31),
      FeaturedVerse('MIC', 6, 8),
      FeaturedVerse('JOS', 1, 9),
      FeaturedVerse('JOH', 3, 16),
      FeaturedVerse('PSA', 23, 1, 3),
      FeaturedVerse('PHI', 4, 13),
      FeaturedVerse('ROM', 8, 28),
      FeaturedVerse('PRO', 3, 5, 6),
      FeaturedVerse('ISA', 41, 10),
    ],
  );
}
