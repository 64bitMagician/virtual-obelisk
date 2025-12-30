import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import 'screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  final Widget child; // The "Protected" App (The Shell)

  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthRepository().authStateChanges,
      builder: (context, snapshot) {
        // 1. Loading (Checking Firebase...)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Not Logged In -> Show Full Screen Login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 3. Logged In -> Show the Protected App (The Shell)
        return child;
      },
    );
  }
}