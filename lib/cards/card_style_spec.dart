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
    this.hiddenVariants = const [],
  });

  final String id;
  final String name;
  final String collection;
  final Set<StyleTag> tags;
  final List<CardVariant> variants;
  final CardArtBuilder builder;

  /// Colourways no longer offered, kept so saved cards still render.
  final List<CardVariant> hiddenVariants;

  int variantIndex(String? variantId) {
    final i = variants.indexWhere((v) => v.id == variantId);
    return i < 0 ? 0 : i;
  }

  CardVariant variant(String? variantId) =>
      hiddenVariants.where((v) => v.id == variantId).firstOrNull ??
      variants[variantIndex(variantId)];

  CardStyleSpec copyWith({
    String? name,
    String? collection,
    Set<StyleTag>? tags,
    List<CardVariant>? variants,
    List<CardVariant>? hiddenVariants,
    CardArtBuilder? builder,
  }) => CardStyleSpec(
    id: id,
    name: name ?? this.name,
    collection: collection ?? this.collection,
    tags: tags ?? this.tags,
    variants: variants ?? this.variants,
    hiddenVariants: hiddenVariants ?? this.hiddenVariants,
    builder: builder ?? this.builder,
  );
}
