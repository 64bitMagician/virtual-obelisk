import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/repositories/database_repository.dart';
import 'package:go_router/go_router.dart';

class ArtPostOptions extends StatelessWidget {
  final ArtPost post;
  final bool isVisible;
  final VoidCallback onUserInteracted;
  final DatabaseRepository _repo = DatabaseRepository();


  ArtPostOptions({
    super.key,
    required this.post,
    required this.isVisible,
    required this.onUserInteracted,
  });

  Future<bool> _checkIfAdmin(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] == 'admin';
  }

  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();

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
                hintText: "EX: AI-Generated, Spam, Copyright...",
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

              Navigator.pop(context);

              try {
                await _repo.submitReport(
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
                    // Shows the reason from submitReport() (Ex: "You have already reported this post.")
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
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

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text("Are you sure you want to permanently delete this artwork? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userDoc = await FirebaseFirestore.instance.collection('users').doc(post.userId).get();
                final currentPostCount = userDoc.data()?['posts'] ?? 0;
                await _repo.deletePost(post.id, post.userId, currentPostCount);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted.")));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete post.")));
                }
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: FutureBuilder<bool>(
          future: currentUid != null ? _checkIfAdmin(currentUid) : Future.value(false),
          builder: (context, snapshot) {
            final isAdmin = snapshot.data ?? false;
            final isOwner = post.userId == currentUid;

            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
              color: Colors.grey[900],
              onOpened: onUserInteracted,
              onSelected: (value) async {
                onUserInteracted();

                if (value == 'report') {
                  _showReportDialog(context);
                } else if (value == 'edit') {
                  context.push('/edit_post', extra: post);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit UI needs to be built")));
                } else if (value == 'delete') {
                  _showDeleteDialog(context);
                } else if (value == 'admin_deactivate') {
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(post.userId).get();
                  final currentPostCount = userDoc.data()?['posts'] ?? 0;
                  await _repo.adminDeactivatePost(post.id, post.userId, currentPostCount);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deactivated.")));
                } else if (value == 'admin_reactivate') {
                  await _repo.adminReactivatePost(post.id, post.userId);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post reactivated!")));
                }
              },
              itemBuilder: (BuildContext context) {
                return [
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

                  if (!isOwner) ...[
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(children: [Icon(Icons.flag, color: Colors.orange, size: 20), SizedBox(width: 8), Text("Report Post", style: TextStyle(color: Colors.white))]),
                    ),
                  ],

                  if (isAdmin) ...[
                    const PopupMenuDivider(),

                    if (!post.isDeactivated)
                      const PopupMenuItem(
                        value: 'admin_deactivate',
                        child: Row(children: [Icon(Icons.gavel, color: Colors.red, size: 20), SizedBox(width: 8), Text("ADMIN: Force Takedown", style: TextStyle(color: Colors.red))]),
                      ),

                    if (post.isDeactivated)
                      const PopupMenuItem(
                        value: 'admin_reactivate',
                        child: Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 20), SizedBox(width: 8), Text("ADMIN: Reactivate Post", style: TextStyle(color: Colors.green))]),
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