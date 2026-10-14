import 'package:art_platform/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthRepository _authRepo = AuthRepository();

  /// Sends a Firebase password reset email to the signed in user's email address
  Future<void> _sendPasswordResetEmail() async {
    final String? email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset email sent to $email"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not send the password reset email. Try again later."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Account',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            subtitle: const Text('Update your personal details'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            // name, bio and avatar are edited on the profile screen
            onTap: () => context.go('/personal_profile'),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Password & Security'),
            subtitle: const Text('Send a password reset email'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _sendPasswordResetEmail,
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Other',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Virtual Obelisk',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.flutter_dash),
              );
            },
          ),

          const SizedBox(height: 20),

          Center(
            child: TextButton.icon(
              onPressed: () async => await _authRepo.signOut(),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}