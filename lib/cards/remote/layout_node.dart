import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../auto_fit_text.dart';
import '../card_content.dart';
import '../card_palette.dart';
import '../card_shape.dart';
import '../marked_text.dart';
import '../reference_text.dart';
import '../styles/halftone_painter.dart';
import 'layout_values.dart';

part 'layout_leaf_nodes.dart';

/// What a remote layout draws with.
class LayoutScope {
  const LayoutScope(this.content, this.palette, this.shape);

  final CardContent content;
  final CardPalette palette;
  final CardShape shape;
}

/// One node of a remote card layout, read from JSON with a `type`.
///
/// Sizes are in card design units (the card is 304 wide). See
/// remote_card_styles.example.json for every node in use.
sealed class LayoutNode {
  const LayoutNode();

  Widget build(LayoutScope s);

  /// Null when [json] isn't a node this app knows, so a layout using a
  /// newer node type is dropped instead of drawn wrong.
  static LayoutNode? parse(Object? json, [int depth = 0]) {
    if (json is! Map || depth > 24) return null;
    final d = depth + 1;
    LayoutNode? child() => parse(json['child'], d);
    List<LayoutNode>? children() {
      final list = json['children'];
      if (list is! List) return null;
      final nodes = [for (final c in list) parse(c, d)];
      return nodes.contains(null) ? null : nodes.cast<LayoutNode>();
    }

    return switch (json['type']) {
      'box' => _BoxNode(json, child()),
      'column' || 'row' => switch (children()) {
        final c? => _FlexNode(json, c),
        null => null,
      },
      'stack' => switch (children()) {
        final c? => _StackNode(c),
        null => null,
      },
      'align' => _wrap(json, child(), _AlignNode.new),
      'padding' => _wrap(json, child(), _PaddingNode.new),
      'rotate' => _wrap(json, child(), _RotateNode.new),
      'space' => _SpaceNode(numberOf(json['size']) ?? 0),
      'text' => _TextNode(json),
      'halftone' => _HalftoneNode(json),
      'byShape' => _ShapeNode.parse(json, d),
      _ => null,
    };
  }

  static LayoutNode? _wrap(
    Map json,
    LayoutNode? child,
    LayoutNode Function(Map, LayoutNode) make,
  ) => child == null ? null : make(json, child);
}

/// `{"type": "box", "color", "gradient": {"colors", "begin", "end"},
/// "border", "borderWidth", "radius", "circle", "width", "height",
/// "minHeight", "maxHeight", "padding", "child"}`
///
/// `height` pins the box, so anything taller is clipped; `minHeight` only
/// sets a floor, which is what text that may take a second line needs.
/// Older app builds ignore `minHeight` and `maxHeight`.
final class _BoxNode extends LayoutNode {
  _BoxNode(Map json, this.child)
    : color = ColorRef.parse(json['color']),
      minHeight = numberOf(json['minHeight']),
      maxHeight = numberOf(json['maxHeight']),
      gradient = json['gradient'] is Map ? json['gradient'] as Map : null,
      border = ColorRef.parse(json['border']),
      borderWidth = numberOf(json['borderWidth']) ?? 1,
      radius = radiusOf(json['radius']),
      circle = json['circle'] == true,
      width = numberOf(json['width']),
      height = numberOf(json['height']),
      padding = insetsOf(json['padding']);

  final LayoutNode? child;
  final ColorRef? color;
  final Map? gradient;
  final ColorRef? border;
  final double borderWidth;
  final BorderRadius? radius;
  final bool circle;
  final double? width;
  final double? height;
  final double? minHeight;
  final double? maxHeight;
  final EdgeInsets padding;

  BoxConstraints? get _constraints => minHeight == null && maxHeight == null
      ? null
      : BoxConstraints(
          minHeight: minHeight ?? 0,
          maxHeight: maxHeight ?? double.infinity,
        );

  Gradient? _gradient(CardPalette p) {
    final colors = [
      for (final c in (gradient?['colors'] as List?) ?? const [])
        ?ColorRef.parse(c)?.resolve(p),
    ];
    if (colors.length < 2) return null;
    return LinearGradient(
      begin: alignmentOf(gradient!['begin']) ?? Alignment.topCenter,
      end: alignmentOf(gradient!['end']) ?? Alignment.bottomCenter,
      colors: colors,
    );
  }

  @override
  Widget build(LayoutScope s) => Container(
    width: width,
    height: height,
    constraints: _constraints,
    padding: padding,
    decoration: BoxDecoration(
      color: color?.resolve(s.palette),
      gradient: _gradient(s.palette),
      border: border == null
          ? null
          : Border.all(color: border!.resolve(s.palette), width: borderWidth),
      borderRadius: circle ? null : radius,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
    ),
    child: child?.build(s),
  );
}

/// `{"type": "column" | "row", "children", "main", "cross", "gap"}`; a
/// child with `"flex": n` takes a share of the free space (needed for
/// `fit` text).
final class _FlexNode extends LayoutNode {
  _FlexNode(Map json, this.children)
    : axis = json['type'] == 'row' ? Axis.horizontal : Axis.vertical,
      flexes = [
        for (final c in json['children'] as List)
          numberOf((c as Map)['flex'])?.round(),
      ],
      gap = numberOf(json['gap']) ?? 0,
      main = switch (json['main']) {
        'center' => MainAxisAlignment.center,
        'end' => MainAxisAlignment.end,
        'spaceBetween' => MainAxisAlignment.spaceBetween,
        'spaceAround' => MainAxisAlignment.spaceAround,
        'spaceEvenly' => MainAxisAlignment.spaceEvenly,
        _ => MainAxisAlignment.start,
      },
      cross = switch (json['cross']) {
        'start' => CrossAxisAlignment.start,
        'end' => CrossAxisAlignment.end,
        'stretch' => CrossAxisAlignment.stretch,
        _ => CrossAxisAlignment.center,
      };

  final Axis axis;
  final List<LayoutNode> children;
  final List<int?> flexes;
  final double gap;
  final MainAxisAlignment main;
  final CrossAxisAlignment cross;

  @override
  Widget build(LayoutScope s) => Flex(
    direction: axis,
    mainAxisAlignment: main,
    crossAxisAlignment: cross,
    spacing: gap,
    children: [
      for (var i = 0; i < children.length; i++)
        switch (flexes[i]) {
          final f? when f > 0 => Expanded(flex: f, child: children[i].build(s)),
          _ => children[i].build(s),
        },
    ],
  );
}

/// `{"type": "stack", "children"}`: layers that each fill the box.
final class _StackNode extends LayoutNode {
  const _StackNode(this.children);

  final List<LayoutNode> children;

  @override
  Widget build(LayoutScope s) => Stack(
    fit: StackFit.expand,
    children: [for (final c in children) c.build(s)],
  );
}

/// `{"type": "align", "alignment", "child"}`
final class _AlignNode extends LayoutNode {
  _AlignNode(Map json, this.child)
    : alignment = alignmentOf(json['alignment']) ?? Alignment.center;

  final Alignment alignment;
  final LayoutNode child;

  @override
  Widget build(LayoutScope s) =>
      Align(alignment: alignment, child: child.build(s));
}

/// `{"type": "padding", "padding", "child"}`
final class _PaddingNode extends LayoutNode {
  _PaddingNode(Map json, this.child) : padding = insetsOf(json['padding']);

  final EdgeInsets padding;
  final LayoutNode child;

  @override
  Widget build(LayoutScope s) =>
      Padding(padding: padding, child: child.build(s));
}

/// `{"type": "rotate", "degrees", "child"}`
final class _RotateNode extends LayoutNode {
  _RotateNode(Map json, this.child)
    : radians = (numberOf(json['degrees']) ?? 0) * math.pi / 180;

  final double radians;
  final LayoutNode child;

  @override
  Widget build(LayoutScope s) =>
      Transform.rotate(angle: radians, child: child.build(s));
}

/// `{"type": "space", "size"}`: a gap in a row or column.
final class _SpaceNode extends LayoutNode {
  const _SpaceNode(this.size);

  final double size;

  @override
  Widget build(LayoutScope s) => SizedBox.square(dimension: size);
}
