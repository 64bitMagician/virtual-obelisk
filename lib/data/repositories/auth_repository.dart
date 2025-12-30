import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Get the current user (if logged in)
  User? get currentUser => _auth.currentUser;

  // 2. Listen to changes (Login -> Logout -> Login)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 3. Sign Up
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

  // 4. Sign In
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

  // 5. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}