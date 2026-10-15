import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/firestore_library_backend.dart';
import 'firebase_options.dart';
import 'services/firebase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Offline stand-ins: local auth, cards kept on this device.
    debugPrint('Firebase unavailable, running locally: $e');
    runApp(SnippetApp());
    return;
  }
  runApp(
    SnippetApp(
      auth: FirebaseAuthService(),
      libraryBackend: (user) =>
          FirestoreLibraryBackend(FirebaseFirestore.instance, user.id),
    ),
  );
}
