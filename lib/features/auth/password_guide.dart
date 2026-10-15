import 'package:flutter/material.dart';

import '../../core/theme/snippet_colors.dart';
import '../../core/theme/snippet_fonts.dart';

/// One thing a new password must have. Firebase enforces the same rules
/// through the project's password policy.
class PasswordRule {
  const PasswordRule(this.label, this.test);

  final String label;
  final bool Function(String password) test;
}

final List<PasswordRule> passwordRules = [
  PasswordRule('At least 8 characters', (p) => p.length >= 8),
  PasswordRule(
    'Upper and lowercase letters',
    (p) => p.contains(RegExp(r'[A-Z]')) && p.contains(RegExp(r'[a-z]')),
  ),
  PasswordRule('At least one number', (p) => p.contains(RegExp(r'[0-9]'))),
];

bool meetsPasswordRules(String password) =>
    passwordRules.every((r) => r.test(password));

/// Checklist under the new-password field; each rule ticks as it is met.
class PasswordGuide extends StatelessWidget {
  const PasswordGuide({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: 'Password requirements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final rule in passwordRules)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _Row(label: rule.label, met: rule.test(password), c: c),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.met, required this.c});

  final String label;
  final bool met;
  final SnippetColors c;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, ${met ? 'done' : 'not yet'}',
      excludeSemantics: true,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Icon(
              met
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(met),
              size: 16,
              color: met ? c.cobalt : c.inkDim,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: SnippetFonts.body(12.5, color: met ? c.ink : c.inkDim),
            ),
          ),
        ],
      ),
    );
  }
}
