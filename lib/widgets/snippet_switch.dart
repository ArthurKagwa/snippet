import 'package:flutter/material.dart';

/// Pill switch from the mockups (48 x 28).
class SnippetSwitch extends StatelessWidget {
  const SnippetSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    required this.onTrack,
    required this.onThumb,
    required this.offTrack,
    required this.offThumb,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;
  final Color onTrack;
  final Color onThumb;
  final Color offTrack;
  final Color offThumb;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 48,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: ShapeDecoration(
              color: value ? onTrack : offTrack,
              shape: const StadiumBorder(),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: value ? onThumb : offThumb,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
