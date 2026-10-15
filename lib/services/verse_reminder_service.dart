/// Schedules the daily verse-of-the-day notification.
abstract class VerseReminderService {
  /// Whether notifications are currently allowed, without asking.
  Future<bool> hasPermission();

  /// Asks the OS for notification permission; false when denied.
  Future<bool> requestPermission();

  /// Replaces any pending reminders with one per entry in [verses], the
  /// first on the next occurrence of [minutesAfterMidnight] local time.
  Future<void> schedule({
    required List<ReminderVerse> verses,
    required int minutesAfterMidnight,
  });

  Future<void> cancel();
}

class ReminderVerse {
  const ReminderVerse({required this.reference, required this.text});

  final String reference;
  final String text;
}

/// Used in tests and where notifications are unavailable.
class NoopVerseReminderService implements VerseReminderService {
  const NoopVerseReminderService();

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
