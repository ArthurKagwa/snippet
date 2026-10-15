import 'package:flutter/material.dart';

class AppTheme {
  static const String appName = 'Snippet';
  static const String tagline = 'Bible verse quote cards';

  static ThemeData light() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
    useMaterial3: true,
  );

  static ThemeData dark() => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
