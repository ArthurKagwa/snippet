import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/data/bible_repository.dart';
import 'package:snippet/services/content_config_service.dart';
import 'package:snippet/services/daily_verse.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'daily verse follows the calendar by local date, then falls back',
    () async {
      final bible = BibleRepository();
      Future<String?> reference(ContentConfig config, DateTime day) async =>
          (await loadDailyVerse(
            bible: bible,
            config: config,
            translationId: 'kjv',
            day: day,
          ))?.reference;

      const config = ContentConfig(
        verseCalendar: {
          '2026-10-21': FeaturedVerse('ISA', 40, 31),
          '2026-10-22': FeaturedVerse('LAM', 3, 22, 23),
          '2026-10-23': FeaturedVerse('BAD', 99, 1),
        },
        fallbackVerse: FeaturedVerse('PSA', 46, 10),
      );
      expect(
        await reference(config, DateTime(2026, 10, 21, 0, 0)),
        'Isaiah 40:31',
      );
      expect(
        await reference(config, DateTime(2026, 10, 21, 23, 59)),
        'Isaiah 40:31',
      );
      expect(
        await reference(config, DateTime(2026, 10, 22)),
        'Lamentations 3:22–23',
      );
      // Unknown book and missing days both use the configured fallback.
      expect(await reference(config, DateTime(2026, 10, 23)), 'Psalm 46:10');
      expect(await reference(config, DateTime(2026, 10, 24)), 'Psalm 46:10');

      const broken = ContentConfig(fallbackVerse: FeaturedVerse('BAD', 1, 1));
      expect(await reference(broken, DateTime(2026, 10, 21)), 'Genesis 1:1');
      expect(
        await reference(defaultContentConfig, DateTime(2026, 10, 21)),
        'Genesis 1:1',
      );
    },
  );
}
