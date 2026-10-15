/// Export shapes. Each lays the card out natively, so nothing is cropped.
enum CardShape {
  feed('Feed', '1:1', 1080, 1080),
  portrait('Portrait', '4:5', 1080, 1350),
  story('Story', '9:16', 1080, 1920);

  const CardShape(
    this.label,
    this.ratioLabel,
    this.pixelWidth,
    this.pixelHeight,
  );

  final String label;
  final String ratioLabel;
  final int pixelWidth;
  final int pixelHeight;

  double get aspectRatio => pixelWidth / pixelHeight;

  /// HD exports render at this multiple of the base size, so WhatsApp's HD
  /// option (and similar) has real detail to keep.
  static const int hdScale = 2;

  int exportWidth({required bool hd}) => hd ? pixelWidth * hdScale : pixelWidth;
  int exportHeight({required bool hd}) =>
      hd ? pixelHeight * hdScale : pixelHeight;

  /// Cards are composed at this logical width and scaled to fit.
  static const double designWidth = 304;

  double get designHeight => designWidth / aspectRatio;

  static CardShape byName(String? name) => CardShape.values.firstWhere(
    (s) => s.name == name,
    orElse: () => CardShape.portrait,
  );
}
