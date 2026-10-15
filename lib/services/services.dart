import 'package:flutter/widgets.dart';

import '../data/app_settings.dart';
import '../data/bible_repository.dart';
import '../data/library_repository.dart';
import 'auth_service.dart';
import 'content_config_service.dart';
import 'export_service.dart';

/// Dependency container exposed through the widget tree so tests (and the
/// future Firebase wiring) can swap implementations.
class Services extends InheritedWidget {
  const Services({
    super.key,
    required this.bible,
    required this.auth,
    required this.contentConfig,
    required this.export,
    required this.library,
    required this.settings,
    required super.child,
  });

  final BibleRepository bible;
  final AuthService auth;
  final ContentConfigService contentConfig;
  final ExportService export;
  final LibraryRepository library;
  final AppSettings settings;

  static Services of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<Services>();
    assert(s != null, 'No Services above this context');
    return s!;
  }

  @override
  bool updateShouldNotify(Services old) =>
      bible != old.bible ||
      auth != old.auth ||
      contentConfig != old.contentConfig ||
      export != old.export ||
      library != old.library ||
      settings != old.settings;
}
