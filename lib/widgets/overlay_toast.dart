import 'package:flutter/material.dart';

OverlayEntry? _current;

/// A toast drawn in the root overlay, so it shows above modal sheets and
/// their scrim (a SnackBar sits under them). Styled like the app's SnackBar
/// and replaces any overlay toast already showing.
void showOverlayToast(BuildContext context, String message) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final theme = Theme.of(context).snackBarTheme;
  _current?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _OverlayToast(
      message: message,
      theme: theme,
      onDone: () {
        if (_current != entry) return;
        entry.remove();
        _current = null;
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

class _OverlayToast extends StatefulWidget {
  const _OverlayToast({
    required this.message,
    required this.theme,
    required this.onDone,
  });

  final String message;
  final SnackBarThemeData theme;
  final VoidCallback onDone;

  @override
  State<_OverlayToast> createState() => _OverlayToastState();
}

class _OverlayToastState extends State<_OverlayToast>
    with SingleTickerProviderStateMixin {
  /// The whole life of the toast: in, hold, out.
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward().whenComplete(widget.onDone);

  late final Animation<double> _in = CurvedAnimation(
    parent: _life,
    curve: const Interval(0, 0.08, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _out = CurvedAnimation(
    parent: _life,
    curve: const Interval(0.92, 1, curve: Curves.easeIn),
  );

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _life,
            builder: (_, child) => Opacity(
              opacity: _in.value * (1 - _out.value),
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - _in.value)),
                child: child,
              ),
            ),
            child: Semantics(
              liveRegion: true,
              child: Material(
                color: theme.backgroundColor,
                shape: theme.shape,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Text(widget.message, style: theme.contentTextStyle),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
