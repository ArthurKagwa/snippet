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
      for (final v in defaultContentConfig.featuredVerses) {
        final back = FeaturedVerse.tryParse(v.ref)!;
        expect(back.ref, v.ref);
      }
    });
  });

  group('parseRemoteContent', () {
    test('uses remote verses and announcement', () {
      final c = parseRemoteContent(
        featuredVersesJson: '["JOH 3:16", "bad", 7, "ROM 8:28"]',
        announcement: '  New styles this week  ',
      );
      expect(c.featuredVerses.map((v) => v.ref), ['JOH 3:16', 'ROM 8:28']);
      expect(c.announcement, 'New styles this week');
    });

    test('falls back to bundled verses on bad or empty input', () {
      for (final json in ['not json', '{}', '[]', '["nope"]']) {
        final c = parseRemoteContent(
          featuredVersesJson: json,
          announcement: '   ',
        );
        expect(
          c.featuredVerses,
          defaultContentConfig.featuredVerses,
          reason: json,
        );
        expect(c.announcement, isNull);
      }
    });

    test('uses remote invite message and share caption', () {
      final c = parseRemoteContent(
        featuredVersesJson: '[]',
        announcement: '',
        inviteMessage: ' Join me on Snippet ',
        shareCaption: '{reference}',
      );
      expect(c.inviteMessage, 'Join me on Snippet');
      expect(c.shareCaption, '{reference}');
    });

    test('falls back to bundled invite and caption when empty', () {
      final c = parseRemoteContent(
        featuredVersesJson: '[]',
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

  test('remoteconfig.template.json matches the bundled defaults', () {
    final template = jsonDecode(
      File('remoteconfig.template.json').readAsStringSync(),
    );
    final value =
        template['parameters'][FirebaseContentConfigService
            .featuredVersesKey]['defaultValue']['value'];
    expect(jsonDecode(value as String), [
      for (final v in defaultContentConfig.featuredVerses) v.ref,
    ]);
    final styles =
        template['parameters'][FirebaseContentConfigService
            .cardStylesKey]['defaultValue']['value'];
    expect(jsonDecode(styles as String), <String, dynamic>{});
    String text(String key) =>
        template['parameters'][key]['defaultValue']['value'] as String;
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
