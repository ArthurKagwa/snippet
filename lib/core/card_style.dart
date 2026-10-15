import 'package:flutter/material.dart';

/// Background + text color combination for a quote card.
class CardStyle {
  const CardStyle({
    required this.id,
    required this.name,
    required this.gradient,
    required this.textColor,
    required this.accentColor,
  });

  final String id;
  final String name;
  final List<Color> gradient;
  final Color textColor;
  final Color accentColor;

  static const List<CardStyle> all = [
    CardStyle(
      id: 'dawn',
      name: 'Dawn',
      gradient: [Color(0xFFFFE3C2), Color(0xFFF7A58C)],
      textColor: Color(0xFF3B1F1A),
      accentColor: Color(0xFF8A3B2B),
    ),
    CardStyle(
      id: 'night',
      name: 'Night',
      gradient: [Color(0xFF0F172A), Color(0xFF312E81)],
      textColor: Color(0xFFF8FAFC),
      accentColor: Color(0xFFFCD34D),
    ),
    CardStyle(
      id: 'meadow',
      name: 'Meadow',
      gradient: [Color(0xFFD9F2D0), Color(0xFF6BBF8A)],
      textColor: Color(0xFF12331F),
      accentColor: Color(0xFF1F6B3F),
    ),
    CardStyle(
      id: 'parchment',
      name: 'Parchment',
      gradient: [Color(0xFFF5E9CF), Color(0xFFE2C896)],
      textColor: Color(0xFF3A2B14),
      accentColor: Color(0xFF7B5B22),
    ),
    CardStyle(
      id: 'ocean',
      name: 'Ocean',
      gradient: [Color(0xFF0EA5E9), Color(0xFF1E3A8A)],
      textColor: Colors.white,
      accentColor: Color(0xFFBAE6FD),
    ),
    CardStyle(
      id: 'mono',
      name: 'Mono',
      gradient: [Color(0xFFFFFFFF), Color(0xFFE5E7EB)],
      textColor: Color(0xFF111827),
      accentColor: Color(0xFF6B7280),
    ),
  ];
}

/// Font option; uses platform fonts so the app works fully offline.
class CardFont {
  const CardFont(
    this.id,
    this.name,
    this.family,
    this.fallback, {
    this.italic = false,
  });

  final String id;
  final String name;
  final String family;
  final List<String> fallback;
  final bool italic;

  TextStyle apply(TextStyle base) => base.copyWith(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  );

  static const List<CardFont> all = [
    CardFont('serif', 'Serif', 'serif', ['Georgia', 'Times New Roman']),
    CardFont('sans', 'Sans', 'sans-serif', ['Roboto', 'Helvetica']),
    CardFont('classic', 'Classic', 'serif', [
      'Georgia',
      'Times New Roman',
    ], italic: true),
    CardFont('mono', 'Mono', 'monospace', ['Courier', 'Courier New']),
  ];
}
