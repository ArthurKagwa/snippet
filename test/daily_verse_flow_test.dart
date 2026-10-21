import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/app.dart';
import 'package:snippet/data/bible_repository.dart';
import 'package:snippet/services/auth_service.dart';
import 'package:snippet/data/json_store.dart';
import 'package:snippet/features/export/export_sheet.dart';
import 'package:snippet/features/home/home_greeting.dart';
import 'package:snippet/features/home/verse_picker_panel.dart';
import 'package:snippet/features/shell/shell_controller.dart';
import 'package:snippet/services/content_config_service.dart';
import 'package:snippet/services/verse_reminder_service.dart';

class _Content implements ContentConfigService {
  const _Content([this.verses = const [FeaturedVerse('LAM', 3, 22, 23)]]);

  final List<FeaturedVerse> verses;
  @override
  Future<ContentConfig> load() async => ContentConfig(featuredVerses: verses);
}

class _Reminders extends NoopVerseReminderService {
  final opens = StreamController<ReminderVerse?>.broadcast();
  List<ReminderVerse> verses = [];
  ReminderVerse? launch;

  @override
  Stream<ReminderVerse?> get notificationOpens => opens.stream;

  @override
  Future<ReminderVerse?> launchVerse() async => launch;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule({
    required List<ReminderVerse> verses,
    required int minutesAfterMidnight,
  }) async => this.verses = verses;
}

class _NamedAuth extends LocalAuthService {
  final changes = StreamController<AppUser?>.broadcast();
  AppUser? user;

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> get authStateChanges => changes.stream;

  void setUser(AppUser? value) {
    user = value;
    changes.add(value);
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pumpAndSettle();
}

Future<void> _boot(
  WidgetTester tester, {
  _Reminders? reminders,
  AuthService? auth,
  ContentConfigService? contentConfig,
  DateTime Function()? now,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SnippetApp(
      store: MemoryJsonStore(),
      contentConfig: contentConfig ?? const _Content(),
      reminders: reminders,
      auth: auth,
      now: now,
    ),
  );
  await _settle(tester);
}

const _psalm = FeaturedVerse('PSA', 46, 10);
const _isaiah = FeaturedVerse('ISA', 40, 31);

Future<ReminderVerse> _reminder(DateTime day, FeaturedVerse verse) async {
  final p = await BibleRepository().passage('kjv', verse.range);
  return ReminderVerse(
    day: day,
    range: p!.range,
    translationId: p.translationId,
    reference: p.reference,
    text: p.text,
  );
}

VersePickerPanel _picker(WidgetTester tester) =>
    tester.widget<VersePickerPanel>(find.byType(VersePickerPanel));

void main() {
  setUp(rootBundle.clear);

  test('greeting follows local morning, afternoon, and evening boundaries', () {
    for (final hour in [0, 7, 11]) {
      expect(
        HomeGreeting.forTime(DateTime(2026, 10, 21, hour)),
        'Good morning',
      );
    }
    for (final hour in [12, 16]) {
      expect(
        HomeGreeting.forTime(DateTime(2026, 10, 21, hour)),
        'Good afternoon',
      );
    }
    for (final hour in [17, 23]) {
      expect(
        HomeGreeting.forTime(DateTime(2026, 10, 21, hour)),
        'Good evening',
      );
    }
  });

  testWidgets(
    'Home defaults to the complete daily passage and shows its local date',
    (tester) async {
      final reminders = _Reminders();
      addTearDown(reminders.opens.close);
      await _boot(tester, reminders: reminders);
      var picker = tester.widget<VersePickerPanel>(
        find.byType(VersePickerPanel),
      );
      expect(picker.range, const FeaturedVerse('LAM', 3, 22, 23).range);
      await tester.tap(find.byKey(const Key('today-verse')));
      await _settle(tester);
      picker = tester.widget<VersePickerPanel>(find.byType(VersePickerPanel));
      expect(picker.range, const FeaturedVerse('LAM', 3, 22, 23).range);
      expect(find.text('TODAY'), findsOneWidget);
      final date = MaterialLocalizations.of(
        tester.element(find.byType(VersePickerPanel)),
      ).formatFullDate(DateTime.now());
      expect(find.text(date), findsOneWidget);
      expect(find.text('Lamentations 3:22–23'), findsOneWidget);
      expect(find.textContaining(picker.passage!.text), findsOneWidget);
      final text = tester.widget<Text>(find.byKey(const Key('passage-text')));
      expect(text.maxLines, isNull);
      expect(reminders.verses.first.text, picker.passage!.text);
      expect(reminders.verses.first.reference, picker.passage!.reference);
      expect(find.text(HomeGreeting.forTime(DateTime.now())), findsOneWidget);
    },
  );

  for (final verses in [
    <FeaturedVerse>[],
    [const FeaturedVerse('BAD', 99, 1)],
  ]) {
    testWidgets('unavailable daily content $verses falls back to Genesis 1:1', (
      tester,
    ) async {
      final reminders = _Reminders();
      addTearDown(reminders.opens.close);
      await _boot(
        tester,
        reminders: reminders,
        contentConfig: _Content(verses),
      );
      final picker = tester.widget<VersePickerPanel>(
        find.byType(VersePickerPanel),
      );
      expect(picker.range, const FeaturedVerse('GEN', 1, 1).range);
      expect(picker.passage!.text, contains('In the beginning'));
      expect(reminders.verses.first.text, picker.passage!.text);
      expect(find.text('Genesis 1:1'), findsOneWidget);
    });
  }

  testWidgets('greeting follows signed-in profile name and sign-out', (
    tester,
  ) async {
    final auth = _NamedAuth();
    addTearDown(auth.changes.close);
    final greeting = HomeGreeting.forTime(DateTime.now());
    auth.setUser(const AppUser(id: 'named', displayName: '  Daniel Mugisha  '));
    await _boot(tester, auth: auth);
    expect(find.text('$greeting, Daniel Mugisha'), findsOneWidget);
    auth.setUser(const AppUser(id: 'renamed', displayName: 'Sarah'));
    await tester.pumpAndSettle();
    expect(find.text('$greeting, Sarah'), findsOneWidget);
    auth.setUser(null);
    await tester.pumpAndSettle();
    expect(find.text(greeting), findsOneWidget);
    auth.setUser(
      const AppUser(id: 'anon', displayName: 'Guest', isAnonymous: true),
    );
    await tester.pumpAndSettle();
    expect(find.text(greeting), findsOneWidget);
  });

  testWidgets(
    'notification tap returns Home and selects the daily verse after browsing',
    (tester) async {
      final reminders = _Reminders();
      addTearDown(reminders.opens.close);
      await _boot(tester, reminders: reminders);
      var picker = tester.widget<VersePickerPanel>(
        find.byType(VersePickerPanel),
      );
      picker.onChapter(2);
      await _settle(tester);
      await tester.tap(find.byKey(const Key('swipe-styles')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-styles')));
      await tester.pumpAndSettle();
      reminders.opens.add(null);
      await _settle(tester);
      picker = tester.widget<VersePickerPanel>(find.byType(VersePickerPanel));
      expect(picker.range, const FeaturedVerse('LAM', 3, 22, 23).range);
      expect(find.text('TODAY'), findsOneWidget);
      final shell = ShellScope.read(
        tester.element(find.byType(VersePickerPanel)),
      );
      expect(shell.tab, ShellTab.home);
    },
  );

  testWidgets(
    'swipe version toggle preserves design and updates export and Home',
    (tester) async {
      await _boot(tester);
      await tester.tap(find.byKey(const Key('swipe-styles')));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byKey(const Key('style-pager')),
        const Offset(0, -400),
        1500,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('WEB'));
      await _settle(tester);
      expect(find.text('Riso Loud'), findsOneWidget);
      await tester.tap(find.byKey(const Key('export-card')));
      await tester.pumpAndSettle();
      final sheet = tester.widget<ExportSheet>(find.byType(ExportSheet));
      final expected = await BibleRepository().passage(
        'web',
        const FeaturedVerse('LAM', 3, 22, 23).range,
      );
      expect(sheet.content.text, expected!.text);
      expect(sheet.content.translation, 'WEB');
      expect(sheet.style.id, 'riso');
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-home')));
      await _settle(tester);
      final picker = tester.widget<VersePickerPanel>(
        find.byType(VersePickerPanel),
      );
      expect(picker.translationId, 'web');
      expect(picker.passage!.text, expected.text);
    },
  );

  testWidgets(
    'All styles keeps bottom navigation usable and system back returns to swiping',
    (tester) async {
      await _boot(tester);
      await tester.tap(find.byKey(const Key('nav-styles')));
      await tester.pumpAndSettle();
      expect(find.text('All styles'), findsOneWidget);
      expect(find.byKey(const Key('nav-home')).hitTestable(), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('style-pager')), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-styles')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-saved')));
      await _settle(tester);
      expect(find.text('Nothing saved yet'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-styles')));
      await tester.pumpAndSettle();
      expect(find.text('All styles'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-home')));
      await tester.pumpAndSettle();
      expect(find.text('TODAY'), findsOneWidget);
    },
  );

  testWidgets(
    'cold launch from a notification shows its verse in Today and the picker',
    (tester) async {
      final day = DateTime(2026, 10, 21);
      final reminders = _Reminders()
        ..launch = await tester.runAsync(() => _reminder(day, _isaiah));
      addTearDown(reminders.opens.close);
      await _boot(
        tester,
        reminders: reminders,
        contentConfig: const _Content([_psalm]),
        now: () => DateTime(2026, 10, 21, 8, 5),
      );
      expect(find.text('Isaiah 40:31'), findsOneWidget);
      expect(_picker(tester).range, _isaiah.range);
      expect(find.textContaining('Psalm'), findsNothing);
    },
  );

  testWidgets('a notification tapped while running retargets Today', (
    tester,
  ) async {
    final reminders = _Reminders();
    addTearDown(reminders.opens.close);
    await _boot(
      tester,
      reminders: reminders,
      contentConfig: const _Content([_psalm]),
      now: () => DateTime(2026, 10, 21, 8, 5),
    );
    expect(_picker(tester).range, _psalm.range);
    final tapped = await tester.runAsync(
      () => _reminder(DateTime(2026, 10, 21), _isaiah),
    );
    reminders.opens.add(tapped);
    await _settle(tester);
    expect(find.text('Isaiah 40:31'), findsOneWidget);
    expect(_picker(tester).range, _isaiah.range);
  });

  testWidgets(
    'scheduled reminders, Today and the picker agree across local midnight',
    (tester) async {
      var clock = DateTime(2026, 10, 21, 23, 59);
      final reminders = _Reminders();
      addTearDown(reminders.opens.close);
      await _boot(
        tester,
        reminders: reminders,
        contentConfig: const _Content([_psalm, _isaiah]),
        now: () => clock,
      );
      final tomorrow = reminders.verses.first;
      expect(tomorrow.day, DateTime(2026, 10, 22));
      final today = _picker(tester).passage!;
      expect(tomorrow.range, isNot(today.range));
      expect(find.text(today.reference), findsOneWidget);

      clock = DateTime(2026, 10, 22, 0, 1);
      await tester.pump(const Duration(minutes: 1));
      await _settle(tester);
      expect(find.text(tomorrow.reference), findsOneWidget);
      expect(_picker(tester).range, tomorrow.range);
      final date = MaterialLocalizations.of(
        tester.element(find.byType(VersePickerPanel)),
      ).formatFullDate(DateTime(2026, 10, 22));
      expect(find.text(date), findsOneWidget);
    },
  );

  testWidgets('resuming on a new day refreshes; same-day resume keeps Home', (
    tester,
  ) async {
    var clock = DateTime(2026, 10, 21, 9);
    await _boot(
      tester,
      contentConfig: const _Content([_psalm, _isaiah]),
      now: () => clock,
    );
    final first = _picker(tester).range;
    _picker(tester).onChapter(2);
    await _settle(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _settle(tester);
    expect(_picker(tester).range.chapter, 2);

    _picker(tester).onChapter(first.chapter);
    await _settle(tester);
    _picker(tester).onStart(first.startVerse);
    await _settle(tester);
    clock = DateTime(2026, 10, 22, 7);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _settle(tester);
    expect(_picker(tester).range, isNot(first));
    expect(
      find.text(_picker(tester).passage!.reference),
      findsAtLeastNWidgets(1),
    );
  });
}
