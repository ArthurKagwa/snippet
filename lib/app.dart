import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'data/bible_repository.dart';
import 'features/picker/picker_screen.dart';
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
  }) : bible = bible ?? BibleRepository(),
       auth = auth ?? LocalAuthService(),
       contentConfig = contentConfig ?? const LocalContentConfigService(),
       export = export ?? const DeviceExportService();

  final BibleRepository bible;
  final AuthService auth;
  final ContentConfigService contentConfig;
  final ExportService export;

  @override
  Widget build(BuildContext context) {
    return Services(
      bible: bible,
      auth: auth,
      contentConfig: contentConfig,
      export: export,
      child: MaterialApp(
        title: AppTheme.appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const PickerScreen(),
      ),
    );
  }
}
