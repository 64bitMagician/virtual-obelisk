import 'package:art_platform/ui/auth_gate.dart';
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
    required String password,
    required String username,
    required String profileName,
  }) async {
    try {
      // Fetch the Firestore Document (QuerySnapshot<>), that matches the value of it's 'username' property/key,
      // with the received username parameter. That would imply that there already exists a user within the
      // platform that already has the username provided as argument to this method.
      // If no such document can be found, meaning that no user exist with such provided username,
      // the returned result would be a QuerySnapshot<> that is empty | ".isEmpty==true"/".isNotEmpty==false".
      final userDocument = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      // if document is not empty (there already exists a user with the provided username)
      // we throw an exception
      if (userDocument.docs.isNotEmpty) {
        throw Exception("Username is already taken.");
      }

      //* by this point in the code, we did not find any user that has a
      //* username with the one provided as parameter.
      //* That means, the uniqueness of the username is checked.
      //* Now we need to check for email and password credentials
      //* And Firebase Authentication Package takes care of this

      // Create the user in Firebase Auth
      // If authentication credentials are invalid, a [FirebaseAuthException] will be thrown
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //* by this point in the code, username is unique and valid
      //* email and password are valid and an user has been created in Firebase Authentication SDK
      //* only thing left is to insert the data of this user in it's own unique Firestore Document
      //* under the 'users' collection. There will one Document created for each User.

      // ! The uid(user id), is not the username.
      // ! Both are unique, and they both represent the user, but in different contexts
      // ! The uid is hashed by Firebase, therefore more secure...

      // Store the extra details in Firestore
      // Use the UID from the newly created user as the document ID (for unique document ID)
      // .set overwrites data in a document, if no such document exist (as in our case),
      // a document will be created with that data written in it
      // ! So this structure right here is what defines the Documents within the 'users' collection
      // ! Change this if you want to change the structure of user Documents. But this will probably require
      // ! full wipe (deletion), of all current user documents (and probably everything else on Firebase),
      // ! unless a method to handle this will be created in the future
      // User is initialized with default avatarPicture, until he changes it himself
      await _db.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'profileName': profileName,
        'avatarPicture' : "default",
        'rank' : "novice",
        'createdAt': DateTime.now(),
      });

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors (weak password, email in use, etc.)
      throw Exception(e.message);
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