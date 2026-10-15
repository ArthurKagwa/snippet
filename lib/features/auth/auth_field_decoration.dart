import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';

/// Rounded white input used by the email sign-in form.
InputDecoration authFieldDecoration(
  SnippetColors c,
  String label, {
  Widget? suffix,
  String? errorText,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: SnippetFonts.body(14, color: c.inkDim),
    floatingLabelStyle: SnippetFonts.body(13, color: c.cobalt),
    errorText: errorText,
    errorStyle: SnippetFonts.body(12, color: c.danger),
    filled: true,
    fillColor: c.white,
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    enabledBorder: border(c.stone2, 1.4),
    focusedBorder: border(c.cobalt, 1.6),
    errorBorder: border(c.danger, 1.4),
    focusedErrorBorder: border(c.danger, 1.6),
  );
}
