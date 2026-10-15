import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/data/app_settings.dart';
import 'package:snippet/data/bible_repository.dart';
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

Future<void> _sync(_Recorder rec, AppSettings settings) => syncVerseReminders(
  reminders: rec,
  settings: settings,
  contentConfig: const LocalContentConfigService(),
  bible: BibleRepository(),
  now: DateTime(2026, 10, 15),
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
}
