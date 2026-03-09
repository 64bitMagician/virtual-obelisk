import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import 'screens/authentication_screen.dart';

/// This [AuthGate] widget acts like a Security Guard (or Bouncer) for our application.
/// It sits between the user and the screens they want to access.
/// Instead of navigating to different pages, it decides what widget to draw right now based on
/// the user's login status.
///
/// It uses a [StreamBuilder] to listen to Firebase Auth in real-time.
class AuthGate extends StatelessWidget {
  /// If the user passes the security check, this [child] Widget is what they are going to see
  ///
  /// It is supposed to reporesent the "VIP Area", the protected content
  final Widget child;

  /// Requires a [Widget] to be passed within the [child] property
  /// The widget will get stored within the [child] variable of the [AuthGate] class
  /// This way, the [AuthGate] class will be able to display the given [Widget] object, as a consequence
  /// of a valid user security check.
  const AuthGate({super.key, required this.child});

  // AuthGate uses a StreamBuilder within it's build method
  // This means that the Widgets (GUI), that reside within the 'builder:' property of the StreamBuilder
  // will update (re-render), based on the state of the output end of the Stream given within the 'stream:'
  // property.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>( // Data passing through the stream is of type User (Can be Null)
      stream: AuthRepository().authStateChanges, // Notifies about changes to the user's sign-in state (such as sign-in or sign-out).
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) { // if the output of the stream is a null value, it means user is signed out
          // so we redirect the user to the LoginScreen (Display the LoginScreen() Wiget)
          return const AuthenticationScreen();
        }

        // At this point, we are neither waiting, and we have value data coming out of the stream
        // so we return the child widget, which is what we constructed AuthGate(child: ) with
        // This child Widget is what we want to display to the user for his succesfull logged in status
        return child;
      },
    );
  }
}