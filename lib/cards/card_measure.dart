import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/app_theme.dart';
import 'card_content.dart';
import 'card_shape.dart';
import 'card_style_spec.dart';
import 'quote_card.dart';

/// Whether a verse actually fits one style at one export size.
///
/// The card is laid out at that shape's design size, inside the same text
/// theme the export paints with, at the font the fit chose. The size is
/// offered only when that text stays inside the verse well. A line past the
/// well is clipped on the card, so it does not count as fitting.
abstract final class CardMeasure {
  /// Rounding slack, in logical pixels. Not a fraction of the well.
  static const epsilon = 0.5;

  static final _cache = <String, _Well>{};

  static bool offers({
    required CardStyleSpec style,
    required CardContent content,
    required CardShape shape,
    required double fontSize,
    required double lineHeight,
    required bool Function() fallback,
    double gap = 0,
    double pad = 0,
    double spacing = 1,
  }) {
    final well = _well(
      style: style,
      content: content,
      shape: shape,
      fontSize: fontSize,
      lineHeight: lineHeight,
      gap: gap,
      pad: pad,
      spacing: spacing,
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
    required double gap,
    required double pad,
    required double spacing,
  }) {
    final key =
        '${style.id}|${identityHashCode(style.builder)}|${shape.name}|'
        '${content.text}|${content.reference}|${content.translation}|'
        '${fontSize.toStringAsFixed(2)}|${lineHeight.toStringAsFixed(3)}|'
        '${gap.toStringAsFixed(2)}|${pad.toStringAsFixed(2)}|'
        '${spacing.toStringAsFixed(3)}';
    final cached = _cache[key];
    if (cached != null) return cached.missing ? null : cached;
    final well = _layout(style: style, content: content, shape: shape);
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
  }) {
    if (style.variants.isEmpty) return null;
    final size = Size(CardShape.designWidth, shape.designHeight);
    final root = _MeasureRoot(size);
    final pipeline = PipelineOwner()..rootNode = root;
    root.scheduleInitialLayout();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    try {
      final theme = AppTheme.cobaltSwipe();
      final element = RenderObjectToWidgetAdapter<RenderBox>(
        container: root,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(size: size, textScaler: TextScaler.noScaling),
            child: Theme(
              data: theme,
              child: DefaultTextStyle(
                style: theme.textTheme.bodyMedium ?? const TextStyle(),
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
      return _Well.fromParagraph(found);
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

  factory _Well.fromParagraph(RenderParagraph paragraph) {
    final slotWidth = paragraph.constraints.maxWidth;
    final slotHeight = paragraph.constraints.maxHeight;
    if (!slotWidth.isFinite || slotWidth <= 0 || !slotHeight.isFinite) {
      return const _Well(fits: false);
    }
    // The paragraph already carries the style the card painted, including
    // the ambient theme. Rebuilding a bare style here used to miss that
    // letter spacing, and the old 8% allowance then treated a clipped last
    // line as fitting.
    final painter = TextPainter(
      text: paragraph.text,
      textAlign: paragraph.textAlign,
      textDirection: paragraph.textDirection,
      textScaler: TextScaler.noScaling,
      maxLines: paragraph.maxLines,
    )..layout(maxWidth: slotWidth);
    final wide = painter.computeLineMetrics().any(
      (line) => line.width > slotWidth + CardMeasure.epsilon,
    );
    final fits =
        !wide &&
        !painter.didExceedMaxLines &&
        painter.height <= slotHeight + CardMeasure.epsilon;
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
