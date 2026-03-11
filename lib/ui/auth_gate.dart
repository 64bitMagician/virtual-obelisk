import 'package:art_platform/ui/screens/profile_setup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import 'screens/authentication_screen.dart';
import '../data/repositories/database_repository.dart';

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

  // get connection with database_repository <--> Firestore
  DatabaseRepository _db = DatabaseRepository();

  /// Requires a [Widget] to be passed within the [child] property
  /// The widget will get stored within the [child] variable of the [AuthGate] class
  /// This way, the [AuthGate] class will be able to display the given [Widget] object, as a consequence
  /// of a valid user security check.
  AuthGate({super.key, required this.child});

  // AuthGate uses a StreamBuilder within it's build method
  // This means that the Widgets (GUI), that reside within the 'builder:' property of the StreamBuilder
  // will update (re-render), based on the state of the output end of the Stream given within the 'stream:'
  // property.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>( // Data passing through the stream is of type User (Can be Null)
      stream: AuthRepository().authStateChanges, // Notifies about changes to the user's sign-in state (such as sign-in or sign-out).
      builder: (context, snapshotUser) {
        if (snapshotUser.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshotUser.hasData) { // if the output of the stream is a null value, it means user is signed out
          // so we redirect the user to the LoginScreen (Display the LoginScreen() Wiget)
          return const AuthenticationScreen();
        }

        // user is signed in
        // now we need to check if his profile set up has been configured
        // if not, we return him the ProfileSetupScreen()
        // if his profile has been configured, we return him the widget that's been passed
        // to us at the construction of 'this' widget. The Widget we want to display if
        // the user passes the authentication Gate

        // A future builder will determine what to display while the fetching of seeing if the
        // user has profile is occuring
        return FutureBuilder<bool>(
          future: _db.hasProfile(snapshotUser.data!.uid),
          builder: (context, profileSnapshot) {
            try
            {
              if (profileSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // if the snapshot came empty (no data, failed to know if the user profile actually exists)
              // or if the snapshot came with data, and the data sugested that the user profile does not exist
              if (!profileSnapshot.hasData || profileSnapshot.data == false) {
                return const ProfileSetupScreen();
              }

              // user has profile, he can enter the app
              return child;
            }
            catch (e)
            {
              throw e;
            }
          },
        );
      },
    );
  }
}