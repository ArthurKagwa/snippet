import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'data/app_settings.dart';
import 'data/bible_repository.dart';
import 'data/json_library_backend.dart';
import 'data/json_store.dart';
import 'data/library_repository.dart';
import 'features/shell/app_shell.dart';
import 'features/update/required_update_gate.dart';
import 'services/auth_service.dart';
import 'services/content_config_service.dart';
import 'services/export_service.dart';
import 'services/play_listing.dart';
import 'services/play_update.dart';
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
    bool? enforceAndroidUpdate,
    AndroidBuildReader? androidBuild,
    AndroidUpdateFlow? updateFlow,
    PlayListing? playListing,
  }) : this._(
         bible: bible ?? BibleRepository(),
         auth: auth ?? LocalAuthService(),
         contentConfig: contentConfig ?? const LocalContentConfigService(),
         export: export ?? const DeviceExportService(),
         reminders: reminders ?? const NoopVerseReminderService(),
         store: store ?? FileJsonStore(),
         libraryBackend: libraryBackend,
         now: now ?? DateTime.now,
         enforceAndroidUpdate: enforceAndroidUpdate,
         androidBuild: androidBuild ?? const PlatformAndroidBuild(),
         updateFlow: updateFlow ?? const PlatformAndroidUpdate(),
         playListing: playListing ?? const ExternalPlayListing(),
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
    required this.enforceAndroidUpdate,
    required this.androidBuild,
    required this.updateFlow,
    required this.playListing,
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
  final bool? enforceAndroidUpdate;
  final AndroidBuildReader androidBuild;
  final AndroidUpdateFlow updateFlow;
  final PlayListing playListing;

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
        home: RequiredUpdateGate(
          enforce: enforceAndroidUpdate,
          androidBuild: androidBuild,
          updateFlow: updateFlow,
          playListing: playListing,
          child: const AppShell(),
        ),
      ),
    );
  }
}
