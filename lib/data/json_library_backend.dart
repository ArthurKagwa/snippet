import 'dart:async';

import 'json_store.dart';
import 'library_backend.dart';
import 'saved_card.dart';

/// Cards in one JSON document on this device. Used when Firebase is not
/// available (offline stand-in auth, tests).
class JsonLibraryBackend extends LibraryBackend {
  JsonLibraryBackend(this._store, {this.document = 'library'});

  final JsonStore _store;
  final String document;
  final StreamController<List<SavedCard>> _changes =
      StreamController<List<SavedCard>>.broadcast();
  List<SavedCard> _cards = const [];
  Future<void>? _ready;

  /// One shared initial read, so a write can't race it and be overwritten.
  Future<void> _ensureLoaded() => _ready ??= () async {
    final raw = await _store.read(document);
    _cards = [
      if (raw is List)
        for (final j in raw) SavedCard.fromJson(j as Map<String, dynamic>),
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }();

  @override
  Stream<List<SavedCard>> watch() {
    StreamSubscription<List<SavedCard>>? changes;
    late final StreamController<List<SavedCard>> out;
    out = StreamController<List<SavedCard>>(
      onListen: () {
        // Listen first so nothing written during the load is missed.
        changes = _changes.stream.listen(out.add);
        _ensureLoaded().then((_) => out.add(_cards), onError: out.addError);
      },
      onCancel: () => changes?.cancel(),
    );
    return out.stream;
  }

  Future<void> _save(List<SavedCard> cards) async {
    _cards = cards;
    _changes.add(cards);
    await _store.write(document, [for (final c in cards) c.toJson()]);
  }

  @override
  Future<void> put(SavedCard card) async {
    await _ensureLoaded();
    await _save([card, ..._cards.where((c) => c.id != card.id)]);
  }

  @override
  Future<void> delete(String id) async {
    await _ensureLoaded();
    await _save(_cards.where((c) => c.id != id).toList());
  }

  @override
  Future<void> deleteAll() async {
    await _ensureLoaded();
    _cards = const [];
    _changes.add(const []);
    await _store.delete(document);
  }

  @override
  void dispose() => _changes.close();
}
