import 'package:flutter/foundation.dart';

import 'json_store.dart';
import 'saved_card.dart';

/// Saved cards, newest first. Persists through [JsonStore].
///
/// Local for now; a Firestore-backed version can replace this once
/// Firebase is set up (cards are already plain JSON).
class LibraryRepository extends ChangeNotifier {
  LibraryRepository(this._store);

  static const String _doc = 'library';

  final JsonStore _store;
  List<SavedCard> _cards = const [];
  bool _loaded = false;

  List<SavedCard> get cards => _cards;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    Object? raw;
    try {
      raw = await _store.read(_doc);
    } catch (e) {
      debugPrint('Library unavailable: $e');
    }
    _cards = [
      if (raw is List)
        for (final j in raw) SavedCard.fromJson(j as Map<String, dynamic>),
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(SavedCard card) async {
    await load();
    _cards = [card, ..._cards];
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _cards = _cards.where((c) => c.id != id).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _cards = const [];
    notifyListeners();
    await _store.delete(_doc);
  }

  Future<void> _persist() =>
      _store.write(_doc, [for (final c in _cards) c.toJson()]);
}
