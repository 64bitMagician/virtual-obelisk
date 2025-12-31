import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';
import '../../data/repositories/database_repository.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseRepository _repository = DatabaseRepository();
  final AuthRepository _authRepo = AuthRepository();
  final User? user = FirebaseAuth.instance.currentUser;

  // Controllers for the Edit Dialog
  final _bioController = TextEditingController();
  final _nameController = TextEditingController();

  // Helper for the initial name if the user hasn't set one yet
  String get defaultName {
    if (user?.email != null) {
      return user!.email!.split('@')[0];
    }
    return "Artist";
  }

  void _showEditDialog(String currentName, String currentBio) {
    // Fill the text fields with what is currently in Firestore
    _nameController.text = currentName;
    _bioController.text = currentBio;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Display Name")
            ),
            const SizedBox(height: 10),
            TextField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: "Bio"),
                maxLines: 3
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () async {
              await _repository.updateUserProfile(
                  uid: user!.uid,
                  displayName: _nameController.text,
                  bio: _bioController.text
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () async => await _authRepo.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // --- 1. HEADER SECTION (Wrapped in StreamBuilder for Persistence) ---
                StreamBuilder<Map<String, dynamic>?>(
                    stream: _repository.getProfileStream(user!.uid),
                    builder: (context, snapshot) {
                      // Extract data from Firestore or use defaults
                      final data = snapshot.data;
                      final currentName = data?['displayName'] ?? defaultName;
                      final currentBio = data?['bio'] ?? "No bio yet...";

                      return Column(
                        children: [
                          CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage("https://robohash.org/${user?.uid}?set=set4")
                          ),
                          const SizedBox(height: 16),
                          Text(
                              currentName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                          ),
                          Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                              child: Text(
                                  currentBio,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey)
                              )
                          ),
                          OutlinedButton.icon(
                              onPressed: () => _showEditDialog(currentName, currentBio),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text("Edit Profile")
                          ),
                        ],
                      );
                    }
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // --- 2. TAB SELECTOR ---
                const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.grid_on, color: Colors.deepPurple),
                      Icon(Icons.bookmark_border, color: Colors.grey)
                    ]
                ),
                const SizedBox(height: 16),

                // --- 3. ARTWORK GRID ---
                StreamBuilder<List<ArtPost>>(
                  stream: _repository.getUserPosts('me'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text("No art uploaded yet.")
                      );
                    }

                    final posts = snapshot.data!;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            post.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(color: Colors.grey[900]);
                            },
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}