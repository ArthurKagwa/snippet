import 'package:flutter/painting.dart';

import '../card_palette.dart';

/// Color tokens for the serif card styles: Vigil, Dawn, Night Watch.
abstract final class SerifPalettes {
  static const Color _lime = Color(0xFFD9F75B);

  // Vigil
  static const Color _vellum = Color(0xFFEFE6D2);
  static const Color _gold = Color(0xFFD4A84B);
  static const Color _goldDim = Color(0xFF8C6E33);

  static const List<CardVariant> vigil = [
    CardVariant(
      id: 'gilt',
      name: 'Gilt',
      swatch: Color(0xFF0F0D0B),
      palette: CardPalette(
        background: Color(0xFF0F0D0B),
        ink: _vellum,
        accent: _gold,
        accentDim: _goldDim,
      ),
    ),
    CardVariant(
      id: 'oxblood',
      name: 'Oxblood',
      swatch: Color(0xFF3A1114),
      palette: CardPalette(
        background: Color(0xFF3A1114),
        ink: _vellum,
        accent: _gold,
        accentDim: _goldDim,
      ),
    ),
    CardVariant(
      id: 'verdigris',
      name: 'Verdigris',
      swatch: Color(0xFF0F2E2A),
      palette: CardPalette(
        background: Color(0xFF0F2E2A),
        ink: _vellum,
        accent: _gold,
        accentDim: _goldDim,
      ),
    ),
    CardVariant(
      id: 'lapis',
      name: 'Lapis',
      swatch: Color(0xFF152350),
      palette: CardPalette(
        background: Color(0xFF152350),
        ink: _vellum,
        accent: _gold,
        accentDim: _goldDim,
      ),
    ),
    CardVariant(
      id: 'bone',
      name: 'Bone',
      swatch: _vellum,
      palette: CardPalette(
        background: _vellum,
        ink: Color(0xFF241C12),
        accent: Color(0xFF8C6E33),
        accentDim: Color(0xFFC9B48A),
      ),
    ),
  ];

  // Dawn
  static const List<CardVariant> dawn = [
    CardVariant(
      id: 'peach',
      name: 'Peach',
      swatch: Color(0xFFF7A58C),
      palette: CardPalette(
        background: Color(0xFFFFE3C2),
        backgroundEnd: Color(0xFFF7A58C),
        ink: Color(0xFF3B1F1A),
        accent: Color(0xFF8A3B2B),
      ),
    ),
    CardVariant(
      id: 'rose',
      name: 'Rose',
      swatch: Color(0xFFE58FA5),
      palette: CardPalette(
        background: Color(0xFFFFE1E8),
        backgroundEnd: Color(0xFFE58FA5),
        ink: Color(0xFF3D1621),
        accent: Color(0xFF8E2F4B),
      ),
    ),
    CardVariant(
      id: 'sky',
      name: 'Sky',
      swatch: Color(0xFF8DB8E8),
      palette: CardPalette(
        background: Color(0xFFE6F1FF),
        backgroundEnd: Color(0xFF8DB8E8),
        ink: Color(0xFF13263F),
        accent: Color(0xFF2B4F8A),
      ),
    ),
    CardVariant(
      id: 'sand',
      name: 'Sand',
      swatch: Color(0xFFD9B98A),
      palette: CardPalette(
        background: Color(0xFFF7EDDC),
        backgroundEnd: Color(0xFFD9B98A),
        ink: Color(0xFF3A2A14),
        accent: Color(0xFF7B5B22),
      ),
    ),
    CardVariant(
      id: 'dusk',
      name: 'Dusk',
      swatch: Color(0xFF4A3566),
      palette: CardPalette(
        background: Color(0xFF8A6BA8),
        backgroundEnd: Color(0xFF4A3566),
        ink: Color(0xFFF7EEFF),
        accent: Color(0xFFF2C6A0),
      ),
    ),
  ];

  // Night Watch
  static const List<CardVariant> nightWatch = [
    CardVariant(
      id: 'forest',
      name: 'Forest',
      swatch: Color(0xFF173F2C),
      palette: CardPalette(
        background: Color(0xFF173F2C),
        backgroundEnd: Color(0xFF0B2218),
        ink: Color(0xFFF3EBD8),
        accent: Color(0xFFD9B866),
      ),
    ),
    CardVariant(
      id: 'midnight',
      name: 'Midnight',
      swatch: Color(0xFF1B2447),
      palette: CardPalette(
        background: Color(0xFF1B2447),
        backgroundEnd: Color(0xFF0B0F24),
        ink: Color(0xFFEEF0FF),
        accent: Color(0xFFC3C9FF),
      ),
    ),
    CardVariant(
      id: 'ember',
      name: 'Ember',
      swatch: Color(0xFF4A1E14),
      palette: CardPalette(
        background: Color(0xFF4A1E14),
        backgroundEnd: Color(0xFF1E0A06),
        ink: Color(0xFFFBEADF),
        accent: Color(0xFFF2A65A),
      ),
    ),
    CardVariant(
      id: 'slate',
      name: 'Slate',
      swatch: Color(0xFF2E3338),
      palette: CardPalette(
        background: Color(0xFF2E3338),
        backgroundEnd: Color(0xFF121517),
        ink: Color(0xFFF1F2F0),
        accent: _lime,
      ),
    ),
    CardVariant(
      id: 'plum',
      name: 'Plum',
      swatch: Color(0xFF3D1F3F),
      palette: CardPalette(
        background: Color(0xFF3D1F3F),
        backgroundEnd: Color(0xFF1A0B1B),
        ink: Color(0xFFF8E9F4),
        accent: Color(0xFFE8B4D8),
      ),
    ),
  ];
}
