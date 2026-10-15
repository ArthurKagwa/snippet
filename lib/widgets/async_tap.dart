import 'dart:async';

import 'package:flutter/widgets.dart';

/// A tap handler. When it returns a Future, the button that ran it ignores
/// further taps until the Future settles.
typedef TapAction = FutureOr<void> Function();

/// Shared tap state for buttons: [running] while a tap's Future is pending,
/// [pressed] while a finger is down (for press feedback).
mixin AsyncTap<T extends StatefulWidget> on State<T> {
  bool running = false;
  bool pressed = false;

  void setPressed(bool value) {
    if (pressed != value) setState(() => pressed = value);
  }

  Future<void> runTap(TapAction? action) async {
    if (running || action == null) return;
    final result = action();
    if (result is! Future) return;
    setState(() => running = true);
    try {
      await result;
    } finally {
      if (mounted) setState(() => running = false);
    }
  }
}
