import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/features/swipe/swipe_page_physics.dart';

void main() {
  /// Drags a 400px pager by [steps] (negative = towards the next page), one
  /// per frame, then lifts. Small trailing steps make it ease off like a
  /// real thumb, so the release is not a fling.
  Future<void> swipe(WidgetTester tester, List<double> steps) async {
    var t = Duration.zero;
    final gesture = await tester.startGesture(const Offset(200, 200));
    for (final dx in steps) {
      t += const Duration(milliseconds: 16);
      await gesture.moveBy(Offset(dx, 0), timeStamp: t);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up(timeStamp: t);
    await tester.pumpAndSettle();
  }

  const easeOff = <double>[-25, -25, -25, -25, -10, -5, -3, -2, -1, -1, -1];

  Future<PageController> pager(
    WidgetTester tester, {
    required bool eager,
    int initialPage = 0,
  }) async {
    final controller = PageController(initialPage: initialPage);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: PageView(
              controller: controller,
              pageSnapping: !eager,
              physics: eager ? const SwipePagePhysics() : null,
              children: List.generate(3, (_) => const SizedBox.expand()),
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  testWidgets('stock pager springs back from an easing swipe', (tester) async {
    final controller = await pager(tester, eager: false);
    await swipe(tester, easeOff);
    expect(controller.page, 0);
  });

  testWidgets('easing swipe turns the page forward', (tester) async {
    final controller = await pager(tester, eager: true);
    await swipe(tester, easeOff);
    expect(controller.page, 1);
  });

  testWidgets('easing swipe turns the page back', (tester) async {
    final controller = await pager(tester, eager: true, initialPage: 1);
    await swipe(tester, [for (final dx in easeOff) -dx]);
    expect(controller.page, 0);
  });

  testWidgets('a nudge under a fifth of the page stays put', (tester) async {
    final controller = await pager(tester, eager: true);
    await swipe(tester, [-20, -20, -10, -5, -3, -2, -1, -1, -1]);
    expect(controller.page, 0);
  });

  testWidgets('pulling back before letting go cancels', (tester) async {
    final controller = await pager(tester, eager: true);
    await swipe(tester, [...easeOff, 1, 1, 1, 1]);
    expect(controller.page, 0);
  });

  testWidgets('a quick flick still turns one page', (tester) async {
    final controller = await pager(tester, eager: true);
    await tester.fling(find.byType(PageView), const Offset(-120, 0), 1500);
    await tester.pumpAndSettle();
    expect(controller.page, 1);
  });
}
