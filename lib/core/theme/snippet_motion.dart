import 'package:flutter/widgets.dart';

/// Shared curves and durations for transitions that enter, leave or move.
///
/// Press feedback and small toggles keep their inline 90–180ms values.
abstract final class SnippetMotion {
  /// Strong ease-out: quick to respond, soft to settle.
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Something leaving (a removed card).
  static const Duration exit = Duration(milliseconds: 180);

  /// One view of a region replacing another (filters, loading → content).
  static const Duration swap = Duration(milliseconds: 200);

  /// Opacity-only stand-in when the system asks for less motion.
  static const Duration reduced = Duration(milliseconds: 120);

  /// True when the system asks for reduced motion.
  static bool reduce(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
