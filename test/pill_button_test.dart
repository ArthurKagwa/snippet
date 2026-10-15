import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/widgets/pill_button.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget button) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: button)),
    ),
  );

  testWidgets('spins and ignores taps until async work finishes', (
    tester,
  ) async {
    var taps = 0;
    final work = Completer<void>();
    await pump(
      tester,
      PillButton(
        label: 'Save',
        foreground: Colors.black,
        onPressed: () {
          taps++;
          return work.future;
        },
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(taps, 1);

    work.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(taps, 2);
  });

  testWidgets('a synchronous tap shows no spinner', (tester) async {
    var taps = 0;
    await pump(
      tester,
      PillButton(
        label: 'Go',
        foreground: Colors.black,
        onPressed: () => taps++,
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(taps, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('busy shows the spinner and blocks taps', (tester) async {
    var taps = 0;
    await pump(
      tester,
      PillButton(
        label: 'Share',
        foreground: Colors.black,
        busy: true,
        onPressed: () => taps++,
      ),
    );
    await tester.tap(find.text('Share'));
    await tester.pump();
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
