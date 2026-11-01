import 'reminder_verse.dart';

export 'reminder_verse.dart';

/// Schedules the daily verse-of-the-day notification.
abstract class VerseReminderService {
  /// Taps while the app is running.
  Stream<ReminderVerse?> get notificationOpens;

  Future<ReminderVerse?> launchVerse();

  /// Whether notifications are currently allowed, without asking.
  Future<bool> hasPermission();

  /// Asks the OS for notification permission; false when denied.
  Future<bool> requestPermission();

  /// Replaces pending reminders with one per entry on its [ReminderVerse.day]
  /// at [minutesAfterMidnight] in the device's local time.
  Future<void> schedule({
    required List<ReminderVerse> verses,
    required int minutesAfterMidnight,
  });

  Future<void> cancel();
}

/// Used in tests and where notifications are unavailable.
class NoopVerseReminderService implements VerseReminderService {
  const NoopVerseReminderService();

  @override
  Stream<ReminderVerse?> get notificationOpens => const Stream.empty();

  @override
  Future<ReminderVerse?> launchVerse() async => null;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule({
    required List<ReminderVerse> verses,
    required int minutesAfterMidnight,
  }) async {}

  @override
  Future<void> cancel() async {}
}
