import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';

/// Thin vertical scrollbar showing which style of [count] is current.
class StyleTrack extends StatelessWidget {
  const StyleTrack({
    super.key,
    required this.count,
    required this.position,
    this.height = 280,
  });

  final int count;

  /// Fractional page (animates while swiping).
  final double position;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final thumb = height / count;
    return Semantics(
      label: 'Style ${position.round() + 1} of $count',
      child: Container(
        width: 2,
        height: height,
        decoration: ShapeDecoration(
          color: c.track,
          shape: const StadiumBorder(),
        ),
        alignment: Alignment.topCenter,
        child: Transform.translate(
          offset: Offset(0, thumb * position.clamp(0, count - 1)),
          child: Container(
            width: 2,
            height: thumb,
            decoration: ShapeDecoration(
              color: c.lime,
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ),
    );
  }
}
