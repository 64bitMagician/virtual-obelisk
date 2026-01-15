import 'package:art_platform/ui/widgets/upload_dialog.dart';
import 'package:art_platform/ui/widgets/profile_header.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/art_post.dart';
import '../../data/repositories/database_repository.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_gallery_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseRepository _repository = DatabaseRepository();
  final AuthRepository _authRepo = AuthRepository();
  final User? user = FirebaseAuth.instance.currentUser;

  final _bioController = TextEditingController();
  final _nameController = TextEditingController();

  String get defaultName => user?.email?.split('@')[0] ?? "Artist";

  Future<void> _changeAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image != null && user != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Updating avatar...")),
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('avatars/${user!.uid}.jpg');

        final Uint8List imageData = await image.readAsBytes();
        await storageRef.putData(
          imageData,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final String downloadUrl = await storageRef.getDownloadURL();

        await _repository.updateUserProfile(
          uid: user!.uid,
          avatarUrl: downloadUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Avatar updated successfully!")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: $e")),
          );
        }
      }
    }
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UploadDialog(),
    );
  }

  void _showEditDialog(String currentName, String currentBio) {
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
                decoration: const InputDecoration(labelText: "Display Name")),
            const SizedBox(height: 10),
            TextField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: "Bio"),
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _repository.updateUserProfile(
                  uid: user!.uid,
                  displayName: _nameController.text,
                  bio: _bioController.text);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context),
        label: const Text("Create"),
        icon: const Icon(Icons.add),
      ),
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
                StreamBuilder<Map<String, dynamic>?>(
                    stream: _repository.getProfileStream(user!.uid),
                    builder: (context, snapshot) {
                      final data = snapshot.data;

                      final Map<String, dynamic> headerMap = {
                        'uid': user!.uid,
                        'name': data?['displayName'] ?? defaultName,
                        'bio': data?['bio'] ?? "No bio yet...",
                        'avatarUrl': data?['avatarUrl'] ?? "https://robohash.org/${user?.uid}?set=set4",
                        'rank': data?['rank'] ?? 'Beginner',
                        'followers': data?['followers'] ?? 0,
                        'following': data?['following'] ?? 0,
                        'likes': data?['likes'] ?? 0,
                      };

                      return ProfileHeader(
                        userData: headerMap, // Fixed parameter name
                        onAvatarTap: _changeAvatar,
                        onEditProfile: () => _showEditDialog(
                            headerMap['name'],
                            headerMap['bio']
                        ),
                      );
                    }),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.grid_on, color: Colors.deepPurple),
                      Icon(Icons.bookmark_border, color: Colors.grey)
                    ]),
                const SizedBox(height: 16),

                StreamBuilder<List<ArtPost>>(
                  stream: _repository.getUserPosts('me'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text("No art uploaded yet."));
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

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserGalleryScreen(
                                  posts: posts,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: Colors.grey[900],
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (ctx, err, stack) =>
                              const Icon(Icons.broken_image),
                            ),
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