import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/data/bible_models.dart';
import 'package:snippet/data/bible_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled assets', () {
    final repo = BibleRepository();

    for (final id in ['kjv', 'web']) {
      test('$id has 66 books and John 3:16', () async {
        final books = await repo.books(id);
        expect(books.length, 66);
        final p = await repo.passage(
          id,
          const VerseRange(bookId: 'JOH', chapter: 3, startVerse: 16),
        );
        expect(p, isNotNull);
        expect(p!.reference, 'John 3:16');
        expect(p.text, contains('God so loved the world'));
      });
    }

    test('KJV and WEB differ', () async {
      const r = VerseRange(bookId: 'PSA', chapter: 23, startVerse: 1);
      final k = await repo.passage('kjv', r);
      final w = await repo.passage('web', r);
      expect(k!.text, isNot(w!.text));
    });

    test('range joins verses and formats reference', () async {
      final p = await repo.passage(
        'kjv',
        const VerseRange(
          bookId: 'PSA',
          chapter: 23,
          startVerse: 1,
          endVerse: 3,
        ),
      );
      expect(p!.reference, 'Psalms 23:1-3');
      expect(p.text, contains('The LORD is my shepherd'));
    });

    test('invalid ranges return null', () async {
      expect(
        await repo.passage(
          'kjv',
          const VerseRange(bookId: 'JOH', chapter: 99, startVerse: 1),
        ),
        isNull,
      );
      expect(
        await repo.passage(
          'kjv',
          const VerseRange(
            bookId: 'JOH',
            chapter: 3,
            startVerse: 5,
            endVerse: 2,
          ),
        ),
        isNull,
      );
      expect(
        await repo.passage(
          'kjv',
          const VerseRange(bookId: 'XXX', chapter: 1, startVerse: 1),
        ),
        isNull,
      );
    });
  });

  test('skips verses absent in a translation', () async {
    final bundle = _FakeBundle(
      jsonEncode({
        'id': 't',
        'name': 'T',
        'license': 'PD',
        'books': [
          {
            'id': 'GEN',
            'name': 'Genesis',
            'chapters': [
              ['a', '', 'c'],
            ],
          },
        ],
      }),
    );
    final repo = BibleRepository(bundle: bundle, translationIds: ['t']);
    final p = await repo.passage(
      't',
      const VerseRange(bookId: 'GEN', chapter: 1, startVerse: 1, endVerse: 3),
    );
    expect(p!.text, 'a c');
  });
}

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.json);
  final String json;
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(json)));
}
