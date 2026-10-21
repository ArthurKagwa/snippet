import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'verse_reminder_service.dart';

/// [VerseReminderService] on device-local notifications. Each day is its own
/// one-shot notification carrying that day's verse, so the text is right
/// without the app running; the app tops the window up on every launch.
class LocalVerseReminderService implements VerseReminderService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _ready;
  final _opens = StreamController<ReminderVerse?>.broadcast();

  @override
  Stream<ReminderVerse?> get notificationOpens => _opens.stream;

  @override
  Future<ReminderVerse?> launchVerse() async {
    await _init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true
        ? ReminderVerse.fromPayload(details?.notificationResponse?.payload)
        : null;
  }

  static const _channelId = 'verse_of_the_day';
  static const _firstId = 1000;

  Future<void> _init() => _ready ??= () async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('Timezone lookup failed, using UTC: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _opens.add(ReminderVerse.fromPayload(response.payload)),
    );
  }();

  @override
  Future<bool> hasPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return (await ios?.checkPermissions())?.isEnabled ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> schedule({
    required List<ReminderVerse> verses,
    required int minutesAfterMidnight,
  }) async {
    await _init();
    await _plugin.cancelAllPendingNotifications();
    final now = tz.TZDateTime.now(tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Verse of the day',
        channelDescription: 'A daily verse to turn into a card',
        icon: 'ic_notification',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (var i = 0; i < verses.length; i++) {
      final v = verses[i];
      final scheduled = tz.TZDateTime(
        tz.local,
        v.day.year,
        v.day.month,
        v.day.day,
        minutesAfterMidnight ~/ 60,
        minutesAfterMidnight % 60,
      );
      if (!scheduled.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: _firstId + i,
        title: v.reference,
        body: v.text,
        payload: v.payload,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancel() async {
    await _init();
    await _plugin.cancelAllPendingNotifications();
  }
}
