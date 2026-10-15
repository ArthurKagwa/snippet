import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'library_backend.dart';
import 'saved_card.dart';

/// Cards in Firestore at `users/{uid}/cards/{cardId}` (see firestore.rules).
/// Firestore's local cache makes this work offline and syncs later.
class FirestoreLibraryBackend extends LibraryBackend {
  FirestoreLibraryBackend(FirebaseFirestore db, String uid)
    : _cards = db.collection('users').doc(uid).collection('cards');

  final CollectionReference<Map<String, dynamic>> _cards;

  /// Writes land in the local cache immediately, but their futures only
  /// complete once the server acknowledges them, which never happens while
  /// offline. Wait briefly so real failures (e.g. permission denied)
  /// surface, then trust the cache.
  static Future<void> _settle(Future<void> write) =>
      write.timeout(const Duration(seconds: 4), onTimeout: () {});

  @override
  Stream<List<SavedCard>> watch() => _cards
      .orderBy('savedAt', descending: true)
      .snapshots()
      .map((s) => [for (final d in s.docs) SavedCard.fromJson(d.data())]);

  @override
  Future<void> put(SavedCard card) =>
      _settle(_cards.doc(card.id).set(card.toJson()));

  @override
  Future<void> delete(String id) => _settle(_cards.doc(id).delete());

  @override
  Future<void> deleteAll() async {
    final docs = (await _cards.get()).docs;
    // Batches are capped at 500 writes.
    for (var i = 0; i < docs.length; i += 500) {
      final batch = _cards.firestore.batch();
      for (final d in docs.skip(i).take(500)) {
        batch.delete(d.reference);
      }
      await _settle(batch.commit());
    }
  }
}
