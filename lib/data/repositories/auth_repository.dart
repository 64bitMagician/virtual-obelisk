import 'package:art_platform/ui/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';

///
class AuthRepository {
  // _auth represents the handle to the Firebase Authentication SDK.
  // This is the only class meant to define the communication with the Firebase Authentication SDK.
  // Thus we mark the _auth variable as private through the use of '_'
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Synchronous (Instant) Getter
  // Can fetch the current user authenticated instantly
  // Can be either User (if authenticated)
  // or null if logged out
  User? get currentUser => _auth.currentUser;

  // Asynchronous (Stream) Getter
  // It listens for authentication state changes and emits a new value whenever:
  // A user signs in
  // A user signs out
  // The app starts and Firebase restores a logged-in session
  // It emits a User object when someone is signed in
  // or a null when no use is signed in
  // IMPORTANT: it only listens to local authentication state changes
  // meaning that it returns the authState of the User instance that is running the application
  // Every device that runs the app will have it's own User to represent itself
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Responsible for creating a new user to Firebase. It uses [FirebaseAuth] Class to take care of
  /// validity of credentials given.
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Responsible for signing the User within it's account
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Tells Firebase to kill the current session
  ///
  /// Calling this triggers [authStateChanges] stream to emit null.
  /// This will make the [AuthGate] that is listening to the [authStateChanges] stream
  /// to automatically redirect the user to the Login Screen.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}