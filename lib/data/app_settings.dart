import 'package:flutter/foundation.dart';

import '../cards/card_shape.dart';
import 'bible_models.dart';
import 'json_store.dart';

/// A verse the user opened recently (shown as chips on Home).
@immutable
class RecentVerse {
  const RecentVerse({required this.range, required this.label});

  factory RecentVerse.fromJson(Map<String, dynamic> j) => RecentVerse(
    range: VerseRange(
      bookId: j['bookId'] as String,
      chapter: j['chapter'] as int,
      startVerse: j['startVerse'] as int,
      endVerse: j['endVerse'] as int,
    ),
    label: j['label'] as String,
  );

  final VerseRange range;
  final String label;

  Map<String, dynamic> toJson() => {
    'bookId': range.bookId,
    'chapter': range.chapter,
    'startVerse': range.startVerse,
    'endVerse': range.endVerse,
    'label': label,
  };
}

/// User preferences, persisted through [JsonStore].
class AppSettings extends ChangeNotifier {
  AppSettings(this._store);

  static const String _doc = 'settings';
  static const int maxRecent = 3;

  final JsonStore _store;

  String _translationId = 'kjv';
  CardShape _shape = CardShape.portrait;
  bool _showMark = false;
  bool _swipeHints = true;
  List<RecentVerse> _recent = const [];

  String get defaultTranslationId => _translationId;
  CardShape get defaultShape => _shape;
  bool get showMark => _showMark;
  bool get swipeHints => _swipeHints;
  List<RecentVerse> get recent => _recent;

  /// Missing or unreadable settings fall back to defaults.
  Future<void> load() async {
    final Object? raw;
    try {
      raw = await _store.read(_doc);
    } catch (e) {
      debugPrint('Settings unavailable, using defaults: $e');
      return;
    }
    if (raw is! Map<String, dynamic>) return;
    _translationId = raw['translation'] as String? ?? _translationId;
    _shape = CardShape.byName(raw['shape'] as String?);
    _showMark = raw['showMark'] as bool? ?? _showMark;
    _swipeHints = raw['swipeHints'] as bool? ?? _swipeHints;
    _recent = [
      for (final r in raw['recent'] as List<dynamic>? ?? const [])
        RecentVerse.fromJson(r as Map<String, dynamic>),
    ];
    notifyListeners();
  }

  set defaultTranslationId(String id) => _update(() => _translationId = id);
  set defaultShape(CardShape s) => _update(() => _shape = s);
  set showMark(bool v) => _update(() => _showMark = v);
  set swipeHints(bool v) => _update(() => _swipeHints = v);

  void addRecent(RecentVerse v) => _update(() {
    _recent = [
      v,
      ..._recent.where((r) => r.range != v.range),
    ].take(maxRecent).toList();
  });

  void _update(VoidCallback change) {
    change();
    notifyListeners();
    _store
        .write(_doc, {
          'translation': _translationId,
          'shape': _shape.name,
          'showMark': _showMark,
          'swipeHints': _swipeHints,
          'recent': [for (final r in _recent) r.toJson()],
        })
        .catchError((Object e) => debugPrint('Could not save settings: $e'));
  }
}
