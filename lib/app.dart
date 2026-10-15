import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'data/app_settings.dart';
import 'data/bible_repository.dart';
import 'data/json_library_backend.dart';
import 'data/json_store.dart';
import 'data/library_repository.dart';
import 'features/shell/app_shell.dart';
import 'services/auth_service.dart';
import 'services/content_config_service.dart';
import 'services/export_service.dart';
import 'services/services.dart';

class SnippetApp extends StatelessWidget {
  /// Without [libraryBackend], saved cards stay in a file on this device.
  SnippetApp({
    Key? key,
    BibleRepository? bible,
    AuthService? auth,
    ContentConfigService? contentConfig,
    ExportService? export,
    JsonStore? store,
    LibraryBackendFactory? libraryBackend,
  }) : this._(
         bible: bible ?? BibleRepository(),
         auth: auth ?? LocalAuthService(),
         contentConfig: contentConfig ?? const LocalContentConfigService(),
         export: export ?? const DeviceExportService(),
         store: store ?? FileJsonStore(),
         libraryBackend: libraryBackend,
         key: key,
       );

  SnippetApp._({
    super.key,
    required this.bible,
    required this.auth,
    required this.contentConfig,
    required this.export,
    required JsonStore store,
    LibraryBackendFactory? libraryBackend,
  }) : library = LibraryRepository(
         auth: auth,
         backendFor: libraryBackend ?? (_) => JsonLibraryBackend(store),
       ),
       settings = AppSettings(store);

  final BibleRepository bible;
  final AuthService auth;
  final ContentConfigService contentConfig;
  final ExportService export;
  final LibraryRepository library;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Services(
      bible: bible,
      auth: auth,
      contentConfig: contentConfig,
      export: export,
      library: library,
      settings: settings,
      child: MaterialApp(
        title: AppTheme.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cobaltSwipe(),
        home: const AppShell(),
      ),
    );
  }
}
