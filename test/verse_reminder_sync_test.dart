import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/data/app_settings.dart';
import 'package:snippet/data/bible_repository.dart';
import 'package:snippet/data/daily_verse_store.dart';
import 'package:snippet/data/json_store.dart';
import 'package:snippet/services/content_config_service.dart';
import 'package:snippet/services/verse_reminder_service.dart';
import 'package:snippet/services/verse_reminder_sync.dart';

class _MemoryStore implements JsonStore {
  final Map<String, Object?> docs = {};

  @override
  Future<Object?> read(String name) async => docs[name];

  @override
  Future<void> write(String name, Object? value) async => docs[name] = value;

  @override
  Future<void> delete(String name) async => docs.remove(name);
}

class _Recorder extends NoopVerseReminderService {
  _Recorder({this.allowed = true});

  final bool allowed;
  int asked = 0;
  List<ReminderVerse>? scheduled;
  int? minutes;
  bool cancelled = false;

  @override
  Future<bool> hasPermission() async => allowed;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return allowed;
  }

  @override
  Future<void> schedule({
    required List<ReminderVerse> verses,
    required int minutesAfterMidnight,
  }) async {
    scheduled = verses;
    minutes = minutesAfterMidnight;
  }

  @override
  Future<void> cancel() async => cancelled = true;
}

Future<void> _sync(_Recorder rec, AppSettings settings, {DateTime? now}) =>
    syncVerseReminders(
      reminders: rec,
      settings: settings,
      contentConfig: const LocalContentConfigService(),
      bible: BibleRepository(),
      dailyVerses: DailyVerseStore(_MemoryStore()),
      now: now ?? DateTime(2026, 10, 15),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asks once, then schedules a window at 8am', () async {
    final settings = AppSettings(_MemoryStore());
    final rec = _Recorder();
    await _sync(rec, settings);
    await _sync(rec, settings);
    expect(rec.asked, 1);
    expect(rec.scheduled, hasLength(reminderWindowDays));
    expect(rec.minutes, 480);
    expect(rec.scheduled!.first.text, isNotEmpty);
  });

  test('schedules nothing when permission is denied', () async {
    final rec = _Recorder(allowed: false);
    await _sync(rec, AppSettings(_MemoryStore()));
    expect(rec.cancelled, isTrue);
    expect(rec.scheduled, isNull);
  });

  for (final hour in [7, 8, 15, 23]) {
    test(
      'at $hour:00 each reminder matches its scheduled day and version',
      () async {
        final settings = AppSettings(_MemoryStore())
          ..defaultTranslationId = 'web';
        final rec = _Recorder();
        await _sync(rec, settings, now: DateTime(2026, 10, 31, hour));
        final bible = BibleRepository();
        final firstDay = DateTime(2026, 10, hour < 8 ? 31 : 32);
        for (var i = 0; i < reminderWindowDays; i++) {
          final day = DateTime(firstDay.year, firstDay.month, firstDay.day + i);
          final expected = await bible.passage(
            'web',
            defaultContentConfig.verseOfTheDay(day)!.range,
          );
          final reminder = rec.scheduled![i];
          expect(reminder.day, day);
          expect(reminder.reference, expected!.reference);
          expect(reminder.text, expected.text);
        }
      },
    );
  }
}
