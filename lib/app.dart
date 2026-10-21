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
import 'services/verse_reminder_service.dart';

class SnippetApp extends StatelessWidget {
  /// Without [libraryBackend], saved cards stay in a file on this device;
  /// "this phone only" (anonymous) users' cards always do.
  SnippetApp({
    Key? key,
    BibleRepository? bible,
    AuthService? auth,
    ContentConfigService? contentConfig,
    ExportService? export,
    VerseReminderService? reminders,
    JsonStore? store,
    LibraryBackendFactory? libraryBackend,
    DateTime Function()? now,
  }) : this._(
         bible: bible ?? BibleRepository(),
         auth: auth ?? LocalAuthService(),
         contentConfig: contentConfig ?? const LocalContentConfigService(),
         export: export ?? const DeviceExportService(),
         reminders: reminders ?? const NoopVerseReminderService(),
         store: store ?? FileJsonStore(),
         libraryBackend: libraryBackend,
         now: now ?? DateTime.now,
         key: key,
       );

  SnippetApp._({
    super.key,
    required this.bible,
    required this.auth,
    required this.contentConfig,
    required this.export,
    required this.reminders,
    required JsonStore store,
    LibraryBackendFactory? libraryBackend,
    required this.now,
  }) : library = LibraryRepository(
         auth: auth,
         backendFor: (user) => libraryBackend == null || user.isAnonymous
             ? JsonLibraryBackend(store)
             : libraryBackend(user),
       ),
       settings = AppSettings(store);

  final BibleRepository bible;
  final AuthService auth;
  final ContentConfigService contentConfig;
  final ExportService export;
  final VerseReminderService reminders;
  final LibraryRepository library;
  final AppSettings settings;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    return Services(
      bible: bible,
      auth: auth,
      contentConfig: contentConfig,
      export: export,
      reminders: reminders,
      library: library,
      settings: settings,
      now: now,
      child: MaterialApp(
        title: AppTheme.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cobaltSwipe(),
        home: const AppShell(),
      ),
    );
  }
}
