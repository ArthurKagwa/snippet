import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled faces so text measurement in tests matches the app.
Future<void> testExecutable(Future<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fonts = {
    'Syne': ['assets/fonts/Syne-Variable.ttf'],
    'InstrumentSerif': [
      'assets/fonts/InstrumentSerif-Regular.ttf',
      'assets/fonts/InstrumentSerif-Italic.ttf',
    ],
    'InstrumentSans': ['assets/fonts/InstrumentSans-Variable.ttf'],
    'CormorantGaramond': [
      'assets/fonts/CormorantGaramond-Variable.ttf',
      'assets/fonts/CormorantGaramond-Italic-Variable.ttf',
    ],
    'SpaceMono': [
      'assets/fonts/SpaceMono-Regular.ttf',
      'assets/fonts/SpaceMono-Bold.ttf',
    ],
    'BricolageGrotesque': ['assets/fonts/BricolageGrotesque-Variable.ttf'],
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final bytes = Uint8List.fromList(File(path).readAsBytesSync());
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
  await testMain();
}
