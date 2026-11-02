import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/core/app_theme.dart';
import 'package:snippet/widgets/overlay_toast.dart';

void main() {
  testWidgets('an action can be tapped and a plain toast has none', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.cobaltSwipe(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showOverlayToast(
                    context,
                    'Saved to Photos',
                    actionLabel: 'View',
                    onAction: () => taps++,
                  ),
                  child: const Text('with action'),
                ),
                TextButton(
                  onPressed: () => showOverlayToast(context, 'Saved to Photos'),
                  child: const Text('plain'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('with action'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Saved to Photos'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);

    await tester.tap(find.byKey(const Key('overlay-toast-action')));
    await tester.pump();
    expect(taps, 1);
    expect(find.text('View'), findsNothing);

    await tester.tap(find.text('plain'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Saved to Photos'), findsOneWidget);
    expect(find.byKey(const Key('overlay-toast-action')), findsNothing);
    await tester.pumpAndSettle();
  });
}
