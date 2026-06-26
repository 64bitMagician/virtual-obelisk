import 'package:art_platform/auth_gate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A static class. It can check for current state of users (logged in or not).
/// Responsible for backend logic of Signing Up/In/Out a User.
class AuthRepository {
  // _auth represents the handle to the Firebase Authentication SDK.
  // This is the only class meant to define the communication with the Firebase Authentication SDK.
  // Thus we mark the _auth variable as private through the use of '_'
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Establish connection with Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  /// validity of email and password credentials. This method also requires a [username] and [profileName]
  /// to be passed. [username] must be unique, otherwise an exception will be thrown.
  ///
  /// There is no build in method in firestore package to check for validity of a unique
  /// [username]. So we had to take care of it ourselves in this method.
  Future<void> signUp({
    required String email,
    required String password
  }) async {
    try
    {
      // create user account | if succesful, it also authenticates the user, also assigning the User to
      // [Firebase.instance.currentUser]
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(parseFirebaseAuthException(e));
    } catch (e) {
      throw Exception("Unexpected error occurred.");
    }
  }

  /// Responsible for signing the User within it's account
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }  on FirebaseAuthException catch (e) {
      throw Exception(parseFirebaseAuthException(e));
    } catch (e) {
      throw Exception("Unexpected error occurred.");
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

  String parseFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';

      case 'user-disabled':
        return 'This user account has been disabled.';

      case 'user-not-found':
        return 'No account found for this email.';

      case 'wrong-password':
        return 'Incorrect password.';

      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';

      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      default:
        return '${e.message ?? "Unknown error"}';
    }
  }
}