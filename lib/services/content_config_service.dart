import '../cards/card_style_overrides.dart';
import '../data/bible_models.dart';

/// Remotely updatable content (verse suggestions, announcements, styles).
class ContentConfig {
  const ContentConfig({
    this.featuredVerses = const [],
    this.announcement,
    this.cardStyles = CardStyleOverrides.none,
  });

  /// Suggested verses; one is shown each day as the verse of the day.
  final List<FeaturedVerse> featuredVerses;
  final String? announcement;

  /// Changes to the bundled card styles; see CardCatalog.apply.
  final CardStyleOverrides cardStyles;

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

  static final _refPattern = RegExp(
    r'^([0-9A-Z]{3})\s+(\d+):(\d+)(?:-(\d+))?$',
  );

  /// Parses a reference like `PSA 46:10` or `LAM 3:22-23` (book ids as in
  /// the Bible assets). Returns null when it doesn't match.
  static FeaturedVerse? tryParse(String ref) {
    final m = _refPattern.firstMatch(ref.trim().toUpperCase());
    if (m == null) return null;
    final start = int.parse(m[3]!);
    final end = m[4] == null ? null : int.parse(m[4]!);
    if (end != null && end < start) return null;
    return FeaturedVerse(m[1]!, int.parse(m[2]!), start, end);
  }

  /// The reference [tryParse] reads back.
  String get ref =>
      '$bookId $chapter:$startVerse${endVerse == null ? '' : '-$endVerse'}';

  VerseRange get range => VerseRange(
    bookId: bookId,
    chapter: chapter,
    startVerse: startVerse,
    endVerse: endVerse,
  );
}

/// Source of hot-updatable content.
///
/// [LocalContentConfigService] serves the bundled defaults;
/// FirebaseContentConfigService serves Firebase Remote Config.
abstract class ContentConfigService {
  Future<ContentConfig> load();
}

/// Bundled content, also the Remote Config defaults.
const defaultContentConfig = ContentConfig(
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

class LocalContentConfigService implements ContentConfigService {
  const LocalContentConfigService();

  @override
  Future<ContentConfig> load() async => defaultContentConfig;
}
