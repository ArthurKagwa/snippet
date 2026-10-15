import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snippet/services/export_service.dart';

void main() {
  testWidgets('capturePng produces a PNG', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 100,
            height: 100,
            child: ColoredBox(color: Colors.red),
          ),
        ),
      ),
    );
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final png = await tester.runAsync(
      () => const DeviceExportService().capturePng(boundary, pixelRatio: 2),
    );
    expect(png!.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });
}
