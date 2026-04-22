import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionsDialog extends StatelessWidget {
  final String title;
  final String collectionName; // 'followers' or 'following'
  final String profileUid;

  const ConnectionsDialog({
    super.key,
    required this.title,
    required this.collectionName,
    required this.profileUid,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 400,
        height: 500,
        child: StreamBuilder<QuerySnapshot>(
          // Listen to the subcollection (followers or following)
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(profileUid)
              .collection(collectionName)
              .orderBy('timestamp', descending: true) // Show newest first
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // if snapshot null or there is no docs data in the collection
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No users found."));
            }

            final List<String> uids = snapshot.data!.docs.map((doc) => doc.id).toList();

            return ListView.builder(
              itemCount: uids.length, // how many followers/followings
              itemBuilder: (context, index) {
                final String connectionUid = uids[index]; // store uid of indexed document

                // For every UID, fetch that specific user's public data
                return FutureBuilder<DocumentSnapshot>(
                  // read the 'user' document of indexed user
                  future: FirebaseFirestore.instance.collection('users').doc(connectionUid).get(),
                  // and build the UI
                  builder: (context, userSnapshot) {
                    // if Future hasn't completed, waiting to fetch profile data...
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.grey),
                        title: Text("Loading..."),
                      );
                    }

                    // if Future finished, but came back with null
                    if (!userSnapshot.hasData) {
                      return const ListTile(title: Text("ERROR: Could not Fetch User Data"));
                    }

                    // if Future comes back with non-null data:
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;

                    final String username = userData!['username'] ?? 'ERROR: UNKNOWN USER';
                    final String avatarUrl = userData!['avatarUrl'] ?? 'default';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: avatarUrl == 'default'
                            ? const AssetImage('assets/icons/user-profile-icon.png') as ImageProvider
                            : NetworkImage(avatarUrl),
                      ),
                      title: Text(username),
                      onTap: () {
                        context.pop(); // Close the dialog
                        context.push("/user_profile/$username"); // Go to their profile
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text("Close"),
        ),
      ],
    );
  }
}