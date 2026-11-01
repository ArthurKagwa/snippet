import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'card_palette.dart';
import 'card_style_spec.dart';
import 'remote/layout_node.dart';
import 'verse_scale.dart';

/// Remote changes to the bundled card styles (Remote Config `card_styles`).
///
/// Reorders, hides and renames styles, adds, recolours or hides
/// colourways, and adds whole new styles from a JSON `layout` (see
/// [LayoutNode] and remote_card_styles.example.json):
///
/// ```json
/// {
///   "order": ["dawn", "vigil"],
///   "hidden": ["swiss"],
///   "styles": {
///     "riso": {
///       "name": "Riso",
///       "tags": ["bold", "soft"],
///       "hidden_variants": ["mint"],
///       "variants": [
///         {"id": "pink", "ink": "#FFFFFF"},
///         {"id": "tangerine", "name": "Tangerine", "background": "#FF7A1A",
///          "ink": "#141414", "accent": "#141414", "surface": "#FFE14D"}
///       ]
///     },
///     "psalter": {
///       "name": "Psalter",
///       "tags": ["classic"],
///       "layout": {"type": "box", "color": "background", ...},
///       "variants": [{"id": "ink", "background": "#101010", "ink": "#F4EFE6"}]
///     }
///   }
/// }
/// ```
///
/// A variant whose id matches a bundled one only changes the fields given;
/// a new id needs at least `background` and `ink`. A style id that isn't
/// bundled needs a `layout` and one valid variant; a `layout` on a bundled
/// id redraws it. Hidden styles and colourways still render on cards that
/// were saved with them, but a style deleted from the config falls back to
/// the first style, so hide styles rather than delete them.
@immutable
class CardStyleOverrides {
  const CardStyleOverrides({
    this.order = const [],
    this.hidden = const {},
    this.styles = const {},
  });

  /// Style ids to show first; the rest follow in bundled order.
  final List<String> order;
  final Set<String> hidden;
  final Map<String, StyleOverride> styles;

  static const none = CardStyleOverrides();

  /// Reads the `card_styles` JSON. Anything unreadable is skipped, so a
  /// bad edit in the console degrades to the bundled styles.
  static CardStyleOverrides parse(String json) {
    if (json.trim().isEmpty) return none;
    try {
      final root = jsonDecode(json);
      if (root is! Map) return none;
      final styles = root['styles'];
      return CardStyleOverrides(
        order: _strings(root['order']).toList(),
        hidden: _strings(root['hidden']).toSet(),
        styles: {
          if (styles is Map)
            for (final e in styles.entries)
              if (e.key is String && e.value is Map)
                e.key as String: StyleOverride._fromJson(e.value as Map),
        },
      );
    } on FormatException catch (e) {
      debugPrint('Remote Config card_styles is not JSON: $e');
      return none;
    }
  }

  /// Applies these changes to [bundled], returning every style in display
  /// order with hidden ones still included (see [isHidden]).
  List<CardStyleSpec> applyTo(List<CardStyleSpec> bundled) {
    final base = {for (final s in bundled) s.id: s};
    for (final MapEntry(key: id, value: o) in styles.entries) {
      if (o.layout == null) continue;
      base.putIfAbsent(
        id,
        () => CardStyleSpec(
          id: id,
          name: id,
          tags: const {},
          variants: const [],
          builder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }
    final byId = {
      for (final s in base.values)
        if (styles[s.id]?._applyTo(s) ?? s case final spec
            when spec.variants.isNotEmpty)
          s.id: spec,
    };
    return [for (final id in order.toSet()) ?byId.remove(id), ...byId.values];
  }

  /// Whether [styleId] is hidden. Ignored when it would hide every style.
  bool isHidden(String styleId, List<CardStyleSpec> all) =>
      hidden.contains(styleId) && all.any((s) => !hidden.contains(s.id));
}

/// Changes to one style.
@immutable
class StyleOverride {
  const StyleOverride({
    this.name,
    this.collection,
    this.tags,
    this.hiddenVariants = const {},
    this.variants = const [],
    this.layout,
  });

  factory StyleOverride._fromJson(Map json) {
    final tags = json['tags'];
    final variants = json['variants'];
    return StyleOverride(
      name: _string(json['name']),
      collection: _string(json['collection']),
      tags: tags is List
          ? {
              for (final t in _strings(tags))
                ...StyleTag.values.where((v) => v.name == t),
            }
          : null,
      hiddenVariants: _strings(json['hidden_variants']).toSet(),
      variants: [
        if (variants is List)
          for (final v in variants.whereType<Map>())
            if (_string(v['id']) case final id?) VariantOverride._(id, v),
      ],
      layout: _layout(json['layout']),
    );
  }

  final String? name;
  final String? collection;
  final Set<StyleTag>? tags;
  final Set<String> hiddenVariants;
  final List<VariantOverride> variants;

  /// Replaces the style's drawing; required for a new style.
  final LayoutNode? layout;

  static LayoutNode? _layout(Object? json) {
    if (json == null) return null;
    final node = LayoutNode.parse(json);
    if (node == null) debugPrint('Remote Config card_styles: bad layout');
    return node;
  }

  CardStyleSpec _applyTo(CardStyleSpec style) {
    final merged = [...style.variants, ...style.hiddenVariants];
    for (final o in variants) {
      final i = merged.indexWhere((v) => v.id == o.id);
      final base = i < 0 ? null : merged[i];
      final variant = o.resolve(base);
      if (variant == null) continue;
      if (i < 0) {
        merged.add(variant);
      } else {
        merged[i] = variant;
      }
    }
    var shown = [
      for (final v in merged)
        if (!hiddenVariants.contains(v.id)) v,
    ];
    if (shown.isEmpty) shown = merged;
    return style.copyWith(
      name: name,
      collection: collection,
      tags: tags == null || tags!.isEmpty ? null : tags,
      variants: shown,
      builder: switch (layout) {
        final l? => (c, p, shape) => l.build(
          LayoutScope(c, p, shape, VerseScales.read(style.id, c.text)),
        ),
        null => null,
      },
      hiddenVariants: [
        for (final v in merged)
          if (!shown.contains(v)) v,
      ],
    );
  }
}

/// A new or recoloured colourway; colours are `#RRGGBB` or `#AARRGGBB`.
@immutable
class VariantOverride {
  const VariantOverride._(this.id, this._json);

  final String id;
  final Map _json;

  Color? _color(String key) => parseHexColor(_json[key]);

  /// The colourway with these changes over [base], or null when a new one
  /// lacks `background` or `ink`.
  CardVariant? resolve(CardVariant? base) {
    final p = base?.palette;
    final background = _color('background') ?? p?.background;
    final ink = _color('ink') ?? p?.ink;
    if (background == null || ink == null) return null;
    final accent = _color('accent') ?? p?.accent ?? ink;
    return CardVariant(
      id: id,
      name: _string(_json['name']) ?? base?.name ?? id,
      swatch: _color('swatch') ?? base?.swatch ?? background,
      palette: CardPalette(
        background: background,
        backgroundEnd: _color('background_end') ?? p?.backgroundEnd,
        ink: ink,
        accent: accent,
        accentDim: _color('accent_dim') ?? p?.accentDim,
        surface: _color('surface') ?? p?.surface,
        surfaceInk: _color('surface_ink') ?? p?.surfaceInk,
        border: _color('border') ?? p?.border,
      ),
    );
  }
}

/// Reads `#RRGGBB` or `#AARRGGBB` (the `#` is optional).
Color? parseHexColor(Object? value) {
  if (value is! String) return null;
  final hex = value.trim().replaceFirst('#', '');
  if (!RegExp(r'^([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(hex)) {
    return null;
  }
  return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
}

String? _string(Object? v) =>
    v is String && v.trim().isNotEmpty ? v.trim() : null;

Iterable<String> _strings(Object? v) =>
    v is List ? v.map(_string).nonNulls : const [];
