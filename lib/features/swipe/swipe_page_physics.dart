import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Page snapping that turns the page once a swipe has gone a fifth of the
/// way, even if the finger eased off before letting go.
///
/// Stock PageView only moves on when the release counts as a fling (the
/// finger still covering 18px per 100ms) or the drag passed half the page.
/// A natural swipe slows down at the end, so it landed with no velocity
/// short of halfway and sprang back: the card just jiggled. Use with
/// `pageSnapping: false`, and a viewportFraction of 1.
class SwipePagePhysics extends PageScrollPhysics {
  const SwipePagePhysics({super.parent});

  /// How much of a page a slow swipe must cover to commit.
  static const double commitFraction = 0.2;

  @override
  SwipePagePhysics applyTo(ScrollPhysics? ancestor) =>
      SwipePagePhysics(parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final direction = position is ScrollPosition
        ? position.userScrollDirection
        : ScrollDirection.idle;
    // Real flings, overscroll and settled pages keep stock behaviour.
    if (velocity != 0 ||
        direction == ScrollDirection.idle ||
        position.outOfRange ||
        position.viewportDimension == 0) {
      return super.createBallisticSimulation(position, velocity);
    }
    final page = position.pixels / position.viewportDimension;
    final past = page - page.floorToDouble();
    // Reverse means the pixels grew: the swipe was heading for the next page.
    final towardsNext = direction == ScrollDirection.reverse;
    final target = towardsNext
        ? (past >= commitFraction ? page.ceil() : page.floor())
        : (1 - past >= commitFraction ? page.floor() : page.ceil());
    final pixels = (target * position.viewportDimension).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final tolerance = toleranceFor(position);
    if ((pixels - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      pixels,
      velocity,
      tolerance: tolerance,
    );
  }
}
