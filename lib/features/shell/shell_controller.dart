import 'package:flutter/widgets.dart';

import '../../data/bible_models.dart';

enum ShellTab { home, styles, saved }

/// Which tab is showing and which verse the Styles tab previews.
class ShellController extends ChangeNotifier {
  ShellTab _tab = ShellTab.home;
  Passage? _passage;
  String? _styleId;
  String? _variantId;
  int _openCount = 0;
  bool _allStylesRequested = false;

  ShellTab get tab => _tab;
  Passage? get passage => _passage;
  String? get styleId => _styleId;
  String? get variantId => _variantId;

  /// Bumps when a specific card is opened, so Styles jumps to its look.
  int get openCount => _openCount;

  void select(ShellTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
  }

  /// Styles in the nav: show the Styles tab with All styles on top.
  void openAllStyles() {
    _tab = ShellTab.styles;
    _allStylesRequested = true;
    notifyListeners();
  }

  /// Whether All styles was asked for since the last call.
  bool takeAllStylesRequest() {
    final requested = _allStylesRequested;
    _allStylesRequested = false;
    return requested;
  }

  /// The verse picked on Home; Styles follows it without switching tabs.
  void setPassage(Passage passage) {
    _passage = passage;
    notifyListeners();
  }

  /// Opens Styles on [passage], optionally at a saved style/colourway.
  void preview(Passage passage, {String? styleId, String? variantId}) {
    _passage = passage;
    if (styleId != null) {
      _styleId = styleId;
      _variantId = variantId;
      _openCount++;
    }
    _tab = ShellTab.styles;
    notifyListeners();
  }
}

/// Exposes the [ShellController] to the tabs.
class ShellScope extends InheritedNotifier<ShellController> {
  const ShellScope({
    super.key,
    required ShellController controller,
    required super.child,
  }) : super(notifier: controller);

  static ShellController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()!.notifier!;

  /// Without subscribing to changes (for callbacks).
  static ShellController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellScope>()!.notifier!;
}
