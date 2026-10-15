import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import 'library_backend.dart';
import 'saved_card.dart';

typedef LibraryBackendFactory = LibraryBackend Function(AppUser user);

/// The signed-in user's saved cards, newest first. Empty when signed out.
///
/// Follows [AuthService]: each user gets their own [LibraryBackend]
/// (Firestore when Firebase is set up, a local file otherwise).
class LibraryRepository extends ChangeNotifier {
  LibraryRepository({required this._auth, required this.backendFor});

  final AuthService _auth;
  final LibraryBackendFactory backendFor;

  String? _userId;
  LibraryBackend? _backend;
  StreamSubscription<List<SavedCard>>? _cardsSub;
  StreamSubscription<AppUser?>? _authSub;
  List<SavedCard> _cards = const [];
  bool _loaded = false;
  Object? _error;

  List<SavedCard> get cards => _cards;
  bool get isLoaded => _loaded;

  /// Why the library could not be read (e.g. no network on first load).
  Object? get error => _error;

  /// Starts following the signed-in user. Safe to call repeatedly.
  Future<void> load() async {
    _authSub ??= _auth.authStateChanges.listen(_follow);
    // Callers may be mid-build; notify listeners on the next microtask.
    await Future<void>.value();
    _follow(_auth.currentUser);
  }

  void _follow(AppUser? user) {
    if (user?.id == _userId && (_backend != null || user == null)) {
      if (user == null && !_loaded) _setCards(const []);
      return;
    }
    _cardsSub?.cancel();
    _backend?.dispose();
    _userId = user?.id;
    _backend = user == null ? null : backendFor(user);
    _error = null;
    if (_backend == null) {
      _setCards(const []);
      return;
    }
    _loaded = false;
    notifyListeners();
    _cardsSub = _backend!.watch().listen(
      _setCards,
      onError: (Object e) {
        debugPrint('Library unavailable: $e');
        _error = e;
        _setCards(const []);
      },
    );
  }

  void _setCards(List<SavedCard> cards) {
    _cards = cards;
    _loaded = true;
    notifyListeners();
  }

  LibraryBackend get _current {
    // Sign-in may have just happened; don't wait for the auth stream.
    _follow(_auth.currentUser);
    final backend = _backend;
    if (backend == null) throw StateError('Sign in to use the library');
    return backend;
  }

  Future<void> add(SavedCard card) => _current.put(card);

  Future<void> remove(String id) => _current.delete(id);

  Future<void> clear() async {
    if (_auth.currentUser == null) return;
    await _current.deleteAll();
  }

  @override
  void dispose() {
    _cardsSub?.cancel();
    _authSub?.cancel();
    _backend?.dispose();
    super.dispose();
  }
}
