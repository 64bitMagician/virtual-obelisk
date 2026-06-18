import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BanUserDialog extends StatefulWidget {
  const BanUserDialog({super.key});

  @override
  State<BanUserDialog> createState() => _BanUserDialogState();
}

class _BanUserDialogState extends State<BanUserDialog> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isBanning = false;

  Future<void> _banUser() async {
    final username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty) return;

    setState(() => _isBanning = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception("Username not found.");
      }

      final userDocId = snapshot.docs.first.id;
      await FirebaseFirestore.instance.collection('users').doc(userDocId).update({
        'role': 'banned',
        'hasActivePosts': false, // will no longer be seen in feeds
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User '@$username' has been permanently banned."), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isBanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Ban User", style: TextStyle(color: Colors.red)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Enter the exact username of the account you want to permanently ban."),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              hintText: "e.g., cool_artist_99",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isBanning ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: _isBanning ? null : _banUser,
          child: _isBanning
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Ban User"),
        ),
      ],
    );
  }
}