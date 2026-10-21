import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/cards/card_content.dart';
import 'package:snippet/services/content_config_service.dart';
import 'package:snippet/services/firebase_content_config_service.dart';

void main() {
  group('FeaturedVerse.tryParse', () {
    test('reads single verses and ranges', () {
      final v = FeaturedVerse.tryParse('PSA 46:10')!;
      expect(
        [v.bookId, v.chapter, v.startVerse, v.endVerse],
        ['PSA', 46, 10, null],
      );
      final r = FeaturedVerse.tryParse(' 1co 13:4-7 ')!;
      expect(
        [r.bookId, r.chapter, r.startVerse, r.endVerse],
        ['1CO', 13, 4, 7],
      );
    });

    test('rejects malformed references', () {
      for (final ref in ['', 'Psalm 46:10', 'PSA 46', 'PSA 46:10-9', 'PSA']) {
        expect(FeaturedVerse.tryParse(ref), isNull, reason: ref);
      }
    });

    test('ref round-trips', () {
      for (final ref in ['PSA 46:10', 'LAM 3:22-23', '1CO 13:4-7']) {
        expect(FeaturedVerse.tryParse(ref)!.ref, ref);
      }
    });
  });

  group('parseRemoteContent', () {
    test('reads the dated calendar, fallback verse and announcement', () {
      final c = parseRemoteContent(
        verseCalendarJson:
            '{"2026-10-21": "ISA 40:31", "2026-10-22": "bad", '
            '"2026-13-01": "JOH 3:16", "Oct 23": "ROM 8:28", '
            '"2026-10-24": 7, "2026-10-25": "lam 3:22-23"}',
        fallbackVerse: ' psa 46:10 ',
        announcement: '  New styles this week  ',
      );
      expect(c.verseCalendar.map((k, v) => MapEntry(k, v.ref)), {
        '2026-10-21': 'ISA 40:31',
        '2026-10-25': 'LAM 3:22-23',
      });
      expect(c.verseOfTheDay(DateTime(2026, 10, 21, 23, 59))!.ref, 'ISA 40:31');
      expect(c.verseOfTheDay(DateTime(2026, 10, 22)), isNull);
      expect(c.fallbackVerse.ref, 'PSA 46:10');
      expect(c.announcement, 'New styles this week');
    });

    test('bad or empty input leaves an empty calendar and Genesis 1:1', () {
      for (final json in ['not json', '{}', '[]', '["JOH 3:16"]']) {
        for (final fallback in ['', 'nope']) {
          final c = parseRemoteContent(
            verseCalendarJson: json,
            fallbackVerse: fallback,
            announcement: '   ',
          );
          expect(c.verseCalendar, isEmpty, reason: json);
          expect(c.fallbackVerse.ref, 'GEN 1:1', reason: fallback);
          expect(c.announcement, isNull);
        }
      }
    });

    test('uses remote invite message and share caption', () {
      final c = parseRemoteContent(
        verseCalendarJson: '{}',
        announcement: '',
        inviteMessage: ' Join me on Snippet ',
        shareCaption: '{reference}',
      );
      expect(c.inviteMessage, 'Join me on Snippet');
      expect(c.shareCaption, '{reference}');
    });

    test('falls back to bundled invite and caption when empty', () {
      final c = parseRemoteContent(
        verseCalendarJson: '{}',
        announcement: '',
        inviteMessage: '  ',
      );
      expect(c.inviteMessage, defaultInviteMessage);
      expect(c.shareCaption, defaultShareCaption);
    });
  });

  test('captionFor fills in the placeholders', () {
    const content = CardContent(
      text: 'Be still, and know that I am God',
      reference: 'Psalm 46:10',
      translation: 'KJV',
    );
    expect(const ContentConfig().captionFor(content), 'PSALM 46:10 · KJV');
    expect(
      const ContentConfig(
        shareCaption: '"{verse}" {reference} ({translation})\n#snippet',
      ).captionFor(content),
      '"Be still, and know that I am God" Psalm 46:10 (KJV)\n#snippet',
    );
  });

  test('remoteconfig.template.json has a readable calendar and fallback', () {
    final template = jsonDecode(
      File('remoteconfig.template.json').readAsStringSync(),
    );
    String text(String key) =>
        template['parameters'][key]['defaultValue']['value'] as String;
    final calendar =
        jsonDecode(text(FirebaseContentConfigService.verseCalendarKey))
            as Map<String, dynamic>;
    final parsed = parseRemoteContent(
      verseCalendarJson: text(FirebaseContentConfigService.verseCalendarKey),
      fallbackVerse: text(FirebaseContentConfigService.fallbackVerseKey),
      announcement: '',
    );
    expect(calendar, isNotEmpty);
    expect(parsed.verseCalendar.keys, calendar.keys);
    expect(parsed.fallbackVerse.ref, defaultContentConfig.fallbackVerse.ref);
    final styles =
        template['parameters'][FirebaseContentConfigService
            .cardStylesKey]['defaultValue']['value'];
    expect(jsonDecode(styles as String), <String, dynamic>{});
    expect(
      text(FirebaseContentConfigService.inviteMessageKey),
      defaultInviteMessage,
    );
    expect(
      text(FirebaseContentConfigService.shareCaptionKey),
      defaultShareCaption,
    );
  });
}
