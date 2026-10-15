/// Remotely updatable content (verse suggestions, announcements, themes).
class ContentConfig {
  const ContentConfig({this.featuredVerses = const [], this.announcement});

  /// Suggested verses shown on the picker. Each entry is a reference triple.
  final List<FeaturedVerse> featuredVerses;
  final String? announcement;
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
      FeaturedVerse('JOH', 3, 16),
      FeaturedVerse('PSA', 23, 1, 3),
      FeaturedVerse('PHI', 4, 13),
      FeaturedVerse('ROM', 8, 28),
      FeaturedVerse('PRO', 3, 5, 6),
      FeaturedVerse('ISA', 41, 10),
    ],
  );
}
