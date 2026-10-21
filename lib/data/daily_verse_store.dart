import 'bible_models.dart';
import 'bible_repository.dart';
import 'json_store.dart';
import '../services/content_config_service.dart';
import '../services/daily_verse.dart';

/// Keeps the daily references used by Home and already-scheduled reminders.
class DailyVerseStore {
  DailyVerseStore(this._store);

  final JsonStore _store;
  final Map<String, VerseRange> _ranges = {};
  Future<void>? _loaded;
  Future<void> _writes = Future.value();

  String _key(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<void> _load() => _loaded ??= () async {
    final raw = await _store.read('daily_verses');
    if (raw is! Map) return;
    for (final entry in raw.entries) {
      final value = entry.value;
      if (entry.key is! String || value is! Map) continue;
      final book = value['bookId'];
      final chapter = value['chapter'];
      final start = value['startVerse'];
      final end = value['endVerse'];
      if (book is String &&
          chapter is int &&
          start is int &&
          end is int &&
          chapter > 0 &&
          start > 0 &&
          end >= start) {
        _ranges[entry.key as String] = VerseRange(
          bookId: book,
          chapter: chapter,
          startVerse: start,
          endVerse: end,
        );
      }
    }
  }();

  Future<void> remember(DateTime day, VerseRange range) async {
    await _load();
    _ranges[_key(day)] = range;
    final cutoff = _key(DateTime(day.year, day.month, day.day - 16));
    _ranges.removeWhere((key, _) => key.compareTo(cutoff) < 0);
    final snapshot = {
      for (final entry in _ranges.entries)
        entry.key: {
          'bookId': entry.value.bookId,
          'chapter': entry.value.chapter,
          'startVerse': entry.value.startVerse,
          'endVerse': entry.value.endVerse,
        },
    };
    final write = _writes.then((_) => _store.write('daily_verses', snapshot));
    _writes = write.catchError((Object _) {});
    await write;
  }

  Future<Passage?> resolve({
    required DateTime day,
    required String translationId,
    required BibleRepository bible,
    required ContentConfig config,
  }) async {
    await _load();
    final range = _ranges[_key(day)];
    if (range != null) {
      final saved = await bible.passage(translationId, range);
      if (saved != null) return saved;
    }
    final passage = await loadDailyVerse(
      bible: bible,
      config: config,
      translationId: translationId,
      day: day,
    );
    if (passage != null) await remember(day, passage.range);
    return passage;
  }
}
