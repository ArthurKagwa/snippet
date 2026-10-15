import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'data/app_settings.dart';
import 'data/bible_repository.dart';
import 'data/json_store.dart';
import 'data/library_repository.dart';
import 'features/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/content_config_service.dart';
import 'services/export_service.dart';
import 'services/services.dart';

class SnippetApp extends StatelessWidget {
  SnippetApp({
    super.key,
    BibleRepository? bible,
    AuthService? auth,
    ContentConfigService? contentConfig,
    ExportService? export,
    JsonStore? store,
  }) : bible = bible ?? BibleRepository(),
       auth = auth ?? LocalAuthService(),
       contentConfig = contentConfig ?? const LocalContentConfigService(),
       export = export ?? const DeviceExportService(),
       library = LibraryRepository(store ??= FileJsonStore()),
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
        home: const HomeScreen(),
      ),
    );
  }
}
