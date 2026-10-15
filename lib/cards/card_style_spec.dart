import 'package:flutter/widgets.dart';

import 'card_content.dart';
import 'card_palette.dart';
import 'card_shape.dart';

/// Filters on the All styles screen.
enum StyleTag {
  classic('Classic'),
  bold('Bold'),
  soft('Soft'),
  minimal('Minimal');

  const StyleTag(this.label);
  final String label;
}

typedef CardArtBuilder =
    Widget Function(CardContent content, CardPalette palette, CardShape shape);

/// A card style: a layout plus its colourways.
@immutable
class CardStyleSpec {
  const CardStyleSpec({
    required this.id,
    required this.name,
    required this.tags,
    required this.variants,
    required this.builder,
    this.collection = 'Snippet originals',
  });

  final String id;
  final String name;
  final String collection;
  final Set<StyleTag> tags;
  final List<CardVariant> variants;
  final CardArtBuilder builder;

  int variantIndex(String? variantId) {
    final i = variants.indexWhere((v) => v.id == variantId);
    return i < 0 ? 0 : i;
  }

  CardVariant variant(String? variantId) => variants[variantIndex(variantId)];
}
