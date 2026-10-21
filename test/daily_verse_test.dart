import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/data/bible_repository.dart';
import 'package:snippet/services/content_config_service.dart';
import 'package:snippet/services/daily_verse.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled daily verse changes with the local calendar date', () async {
    final bible = BibleRepository();
    final expected = {
      DateTime(2026, 10, 20): 'Lamentations 3:22–23',
      DateTime(2026, 10, 21): 'Psalm 46:10',
      DateTime(2026, 10, 22): 'Isaiah 40:31',
    };
    for (final entry in expected.entries) {
      final passage = await loadDailyVerse(
        bible: bible,
        config: defaultContentConfig,
        translationId: 'kjv',
        day: entry.key,
      );
      expect(passage?.reference, entry.value, reason: '${entry.key}');
    }
    final fallback = await loadDailyVerse(
      bible: bible,
      config: const ContentConfig(),
      translationId: 'kjv',
      day: DateTime(2026, 10, 21),
    );
    expect(fallback?.reference, 'Genesis 1:1');
  });
}
