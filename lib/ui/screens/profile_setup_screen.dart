import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _usernameController = TextEditingController();
  final _profileNameController = TextEditingController();

  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _db = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _usernameError;

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _usernameError = null;
    });

    try {
      // fetch user id of authenticated user
      final uid = _auth.currentUser!.uid;

      // fetch texts from form fields
      final username = _usernameController.text.trim().toLowerCase();
      final profileName = _profileNameController.text.trim();

      if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
        setState(() {
          _usernameError = "Only lowercase letters, numbers, and _ allowed";
          _loading = false;
        });
        return;
      }

      // fetches reference to usernames and users documents corresponding to authenticated user
      // ? here probably also the /usernames and /users collections are created, because we call ".collection(...)"
      // ? probably they do not exist...
      final usernameRef = _db.collection('usernames').doc(username);
      final userRef = _db.collection('users').doc(uid);

      // Note: A transaction is a group of database operations that must happen togheter as one unit
      // Note: Two key rules:
      // Note: - All operations succeed → everything is saved
      // Note: - If anything fails → nothing is saved
      // Note: This is called atomicity

      // Note: We use transactions to solve a potential issue (Race Contition):
      // Note: Two different users could input the same username at the same time.
      // Note: That would generate two profiles with the same username, which we do not want.

      await _db.runTransaction((transaction) async {
        //
        final usernameDoc = await transaction.get(usernameRef);

        // If it exists it throwh error
        if (usernameDoc.exists) {
          setState(() {
            _usernameError = "Username already exists";
            _loading = false;
          });
          return;
        }

        // Document does not exist, so we create it. The name of Document is the actual username
        // it only contains the user id (unique hash value) associated with it
        await transaction.set(usernameRef, {
          "uid": uid,
        });

        // Create new Document representing the data of the Authenticated User
        await transaction.set(userRef, {
          "uid": uid,
          "username": username,
          "displayName": profileName,
          "bio": "No bio yet...",
          "avatarUrl": "default",
          "createdAt": FieldValue.serverTimestamp(),
          "rank": 'rankless',
        });
      });

      // if this point reached, account has been configured with the Corresponding Firestore Documents
      setState(() {
        _loading = false;
      });

      // If reached this point, everything is good we can navigate to home screen
      // we navigate the user to home screen, thus marking his entry to the application
      context.go("/");
      return;
    } catch (e) {
      print("TRANSACTION ERROR: $e");
    }
  }

  // we always need to dispose controllers...
  @override
  void dispose() {
    _usernameController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create your profile"),
        actions: [IconButton(onPressed: () async => await _auth.signOut(), icon: Icon(Icons.close))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              TextFormField( // username text field
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: const OutlineInputBorder(),
                  errorText: _usernameError,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter a username";
                  }

                  if (value.length < 3) {
                    return "Username too short";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField( // Profile Name text field
                controller: _profileNameController,
                decoration: const InputDecoration(
                  labelText: "Profile Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter a profile name";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // if loading indicate that it is futile to press the button
                  // also do nothing if user presses the button
                  // otherwise the button shall trigger the _createProfile method
                  onPressed: _loading ? null : _createProfile,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text("Create Profile"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}