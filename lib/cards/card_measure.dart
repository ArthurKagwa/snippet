import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'card_content.dart';
import 'card_shape.dart';
import 'card_style_spec.dart';
import 'quote_card.dart';

/// Whether a verse actually fits one style at one export size.
///
/// The card is laid out at that shape's design size, with the style's own
/// type, caps, padding and reference block, at the font the length bucket
/// chose. The size is offered when that text stays inside the verse well.
/// About 8% past the well still counts as fitting: the well already sits
/// inside the padding, and a few pixels is the difference between this
/// measure and a phone. Further than that, the size is hidden.
abstract final class CardMeasure {
  /// How far past the verse well still counts as fitting.
  static const slack = 0.08;

  static final _cache = <String, _Well>{};

  static bool offers({
    required CardStyleSpec style,
    required CardContent content,
    required CardShape shape,
    required double fontSize,
    required double lineHeight,
    required bool Function() fallback,
  }) {
    final well = _well(
      style: style,
      content: content,
      shape: shape,
      fontSize: fontSize,
      lineHeight: lineHeight,
    );
    if (well == null) return fallback();
    return well.fits;
  }

  static _Well? _well({
    required CardStyleSpec style,
    required CardContent content,
    required CardShape shape,
    required double fontSize,
    required double lineHeight,
  }) {
    final key =
        '${style.id}|${identityHashCode(style.builder)}|${shape.name}|'
        '${content.text}|${content.reference}|${content.translation}|'
        '${fontSize.toStringAsFixed(2)}|${lineHeight.toStringAsFixed(3)}';
    final cached = _cache[key];
    if (cached != null) return cached.missing ? null : cached;
    final well = _layout(
      style: style,
      content: content,
      shape: shape,
      fontSize: fontSize,
      lineHeight: lineHeight,
    );
    if (well == null) {
      _cache[key] = _Well.absent;
      return null;
    }
    _cache[key] = well;
    return well;
  }

  static _Well? _layout({
    required CardStyleSpec style,
    required CardContent content,
    required CardShape shape,
    required double fontSize,
    required double lineHeight,
  }) {
    if (style.variants.isEmpty) return null;
    final size = Size(CardShape.designWidth, shape.designHeight);
    final root = _MeasureRoot(size);
    final pipeline = PipelineOwner()..rootNode = root;
    root.scheduleInitialLayout();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    try {
      final element = RenderObjectToWidgetAdapter<RenderBox>(
        container: root,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(size: size, textScaler: TextScaler.noScaling),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: QuoteCard(
                content: content,
                style: style,
                variant: style.variants.first,
                shape: shape,
              ),
            ),
          ),
        ),
      ).attachToRenderTree(buildOwner);
      buildOwner.buildScope(element);
      pipeline.flushLayout();
      buildOwner.buildScope(element);
      pipeline.flushLayout();

      final wanted = content.text.trim();
      final upper = wanted.toUpperCase();
      RenderParagraph? verse;
      void visit(RenderObject node) {
        if (node is RenderParagraph) {
          final plain = node.text.toPlainText().trim();
          if (plain == wanted || plain == upper) verse = node;
        }
        node.visitChildren(visit);
      }

      visit(root);
      final found = verse;
      if (found == null) return null;
      return _Well.fromParagraph(
        paragraph: found,
        plain: found.text.toPlainText(),
        fontSize: fontSize,
        lineHeight: lineHeight,
      );
    } catch (e, stack) {
      debugPrint('Could not measure ${style.id} ${shape.name}: $e\n$stack');
      return null;
    } finally {
      root.detach();
    }
  }
}

class _Well {
  const _Well({required this.fits}) : missing = false;
  const _Well._missing() : fits = false, missing = true;

  static const absent = _Well._missing();

  final bool fits;
  final bool missing;

  factory _Well.fromParagraph({
    required RenderParagraph paragraph,
    required String plain,
    required double fontSize,
    required double lineHeight,
  }) {
    final slotWidth = paragraph.constraints.maxWidth;
    final slotHeight = paragraph.constraints.maxHeight;
    if (!slotWidth.isFinite || slotWidth <= 0 || !slotHeight.isFinite) {
      return const _Well(fits: false);
    }
    final painted = paragraph.text.style;
    final rendered = painted?.fontSize ?? fontSize;
    final factor = rendered == 0 ? 1.0 : fontSize / rendered;
    final style = (painted ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      height: lineHeight,
      letterSpacing: painted?.letterSpacing == null
          ? null
          : painted!.letterSpacing! * factor,
    );
    final painter = TextPainter(
      text: TextSpan(text: plain, style: style),
      textAlign: paragraph.textAlign,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: slotWidth);
    final wide = painter.computeLineMetrics().any(
      (line) => line.width > slotWidth + 0.5,
    );
    final limit = slotHeight * (1 + CardMeasure.slack) + 0.5;
    final fits = !wide && painter.height <= limit;
    painter.dispose();
    return _Well(fits: fits);
  }
}

/// Gives its child the card's design size. Not part of the on-screen tree.
class _MeasureRoot extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _MeasureRoot(this.target);

  final Size target;

  @override
  void performLayout() {
    child?.layout(BoxConstraints.tight(target), parentUsesSize: true);
    size = target;
  }

  /// The root is laid out without parent constraints. The child still
  /// receives the card's design size.
  @override
  void debugAssertDoesMeetConstraints() {}

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;
}
