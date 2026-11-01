part of 'layout_node.dart';

/// `{"type": "text", "text", "font", "weight", "italic", "condensed",
/// "size", "fit", "minSize", "maxLines", "color", "align", "upper",
/// "height", "tracking", "highlight", "highlightPadding"}`. [text] may use
/// `{verse}`, `{reference}`, `{translation}` and `{referenceLine}`; `fit`
/// shrinks to the space given (from `size` down to `minSize`); `tracking`
/// is in ems. `highlight` is a colour for a marker band behind each line
/// (a `height` above 1 opens gaps between the bands), grown by
/// `highlightPadding`; older app builds ignore it.
///
/// A fitted `"{reference}"` is drawn by [ReferenceText], which sets the
/// chapter:verse on its own line when the book name is too long to keep it
/// alongside. Give that node room for two lines (a `minHeight` box rather
/// than a fixed `height`).
final class _TextNode extends LayoutNode {
  _TextNode(Map json)
    : text = json['text'] is String ? json['text'] as String : '{verse}',
      font = FontRef.fromJson(json),
      size = numberOf(json['size']) ?? 12,
      minSize = numberOf(json['minSize']) ?? 6,
      maxLines = numberOf(json['maxLines'])?.round(),
      fit = json['fit'] == true,
      color = ColorRef.parse(json['color']),
      align = textAlignOf(json['align']),
      upper = json['upper'] == true,
      height = numberOf(json['height']),
      tracking = numberOf(json['tracking']),
      highlight = ColorRef.parse(json['highlight']),
      highlightPadding = insetsOf(json['highlightPadding']);

  final String text;
  final FontRef font;
  final double size;
  final double minSize;
  final int? maxLines;
  final bool fit;
  final ColorRef? color;
  final TextAlign align;
  final bool upper;
  final double? height;
  final double? tracking;
  final ColorRef? highlight;
  final EdgeInsets highlightPadding;

  String _fill(CardContent c) {
    final s = text
        .replaceAll('{verse}', c.text)
        .replaceAll('{referenceLine}', c.referenceLine)
        .replaceAll('{reference}', c.reference)
        .replaceAll('{translation}', c.translation);
    return upper ? s.toUpperCase() : s;
  }

  /// Whether this node is the reference itself, rather than text that
  /// merely mentions it, so its chapter:verse can take its own line.
  bool get _isReference => text.trim() == '{reference}';

  @override
  Widget build(LayoutScope s) {
    final ink = (color ?? ColorRef.parse('ink')!).resolve(s.palette);
    TextStyle styleFor(double size) =>
        font.style(size, color: ink, height: height, tracking: tracking);
    if (fit && _isReference && highlight == null) {
      final book = s.content.referenceBook;
      return ReferenceText(
        book: upper ? book.toUpperCase() : book,
        numbers: s.content.referenceNumbers,
        maxSize: size,
        minSize: math.min(minSize, size),
        textAlign: align,
        styleFor: styleFor,
      );
    }
    final value = _fill(s.content);
    if (fit) {
      return AutoFitText(
        value,
        maxSize: size,
        minSize: math.min(minSize, size),
        textAlign: align,
        maxLines: maxLines,
        styleFor: styleFor,
        highlight: highlight?.resolve(s.palette),
        highlightPadding: highlightPadding,
      );
    }
    if (highlight case final band?) {
      return MarkedText(
        value,
        style: styleFor(size),
        color: band.resolve(s.palette),
        padding: highlightPadding,
        textAlign: align,
        maxLines: maxLines,
      );
    }
    return Text(
      value,
      textAlign: align,
      textScaler: TextScaler.noScaling,
      maxLines: maxLines,
      style: styleFor(size),
    );
  }
}

/// `{"type": "halftone", "color", "spacing", "dot"}`: a dot screen.
final class _HalftoneNode extends LayoutNode {
  _HalftoneNode(Map json)
    : color = ColorRef.parse(json['color']) ?? ColorRef.parse('ink@0.12')!,
      spacing = (numberOf(json['spacing']) ?? 10).clamp(2, 100),
      dot = numberOf(json['dot']) ?? 0.9;

  final ColorRef color;
  final double spacing;
  final double dot;

  @override
  Widget build(LayoutScope s) => CustomPaint(
    painter: HalftonePainter(
      color: color.resolve(s.palette),
      spacing: spacing,
      radius: dot,
    ),
  );
}

/// `{"type": "byShape", "feed", "portrait", "story", "default"}`: a
/// different node per export shape.
final class _ShapeNode extends LayoutNode {
  const _ShapeNode(this.byShape, this.fallback);

  static LayoutNode? parse(Map json, int depth) {
    final fallback = LayoutNode.parse(json['default'], depth);
    if (fallback == null) return null;
    return _ShapeNode({
      for (final shape in CardShape.values)
        shape: ?LayoutNode.parse(json[shape.name], depth),
    }, fallback);
  }

  final Map<CardShape, LayoutNode> byShape;
  final LayoutNode fallback;

  @override
  Widget build(LayoutScope s) => (byShape[s.shape] ?? fallback).build(s);
}
