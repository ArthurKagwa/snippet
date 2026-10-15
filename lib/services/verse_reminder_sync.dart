import 'package:flutter/foundation.dart';

import '../data/app_settings.dart';
import '../data/bible_repository.dart';
import 'content_config_service.dart';
import 'verse_reminder_service.dart';

/// Days of verses scheduled ahead; the app refills the window on launch.
const int reminderWindowDays = 14;

/// The reminder fires at 8:00 in the device's local time.
const int reminderMinutesAfterMidnight = 8 * 60;

/// Keeps the verse-of-the-day notification in step with the OS permission.
/// The first call asks for permission (the user opts in through the system
/// prompt); afterwards it only schedules while notifications stay allowed.
Future<void> syncVerseReminders({
  required VerseReminderService reminders,
  required AppSettings settings,
  required ContentConfigService contentConfig,
  required BibleRepository bible,
  DateTime? now,
}) async {
  try {
    final bool allowed;
    if (settings.reminderPrompted) {
      allowed = await reminders.hasPermission();
    } else {
      settings.reminderPrompted = true;
      allowed = await reminders.requestPermission();
    }
    if (!allowed) {
      await reminders.cancel();
      return;
    }
    final config = await contentConfig.load();
    final today = now ?? DateTime.now();
    final verses = <ReminderVerse>[];
    for (var i = 0; i < reminderWindowDays; i++) {
      final featured = config.verseOfTheDay(
        DateTime(today.year, today.month, today.day + i),
      );
      if (featured == null) continue;
      final p = await bible.passage(
        settings.defaultTranslationId,
        featured.range,
      );
      if (p != null) {
        verses.add(ReminderVerse(reference: p.reference, text: p.text));
      }
    }
    if (verses.isEmpty) return;
    await reminders.schedule(
      verses: verses,
      minutesAfterMidnight: reminderMinutesAfterMidnight,
    );
  } catch (e) {
    debugPrint('Could not sync verse reminders: $e');
  }
}
