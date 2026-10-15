import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';
import '../../core/theme/snippet_motion.dart';
import '../../widgets/pill_button.dart';
import '../shell/shell_controller.dart';

/// "Nothing saved yet": dashed arch with the lime sun.
///
/// The first time it is on screen the sun rises into the arch and the
/// words follow. Saved is built at launch behind the other tabs, so this
/// waits for the Saved tab rather than playing on mount.
class LibraryEmpty extends StatefulWidget {
  const LibraryEmpty({super.key, required this.onPickVerse});

  final VoidCallback onPickVerse;

  @override
  State<LibraryEmpty> createState() => _LibraryEmptyState();
}

class _LibraryEmptyState extends State<LibraryEmpty>
    with SingleTickerProviderStateMixin {
  // Sun over 600ms; the three text rows 300ms each, 60ms apart, starting
  // as the sun settles. Total 660ms.
  static const _total = 660.0;
  static Interval _at(double startMs, double endMs) =>
      Interval(startMs / _total, endMs / _total, curve: SnippetMotion.easeOut);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _total.round()),
  );
  late final Animation<double> _sun = _controller.drive(
    CurveTween(curve: _at(0, 600)),
  );
  late final List<Animation<double>> _rows = [
    for (final start in [240.0, 300.0, 360.0])
      _controller.drive(CurveTween(curve: _at(start, start + 300))),
  ];
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final showing = ShellScope.of(context).tab == ShellTab.saved;
    if (showing && _controller.isDismissed) {
      _reduce = SnippetMotion.reduce(context);
      if (_reduce) _controller.duration = const Duration(milliseconds: 200);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fades in while rising [distance] px into place (fade only when the
  /// system asks for less motion). Never blocks taps.
  Widget _rise(Animation<double> a, double distance, Widget child) {
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (context, child) {
        final t = _reduce ? _controller.value : a.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, _reduce ? 0 : distance * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 184,
                  height: 187,
                  child: CustomPaint(
                    painter: _DashedArch(c.archLine),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 36),
                        child: _rise(
                          _sun,
                          16,
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c.lime,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _rise(
                  _rows[0],
                  8,
                  Text(
                    'Nothing saved yet',
                    textAlign: TextAlign.center,
                    style: SnippetFonts.display(
                      26.7,
                      color: c.white,
                      letterSpacing: -1,
                      height: 1.02,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _rise(
                  _rows[1],
                  8,
                  Text(
                    'Tap the bookmark while you swipe and the card will wait '
                    'for you here.',
                    textAlign: TextAlign.center,
                    style: SnippetFonts.body(13.3, color: c.mist, height: 1.4),
                  ),
                ),
                const SizedBox(height: 28),
                _rise(
                  _rows[2],
                  8,
                  SizedBox(
                    width: double.infinity,
                    child: PillButton(
                      key: const Key('pick-a-verse'),
                      label: 'Pick a verse',
                      onPressed: widget.onPickVerse,
                      background: c.lime,
                      foreground: c.ink,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedArch extends CustomPainter {
  const _DashedArch(this.line);

  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    const archWidth = 144.0;
    final left = (size.width - archWidth) / 2;
    final r = archWidth / 2;
    final paint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(left, size.height)
      ..lineTo(left, r)
      ..arcToPoint(Offset(left + archWidth, r), radius: Radius.circular(r))
      ..lineTo(left + archWidth, size.height);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DashedArch old) => old.line != line;
}
