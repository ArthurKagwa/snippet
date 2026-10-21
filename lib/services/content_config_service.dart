import '../cards/card_content.dart';
import '../cards/card_style_overrides.dart';
import '../data/bible_models.dart';

/// Remotely updatable content (verse suggestions, announcements, styles).
class ContentConfig {
  const ContentConfig({
    this.verseCalendar = const {},
    this.fallbackVerse = genesisFallback,
    this.announcement,
    this.cardStyles = CardStyleOverrides.none,
    this.inviteMessage = defaultInviteMessage,
    this.shareCaption = defaultShareCaption,
  });

  /// Verse of the day by local date key (see [localDateKey]).
  final Map<String, FeaturedVerse> verseCalendar;

  /// The verse for days missing from [verseCalendar].
  final FeaturedVerse fallbackVerse;
  final String? announcement;

  /// Changes to the bundled card styles; see CardCatalog.apply.
  final CardStyleOverrides cardStyles;

  /// Text sent by "Invite a friend".
  final String inviteMessage;

  /// Caption sent with a shared card. `{reference}` (Psalm 46:10),
  /// `{translation}` (KJV), `{verse}` (the verse text) and
  /// `{reference_line}` (PSALM 46:10 · KJV) are filled in.
  final String shareCaption;

  String captionFor(CardContent content) => shareCaption
      .replaceAll('{reference_line}', content.referenceLine)
      .replaceAll('{reference}', content.reference)
      .replaceAll('{translation}', content.translation)
      .replaceAll('{verse}', content.text)
      .trim();

  FeaturedVerse? verseOfTheDay(DateTime day) =>
      verseCalendar[localDateKey(day)];
}

/// `2026-10-21` for the phone's local calendar day of [day].
String localDateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

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

const defaultInviteMessage =
    "I've been turning Bible verses into quote cards with Snippet. "
    'Try it: https://snippetverses.app';

const defaultShareCaption = '{reference_line}';

/// Used when the calendar and the configured fallback both miss.
const genesisFallback = FeaturedVerse('GEN', 1, 1);

/// Bundled content, also the Remote Config defaults. The calendar is empty,
/// so until Remote Config arrives every day is the fallback, Genesis 1:1.
const defaultContentConfig = ContentConfig();

class LocalContentConfigService implements ContentConfigService {
  const LocalContentConfigService();

  @override
  Future<ContentConfig> load() async => defaultContentConfig;
}
