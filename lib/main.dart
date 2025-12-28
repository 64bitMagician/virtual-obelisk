import 'package:flutter/material.dart';
import 'config/routes.dart'; // Import the router we just made

void main() {
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