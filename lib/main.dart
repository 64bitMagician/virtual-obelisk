import 'package:art_platform/config/app_theme.dart';
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

  // The method responsible for kickstarting our application (rendering)
  runApp(const ArtApp()); // The first thing to be rendered will be the ArtApp Widget defined bellow
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