import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/card_style.dart';
import '../../data/bible_models.dart';

/// The visual quote card. Wrap in a RepaintBoundary to export.
class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.passage,
    required this.style,
    required this.font,
    this.fontSize = 26,
    this.translationLabel = '',
  });

  final Passage passage;
  final CardStyle style;
  final CardFont font;
  final double fontSize;
  final String translationLabel;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(color: style.textColor, height: 1.35);
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: style.gradient,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 300,
                      child: Text(
                        '\u201C${passage.text}\u201D',
                        textAlign: TextAlign.center,
                        style: font.apply(base.copyWith(fontSize: fontSize)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(width: 40, height: 2, color: style.accentColor),
              const SizedBox(height: 10),
              Text(
                '${passage.reference}'
                '${translationLabel.isEmpty ? '' : ' \u00B7 $translationLabel'}',
                style: font.apply(
                  base.copyWith(
                    fontSize: 16,
                    color: style.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppTheme.appName,
                style: base.copyWith(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: style.textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
