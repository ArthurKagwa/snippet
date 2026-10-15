import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/services.dart';

/// Asks an email account for its password and checks it before a
/// sensitive action. Returns true once the password is confirmed, false
/// when cancelled; a wrong password stays in the dialog with a message.
Future<bool> confirmPasswordDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) =>
        _PasswordConfirmDialog(title: title, body: body, action: action),
  );
  return ok ?? false;
}

class _PasswordConfirmDialog extends StatefulWidget {
  const _PasswordConfirmDialog({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final String action;

  @override
  State<_PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  final _password = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_checking) return;
    if (_password.text.isEmpty) {
      return setState(() => _error = 'Enter your password.');
    }
    final auth = Services.of(context).auth;
    final navigator = Navigator.of(context);
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await auth.confirmPassword(_password.text);
      navigator.pop(true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('Password check failed: $e');
      if (mounted) setState(() => _error = 'Could not check that. Try again.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.body),
          const SizedBox(height: 16),
          TextField(
            key: const Key('confirm-password-field'),
            controller: _password,
            obscureText: true,
            autofocus: true,
            enabled: !_checking,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _confirm(),
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _checking ? null : _confirm,
          child: Text(widget.action),
        ),
      ],
    );
  }
}
