import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/data/app_settings.dart';
import 'package:snippet/data/bible_repository.dart';
import 'package:snippet/data/json_store.dart';
import 'package:snippet/services/content_config_service.dart';
import 'package:snippet/services/verse_reminder_service.dart';
import 'package:snippet/services/verse_reminder_sync.dart';

import 'support/verse_calendar.dart';

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
  _Recorder({this.answer = true});

  /// What the user picks when the prompt is shown; null means it never shows.
  final bool? answer;
  bool granted = false;
  int asked = 0;
  List<ReminderVerse>? scheduled;
  int? minutes;
  bool cancelled = false;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return granted = answer ?? false;
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

/// Rotating entries with Nov 5 left out, so that day uses the fallback.
final _calendar = rotatingCalendar(const [
  FeaturedVerse('PSA', 46, 10),
  FeaturedVerse('ISA', 40, 31),
  FeaturedVerse('LAM', 3, 22, 23),
], from: DateTime(2026, 10, 31))..remove('2026-11-05');

Future<void> _sync(_Recorder rec, AppSettings settings, {DateTime? now}) =>
    syncVerseReminders(
      reminders: rec,
      settings: settings,
      contentConfig: CalendarContent(_calendar),
      bible: BibleRepository(),
      now: now ?? DateTime(2026, 10, 15),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'asks only while notifications are off, then schedules at 8am',
    () async {
      final settings = AppSettings(_MemoryStore());
      final rec = _Recorder();
      await _sync(rec, settings);
      await _sync(rec, settings);
      expect(rec.asked, 1);
      expect(rec.scheduled, hasLength(reminderWindowDays));
      expect(rec.minutes, 480);
      expect(rec.scheduled!.first.text, isNotEmpty);
    },
  );

  test('schedules nothing when permission is denied', () async {
    final rec = _Recorder(answer: false);
    await _sync(rec, AppSettings(_MemoryStore()));
    expect(rec.cancelled, isTrue);
    expect(rec.scheduled, isNull);
  });

  test('a prompt that never appeared is shown again next launch', () async {
    final settings = AppSettings(_MemoryStore());
    final missed = _Recorder(answer: null);
    await _sync(missed, settings);
    expect(missed.scheduled, isNull);
    final rec = _Recorder();
    await _sync(rec, settings);
    expect(rec.asked, 1);
    expect(rec.scheduled, hasLength(reminderWindowDays));
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
          final verse = _calendar[localDateKey(day)] ?? genesisFallback;
          final expected = await bible.passage('web', verse.range);
          final reminder = rec.scheduled![i];
          expect(reminder.day, day);
          expect(reminder.reference, expected!.reference);
          expect(reminder.text, expected.text);
        }
      },
    );
  }
}
