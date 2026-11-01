import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/firestore_library_backend.dart';
import 'firebase_options.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_content_config_service.dart';
import 'services/local_verse_reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait only, before the first frame, so a rotated device does not
  // flash landscape while Flutter starts.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // Date names for every locale, so Home's date follows the phone's region.
  await initializeDateFormatting();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Offline stand-ins: local auth, cards kept on this device.
    debugPrint('Firebase unavailable, running locally: $e');
    runApp(SnippetApp(reminders: LocalVerseReminderService()));
    return;
  }
  runApp(
    SnippetApp(
      auth: FirebaseAuthService(),
      contentConfig: FirebaseContentConfigService(),
      reminders: LocalVerseReminderService(),
      libraryBackend: (user) =>
          FirestoreLibraryBackend(FirebaseFirestore.instance, user.id),
    ),
  );
}
