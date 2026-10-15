import 'package:flutter/material.dart';

import 'theme/snippet_colors.dart';
import 'theme/snippet_fonts.dart';

class AppTheme {
  static const String appName = 'Snippet';
  static const String tagline = 'Bible verse quote cards';
  static const String version = '1.0.0';

  /// The Cobalt swipe design is a single dark-chrome theme.
  static ThemeData cobaltSwipe() {
    const c = SnippetColors.cobaltSwipe;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.cobalt,
          brightness: Brightness.dark,
        ).copyWith(
          primary: c.cobalt,
          onPrimary: c.white,
          secondary: c.lime,
          onSecondary: c.ink,
          surface: c.black,
          onSurface: c.white,
          error: c.danger,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.black,
      fontFamily: SnippetFonts.sans,
      extensions: const [c],
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.lime,
        contentTextStyle: SnippetFonts.body(15, color: c.ink),
        shape: const StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.stone,
        titleTextStyle: SnippetFonts.display(24, color: c.ink),
        contentTextStyle: SnippetFonts.body(16, color: c.inkDim),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.cobalt),
      ),
    );
  }
}
