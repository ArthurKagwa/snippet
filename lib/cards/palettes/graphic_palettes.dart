import 'package:flutter/painting.dart';

import '../card_palette.dart';

/// Color tokens for the graphic card styles: Riso Loud, Swiss, Cobalt Arch.
abstract final class GraphicPalettes {
  static const Color _cobalt = Color(0xFF2433D6);
  static const Color _lime = Color(0xFFD9F75B);
  static const Color _stone = Color(0xFFF1EEE8);
  static const Color _cobaltInk = Color(0xFF10133F);

  // Riso Loud
  static const Color _risoInk = Color(0xFF141414);
  static const Color _risoYellow = Color(0xFFFFE14D);
  static const Color _risoPink = Color(0xFFFF4FA3);
  static const Color _risoBlue = Color(0xFF2F55D4);
  static const Color _risoWhite = Color(0xFFFFFFFF);

  static const List<CardVariant> riso = [
    CardVariant(
      id: 'pink',
      name: 'Pink',
      swatch: _risoPink,
      palette: CardPalette(
        background: _risoPink,
        ink: _risoInk,
        accent: _risoInk,
        surface: _risoYellow,
        surfaceInk: _risoInk,
        border: _risoInk,
      ),
    ),
    CardVariant(
      id: 'blue',
      name: 'Blue',
      swatch: _risoBlue,
      palette: CardPalette(
        background: _risoBlue,
        ink: _risoWhite,
        accent: _risoInk,
        surface: _risoYellow,
        surfaceInk: _risoInk,
        border: _risoInk,
      ),
    ),
    CardVariant(
      id: 'yellow',
      name: 'Yellow',
      swatch: _risoYellow,
      palette: CardPalette(
        background: _risoYellow,
        ink: _risoInk,
        accent: _risoInk,
        surface: _risoPink,
        surfaceInk: _risoInk,
        border: _risoInk,
      ),
    ),
    CardVariant(
      id: 'mint',
      name: 'Mint',
      swatch: Color(0xFF7FE0B5),
      palette: CardPalette(
        background: Color(0xFF7FE0B5),
        ink: _risoInk,
        accent: _risoInk,
        surface: _risoYellow,
        surfaceInk: _risoInk,
        border: _risoInk,
      ),
    ),
    CardVariant(
      id: 'black',
      name: 'Black',
      swatch: _risoInk,
      palette: CardPalette(
        background: _risoInk,
        ink: _risoYellow,
        accent: _risoYellow,
        surface: _risoPink,
        surfaceInk: _risoInk,
        border: _risoInk,
      ),
    ),
  ];

  // Swiss
  static const Color _swissPaper = Color(0xFFFFFFFF);
  static const Color _swissInk = Color(0xFF111111);
  static const Color _swissRed = Color(0xFFE1251B);

  static const List<CardVariant> swiss = [
    CardVariant(
      id: 'red',
      name: 'Red',
      swatch: _swissRed,
      palette: CardPalette(
        background: _swissPaper,
        ink: _swissInk,
        accent: _swissRed,
      ),
    ),
    CardVariant(
      id: 'cobalt',
      name: 'Cobalt',
      swatch: _cobalt,
      palette: CardPalette(
        background: _swissPaper,
        ink: _swissInk,
        accent: _cobalt,
      ),
    ),
    CardVariant(
      id: 'orange',
      name: 'Orange',
      swatch: Color(0xFFF26B1D),
      palette: CardPalette(
        background: _swissPaper,
        ink: _swissInk,
        accent: Color(0xFFF26B1D),
      ),
    ),
    CardVariant(
      id: 'green',
      name: 'Green',
      swatch: Color(0xFF1F7A4D),
      palette: CardPalette(
        background: _swissPaper,
        ink: _swissInk,
        accent: Color(0xFF1F7A4D),
      ),
    ),
    CardVariant(
      id: 'inverted',
      name: 'Inverted',
      swatch: _swissInk,
      palette: CardPalette(
        background: _swissInk,
        ink: _swissPaper,
        accent: _swissRed,
      ),
    ),
  ];

  // Cobalt Arch
  static const List<CardVariant> cobaltArch = [
    CardVariant(
      id: 'cobalt',
      name: 'Cobalt',
      swatch: _cobalt,
      palette: CardPalette(
        background: _cobalt,
        ink: _cobaltInk,
        accent: _lime,
        surface: _stone,
        surfaceInk: _cobaltInk,
      ),
    ),
    CardVariant(
      id: 'ink',
      name: 'Ink',
      swatch: _cobaltInk,
      palette: CardPalette(
        background: _cobaltInk,
        ink: _cobaltInk,
        accent: _lime,
        surface: _stone,
        surfaceInk: _cobaltInk,
      ),
    ),
    CardVariant(
      id: 'lime',
      name: 'Lime',
      swatch: _lime,
      palette: CardPalette(
        background: _lime,
        ink: _stone,
        accent: _cobalt,
        surface: _cobaltInk,
        surfaceInk: _stone,
      ),
    ),
    CardVariant(
      id: 'pink',
      name: 'Pink',
      swatch: _risoPink,
      palette: CardPalette(
        background: _risoPink,
        ink: _cobaltInk,
        accent: _cobalt,
        surface: _stone,
        surfaceInk: _cobaltInk,
      ),
    ),
  ];
}
