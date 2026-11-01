import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/data/bible_models.dart';
import 'package:snippet/data/json_library_backend.dart';
import 'package:snippet/data/json_store.dart';
import 'package:snippet/data/library_repository.dart';
import 'package:snippet/data/saved_card.dart';
import 'package:snippet/services/auth_service.dart';

SavedCard _card(String id) => SavedCard(
  id: id,
  translationId: 'kjv',
  range: const VerseRange(bookId: 'PSA', chapter: 46, startVerse: 10),
  reference: 'Psalm 46:10',
  text: 'Be still, and know that I am God',
  styleId: 'vigil',
  variantId: 'gilt',
  savedAt: DateTime.utc(2026, 1, int.parse(id)),
);

/// Anonymous sign-in that can be upgraded to Google, keeping the uid.
class _LinkingAuth extends LocalAuthService {
  final _changes = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get authStateChanges => _changes.stream;

  @override
  bool get supportsGoogleSignIn => true;

  @override
  bool get supportsEmailSignIn => false;

  void _set(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  Future<AppUser> signInAnonymously() async {
    _set(const AppUser(id: 'u1', isAnonymous: true));
    return _user!;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    _set(const AppUser(id: 'u1', displayName: 'Ada'));
    return _user;
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<AppUser> createAccountWithEmail(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordReset(String email) => throw UnimplementedError();

  @override
  Future<void> confirmPassword(String password) async {}

  @override
  Future<void> signOut() async => _set(null);

  @override
  Future<void> deleteAccount() => signOut();
}

void main() {
  test('library follows the signed-in user', () async {
    final auth = LocalAuthService();
    final store = MemoryJsonStore();
    final library = LibraryRepository(
      auth: auth,
      backendFor: (user) =>
          JsonLibraryBackend(store, document: 'library_${user.id}'),
    );
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    await library.load();
    expect(library.isLoaded, isTrue);
    expect(library.cards, isEmpty);
    expect(() => library.add(_card('1')), throwsStateError);

    final user = await auth.signInAnonymously();
    await library.add(_card('1'));
    await library.add(_card('2'));
    await settle();
    expect(library.cards.map((c) => c.id), ['2', '1']);
    expect(await store.read('library_${user.id}'), hasLength(2));

    await auth.signOut();
    await settle();
    expect(library.cards, isEmpty);

    library.dispose();
  });

  test('phone-only cards stay local, then move up on linking Google', () async {
    final auth = _LinkingAuth();
    final phone = MemoryJsonStore();
    final cloud = MemoryJsonStore();
    final library = LibraryRepository(
      auth: auth,
      backendFor: (user) => user.isAnonymous
          ? JsonLibraryBackend(phone)
          : JsonLibraryBackend(cloud),
    );
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    await library.load();
    await auth.signInAnonymously();
    await library.add(_card('1'));
    await library.add(_card('2'));
    await settle();
    expect(await phone.read('library'), hasLength(2));
    expect(await cloud.read('library'), isNull);

    await auth.signInWithGoogle();
    await settle();
    await library.carrying;
    await settle();
    expect(await cloud.read('library'), hasLength(2));
    expect(await phone.read('library'), isNull);
    expect(library.cards.map((c) => c.id), ['2', '1']);

    library.dispose();
  });
}
