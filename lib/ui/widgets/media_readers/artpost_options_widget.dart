import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/repositories/database_repository.dart';

class ArtPostOptions extends StatelessWidget {
  final ArtPost post;
  final bool isVisible;
  final VoidCallback onUserInteracted; // To reset fade timer

  const ArtPostOptions({
    super.key,
    required this.post,
    required this.isVisible,
    required this.onUserInteracted,
  });

  // Checks if the logged-in user is an admin
  Future<bool> _checkIfAdmin(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] == 'admin';
  }

  // The actual Report Dialog!
  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final DatabaseRepository repo = DatabaseRepository();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Post", style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Why are you reporting this content?"),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "e.g., Spam, Inappropriate, Copyright...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              Navigator.pop(context); // Close dialog immediately

              try {
                // Call the backend function we just built!
                await repo.submitReport(
                    artworkId: post.id,
                    reason: reason
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Report submitted successfully."), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to submit report."), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Submit Report"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // Fading animation controlled by MediaReader's timer
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: FutureBuilder<bool>(
          // We check if the user is an admin so we can show them special tools
          future: currentUid != null ? _checkIfAdmin(currentUid) : Future.value(false),
          builder: (context, snapshot) {
            final isAdmin = snapshot.data ?? false;
            final isOwner = post.userId == currentUid;

            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
              color: Colors.grey[900],
              onOpened: onUserInteracted, // Keeps UI visible while menu is open
              onSelected: (value) {
                onUserInteracted(); // Reset timer after selection

                if (value == 'report') {
                  _showReportDialog(context);
                } else if (value == 'edit') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit feature coming soon!")));
                } else if (value == 'delete') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete feature coming soon!")));
                } else if (value == 'admin_ban') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin: Take down post (Coming soon)")));
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  // OPTIONS FOR THE OWNER
                  if (isOwner || isAdmin) ...[
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit, color: Colors.white, size: 20), SizedBox(width: 8), Text("Edit Post", style: TextStyle(color: Colors.white))]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, color: Colors.redAccent, size: 20), SizedBox(width: 8), Text("Delete Post", style: TextStyle(color: Colors.redAccent))]),
                    ),
                  ],

                  // OPTIONS FOR REGULAR VIEWERS
                  if (!isOwner) ...[
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(children: [Icon(Icons.flag, color: Colors.orange, size: 20), SizedBox(width: 8), Text("Report Post", style: TextStyle(color: Colors.white))]),
                    ),
                  ],

                  // OPTIONS FOR ADMINS ONLY
                  if (isAdmin && !isOwner) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'admin_ban',
                      child: Row(children: [Icon(Icons.gavel, color: Colors.red, size: 20), SizedBox(width: 8), Text("ADMIN: Force Takedown", style: TextStyle(color: Colors.red))]),
                    ),
                  ],
                ];
              },
            );
          },
        ),
      ),
    );
  }
}