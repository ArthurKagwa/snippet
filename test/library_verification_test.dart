import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/data/bible_models.dart';
import 'package:snippet/data/json_library_backend.dart';
import 'package:snippet/data/json_store.dart';
import 'package:snippet/data/library_repository.dart';
import 'package:snippet/data/saved_card.dart';
import 'package:snippet/services/auth_service.dart';

import 'support/test_email_auth.dart';

void main() {
  final card = SavedCard(
    id: '1',
    translationId: 'kjv',
    range: const VerseRange(bookId: 'PSA', chapter: 46, startVerse: 10),
    reference: 'Psalm 46:10',
    text: 'Be still',
    styleId: 'vigil',
    variantId: 'gilt',
    savedAt: DateTime.utc(2026),
  );
  const pending = AppUser(id: 'user', email: 'a@b.co', usesPassword: true);
  const verified = AppUser(
    id: 'user',
    email: 'a@b.co',
    usesPassword: true,
    emailVerified: true,
  );

  test('restored unverified accounts cannot load or write a library', () async {
    final auth = TestEmailAuth({})..setUser(pending);
    final store = MemoryJsonStore();
    var opens = 0;
    final library = LibraryRepository(
      auth: auth,
      backendFor: (_) {
        opens++;
        return JsonLibraryBackend(store);
      },
    );
    addTearDown(library.dispose);
    await library.load();
    expect(opens, 0);
    expect(library.cards, isEmpty);
    expect(() => library.add(card), throwsA(isA<AuthException>()));
    expect(await store.read('library'), isNull);
    auth.setUser(verified);
    await library.add(card);
    expect(opens, 1);
    expect(await store.read('library'), hasLength(1));
  });

  test('phone-only cards migrate only after verification', () async {
    final auth = TestEmailAuth({})
      ..setUser(const AppUser(id: 'user', isAnonymous: true));
    final local = MemoryJsonStore();
    final cloud = MemoryJsonStore();
    var cloudOpens = 0;
    final library = LibraryRepository(
      auth: auth,
      backendFor: (user) {
        if (user.isAnonymous) return JsonLibraryBackend(local);
        cloudOpens++;
        return JsonLibraryBackend(cloud);
      },
    );
    addTearDown(library.dispose);
    await library.load();
    await library.add(card);
    auth.setUser(pending);
    await Future<void>.delayed(Duration.zero);
    expect(cloudOpens, 0);
    expect(library.cards, isEmpty);
    expect(await local.read('library'), hasLength(1));
    expect(await cloud.read('library'), isNull);
    auth.setUser(verified);
    await Future<void>.delayed(Duration.zero);
    await library.carrying;
    expect(cloudOpens, 1);
    expect(await cloud.read('library'), hasLength(1));
    expect(await local.read('library'), isNull);
  });

  test('pending accounts can still clear data for account deletion', () async {
    final auth = TestEmailAuth({})..setUser(verified);
    final store = MemoryJsonStore();
    final library = LibraryRepository(
      auth: auth,
      backendFor: (_) => JsonLibraryBackend(store),
    );
    addTearDown(library.dispose);
    await library.load();
    await library.add(card);
    auth.setUser(pending);
    await library.clear();
    expect(await store.read('library'), isNull);
  });
}
