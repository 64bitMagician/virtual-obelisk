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

  // We turn on the Firebase "engine" within our app. We use "await" to stop the program until Firebase is fully
  // initialized (up and running).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // This line tells Firebase which keys and IDs to use.
  );

  runApp(const ArtApp());
}

class ArtApp extends StatelessWidget {
  const ArtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Art Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),

      routerConfig: router,
    );
  }
}