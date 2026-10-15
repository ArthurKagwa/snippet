import 'package:flutter/material.dart';

/// Shows a short message that always dismisses itself. Replaces any toast
/// already showing so messages never queue up.
///
/// Flutter keeps a SnackBar with an action on screen until it is tapped
/// unless `persist` is false, so this sets it explicitly.
void showToast(
  ScaffoldMessengerState messenger,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final hasAction = actionLabel != null && onAction != null;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        persist: false,
        duration: Duration(seconds: hasAction ? 4 : 3),
        action: hasAction
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
}
