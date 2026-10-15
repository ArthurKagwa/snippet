import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../cards/card_content.dart';
import '../../cards/card_style_spec.dart';
import '../../services/services.dart';
import 'style_page.dart';
import 'style_track.dart';
import 'swipe_hint.dart';

/// The dark area between header and panel: the card stack, centered and
/// sized to fill it, plus the position track and the swipe hint.
class SwipeStage extends StatelessWidget {
  const SwipeStage({
    super.key,
    required this.styles,
    required this.styleIndex,
    required this.content,
    required this.styleController,
    required this.variantController,
    required this.onStyleChanged,
    required this.onVariantChanged,
    required this.onScroll,
    required this.sideways,
  });

  final List<CardStyleSpec> styles;
  final int styleIndex;
  final CardContent content;
  final PageController styleController;
  final PageController Function(int style) variantController;
  final ValueChanged<int> onStyleChanged;
  final void Function(int style, int variant) onVariantChanged;
  final NotificationListenerCallback<ScrollNotification> onScroll;
  final bool sideways;

  static const double hintHeight = 30;
  static const double sideMargin = 20;

  @override
  Widget build(BuildContext context) {
    final hints = Services.of(context).settings;
    return LayoutBuilder(
      builder: (context, box) {
        final area = box.maxHeight - hintHeight;
        // Largest 4:5 card that fits the area, with breathing room.
        final h = math.min(
          (box.maxWidth - sideMargin * 2) / 0.8,
          area - StylePage.peekDepth - 12,
        );
        final cardSize = Size(h * 0.8, h);
        final cardTop = (area - h - StylePage.peekDepth) / 2;
        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: area,
              child: NotificationListener<ScrollNotification>(
                onNotification: onScroll,
                child: PageView.builder(
                  key: const Key('style-pager'),
                  controller: styleController,
                  scrollDirection: Axis.vertical,
                  itemCount: styles.length,
                  onPageChanged: onStyleChanged,
                  itemBuilder: (context, i) => StylePage(
                    style: styles[i],
                    nextStyle: i + 1 < styles.length ? styles[i + 1] : null,
                    content: content,
                    controller: variantController(i),
                    cardSize: cardSize,
                    onVariantChanged: (v) => onVariantChanged(i, v),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: cardTop + h * 0.13,
              child: AnimatedBuilder(
                animation: styleController,
                builder: (context, _) => StyleTrack(
                  count: styles.length,
                  height: h * 0.74,
                  position:
                      styleController.hasClients &&
                          styleController.position.haveDimensions
                      ? styleController.page ?? 0
                      : styleIndex.toDouble(),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              height: hintHeight - 4,
              child: ListenableBuilder(
                listenable: hints,
                builder: (context, _) => hints.swipeHints
                    ? SwipeHint(
                        sideways: sideways,
                        isLast: styleIndex == styles.length - 1,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}
