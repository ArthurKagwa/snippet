import 'package:flutter/material.dart';

import '../core/theme/snippet_colors.dart';
import '../core/theme/snippet_fonts.dart';

OverlayEntry? _current;

/// A toast drawn in the root overlay, so it shows above modal sheets and
/// their scrim (a SnackBar sits under them). Styled like the app's SnackBar
/// and replaces any overlay toast already showing.
///
/// [actionLabel] and [onAction] add a button, the way a SnackBar action does.
/// The toast still dismisses on its own.
void showOverlayToast(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final theme = Theme.of(context).snackBarTheme;
  final hasAction = actionLabel != null && onAction != null;
  _current?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _OverlayToast(
      message: message,
      theme: theme,
      actionLabel: hasAction ? actionLabel : null,
      onAction: hasAction ? onAction : null,
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
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final SnackBarThemeData theme;
  final VoidCallback onDone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_OverlayToast> createState() => _OverlayToastState();
}

class _OverlayToastState extends State<_OverlayToast>
    with SingleTickerProviderStateMixin {
  /// The whole life of the toast: in, hold, out. An action stays up longer
  /// so it can be tapped.
  late final AnimationController _life;

  late final CurvedAnimation _in = CurvedAnimation(
    parent: _life,
    curve: const Interval(0, 0.08, curve: Curves.easeOutCubic),
  );
  late final CurvedAnimation _out = CurvedAnimation(
    parent: _life,
    curve: const Interval(0.92, 1, curve: Curves.easeIn),
  );

  bool _closed = false;
  bool get _hasAction => widget.actionLabel != null && widget.onAction != null;

  @override
  void initState() {
    super.initState();
    _life = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _hasAction ? 4500 : 2800),
    )..addStatusListener(_onStatus);
    _life.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish();
  }

  void _finish() {
    if (_closed) return;
    _closed = true;
    widget.onDone();
  }

  void _onAction() {
    widget.onAction?.call();
    _life.stop();
    _finish();
  }

  @override
  void dispose() {
    _life.removeStatusListener(_onStatus);
    _in.dispose();
    _out.dispose();
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final ink = theme.contentTextStyle?.color ?? context.colors.ink;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: IgnorePointer(
          ignoring: !_hasAction,
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
                  padding: EdgeInsets.fromLTRB(
                    20,
                    _hasAction ? 4 : 14,
                    _hasAction ? 8 : 20,
                    _hasAction ? 4 : 14,
                  ),
                  child: _hasAction
                      ? Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.message,
                                style: theme.contentTextStyle,
                              ),
                            ),
                            TextButton(
                              key: const Key('overlay-toast-action'),
                              onPressed: _onAction,
                              style: TextButton.styleFrom(
                                foregroundColor: ink,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                minimumSize: const Size(48, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: SnippetFonts.body(
                                  15,
                                  weight: FontWeight.w700,
                                  color: ink,
                                ),
                              ),
                              child: Text(widget.actionLabel!),
                            ),
                          ],
                        )
                      : Text(widget.message, style: theme.contentTextStyle),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
