import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <--- Add this import
import 'config/routes.dart';
import 'firebase_options.dart';

// 1. Make main() 'async' so we can wait for Firebase to load
void main() async {
  // 2. This line is required when main is async
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Start Firebase using the "Passport" file you just made
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
      // Theme Configuration
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Art apps look better in dark mode
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),

      // Router Configuration
      routerConfig: router, // Connects to our routes.dart
    );
  }
}