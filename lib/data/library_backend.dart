import 'saved_card.dart';

/// Where one user's saved cards live (local file, Firestore, ...).
abstract class LibraryBackend {
  /// Current cards, newest first; emits again on every change.
  Stream<List<SavedCard>> watch();
  Future<void> put(SavedCard card);
  Future<void> delete(String id);
  Future<void> deleteAll();

  /// Releases listeners/resources when the user changes.
  void dispose() {}
}
