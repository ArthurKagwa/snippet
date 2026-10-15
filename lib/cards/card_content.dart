import 'package:flutter/foundation.dart';

/// The words on a card.
@immutable
class CardContent {
  const CardContent({
    required this.text,
    required this.reference,
    required this.translation,
  });

  /// Verse text.
  final String text;

  /// Display reference, e.g. "Psalm 46:10".
  final String reference;

  /// Short translation label, e.g. "KJV".
  final String translation;

  /// "PSALM 46:10 · KJV"
  String get referenceLine =>
      '${reference.toUpperCase()}${translation.isEmpty ? '' : ' · $translation'}';
}
