import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/app_settings.dart';
import '../data/bible_repository.dart';
import 'content_config_service.dart';
import 'daily_verse.dart';
import 'services.dart';
import 'verse_reminder_service.dart';

/// Days of verses scheduled ahead; the app refills the window on launch.
const int reminderWindowDays = 14;

/// The reminder fires at 8:00 in the device's local time.
const int reminderMinutesAfterMidnight = 8 * 60;

/// Keeps the verse-of-the-day notification in step with the OS permission.
/// Asks whenever notifications are off: Android stops showing the prompt after
/// two refusals and iOS after one, while a prompt that never appeared (say the
/// app was backgrounded) is shown again on a later launch.
Future<void> syncVerseReminders({
  required VerseReminderService reminders,
  required AppSettings settings,
  required ContentConfigService contentConfig,
  required BibleRepository bible,
  DateTime? now,
}) async {
  try {
    final allowed =
        await reminders.hasPermission() || await reminders.requestPermission();
    if (!allowed) {
      await reminders.cancel();
      return;
    }
    final config = await contentConfig.load();
    final today = now ?? DateTime.now();
    final todayAtReminder = DateTime(
      today.year,
      today.month,
      today.day,
      reminderMinutesAfterMidnight ~/ 60,
      reminderMinutesAfterMidnight % 60,
    );
    final firstDayOffset = todayAtReminder.isAfter(today) ? 0 : 1;
    final verses = <ReminderVerse>[];
    for (var i = 0; i < reminderWindowDays; i++) {
      final day = DateTime(
        today.year,
        today.month,
        today.day + firstDayOffset + i,
      );
      final p = await loadDailyVerse(
        bible: bible,
        config: config,
        translationId: settings.defaultTranslationId,
        day: day,
      );
      if (p != null) {
        verses.add(
          ReminderVerse(
            day: day,
            range: p.range,
            translationId: p.translationId,
            reference: p.reference,
            text: p.text,
          ),
        );
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

/// Fire-and-forget sync with the app's services, so reminders and Home share
/// one config and clock.
void syncAppVerseReminders(Services s) => unawaited(
  syncVerseReminders(
    reminders: s.reminders,
    settings: s.settings,
    contentConfig: s.contentConfig,
    bible: s.bible,
    now: s.now(),
  ),
);
