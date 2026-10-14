import 'package:art_platform/config/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/routes.dart';
import 'firebase_options.dart';

/// The entry-point of the Application
void main() async {
  // Normally, runApp() automatically initializes the bindings.
  // But since we initialize Firebase before that, we need to make sure that the bindings are already initialized.
  // Otherwise, an error will be thrown.
  // "Bindings" are the bridge that connects the framework (Flutter) to the engine (C++)
  // A "pipe system" which makes graphics render, and gesture data received and processed
  WidgetsFlutterBinding.ensureInitialized();

  // We turn on the Firebase "engine" within our app. We use "await" to stop the program until
  // Firebase is fully initialized (up and running).
  await Firebase.initializeApp(
    // "options" property tells Firebase which Keys and IDs to use,
    // depending on the platform that will be running our application.
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Only when started with: flutter run --dart-define=USE_EMULATORS=true
  // the app talks to the local Firebase Emulators instead of the real Firebase project.
  if (const bool.fromEnvironment('USE_EMULATORS')) {
    await _connectToFirebaseEmulators();
  }

  // The method responsible for kickstarting our application (rendering)
  runApp(const ArtApp()); // The first thing to be rendered will be the ArtApp Widget defined bellow
}

/// Connects Authentication, Firestore and Storage to the Firebase Emulator Suite running on this computer
/// (started with 'firebase emulators:start'). Used for testing the Security Rules without touching real data.
/// The ports must match the "emulators" section in firebase.json.
Future<void> _connectToFirebaseEmulators() async {
  // The Android emulator reaches the computer it runs on through 10.0.2.2, not localhost
  final String host = (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ? '10.0.2.2' : 'localhost';

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);

  debugPrint("USING FIREBASE EMULATORS ON $host");
}

/// The root widget of our application. The central unit from which everything begins.
/// It is directly given as an argument to *runApp()* method, thus it must return the [MaterialApp] widget.
/// Here, the returned [MaterialApp] widget is responsible for the top configurations of the application.
/// Such as the theme used, title, routes, etc...
class ArtApp extends StatelessWidget {
  const ArtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Art Platform',
      debugShowCheckedModeBanner: false, // get rid of top left ribbon on screen
      theme: AppTheme.lightTheme, // Assign the Light Theme
      darkTheme: AppTheme.darkTheme, // Assign the Dark Theme
      themeMode: ThemeMode.system, // Let system default settings determine which one to use
      routerConfig: router, // return the router configurations (navigation) from ./comfig/routes.dart
    );
  }
}