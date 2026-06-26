import 'package:art_platform/ui/widgets/profile_screen_widgets/gallery_art_post.dart';
import 'package:art_platform/ui/widgets/dialogs/upload_dialog.dart';
import 'package:art_platform/ui/widgets/profile_screen_widgets/profile_header.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:art_platform/data/models/art_post.dart';
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

  final _bioController = TextEditingController();
  final _nameController = TextEditingController();

  // get name based on your email, otherwise default name will be Artist
  String get defaultName => user?.email?.split('@')[0] ?? "Artist";

  Future<void> _changeAvatar() async {
    final ImagePicker picker = ImagePicker();
    // opens up your local machine's storage, such that you can upload a local image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null && user != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updating avatar...")));

        // variable a certain document within Firebase Storage
        // the document represents the image data for the avatar image of the currently
        // authenticated user
        // ? if none document, it probably creates one
        final storageRef = FirebaseStorage.instance.ref().child('avatars/${user!.uid}.jpg');

        // convert picked local image to raw binary data, to store it in the document file
        final Uint8List imageData = await image.readAsBytes();
        // we replace the old data of the corresponding avatar image document with the new raw data
        // of the local image we selected
        await storageRef.putData(imageData, SettableMetadata(contentType: 'image/jpeg'));

        // this is the unique access/download URL associated with a Storage Document
        // We fetch the URL for our document that represents the avatar image data for the
        // currently authenticated user
        final String downloadUrl = await storageRef.getDownloadURL();

        // we update the authenticated user's data with new data
        // that is the new avatar url, for the new avatar image
        // PS: Firebase does not always change the unique URL with changing data document
        await _repository.updateUserData(uid: user!.uid, avatarUrl: downloadUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Avatar updated successfully!")));
        }
      } catch (e) {
        // if something goes wrong while trying to change your avatar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
        }
      }
    }
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const UploadDialog());
  }

  // you provide initial text to be shown in the text fields
  void _showEditDialog(String currentName, String currentBio) {
    _nameController.text = currentName;
    _bioController.text = currentBio;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Profile"),
            content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Display Name")), const SizedBox(height: 10), TextField(controller: _bioController, decoration: const InputDecoration(labelText: "Bio"), maxLines: 3)]),
            actions: [
              TextButton(onPressed: () => context.pop(), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  await _repository.updateUserData(uid: user!.uid, displayName: _nameController.text, bio: _bioController.text);
                  if (mounted) context.pop();
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _repository.getProfileStream(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { // Loading Animation while fetching post list
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;
        // we take the snaphot data (user data document data)
        // and store it in our own variable: userData

        final Map<String, dynamic> userData = {
          'uid': user!.uid,
          'username': data?['username'],
          'displayName': data?['displayName'] ?? defaultName,
          'bio': data?['bio'] ?? "No bio yet...",
          'avatarUrl': data?['avatarUrl'] ?? "default",
          'rank': data?['rank'] ?? 'Beginner',
          'posts': data?['posts'] ?? -1,
          'followers': data?['followers'] ?? -1,
          'following': data?['following'] ?? -1,
          'likes': data?['likes'] ?? 0,
          'artist_points': data?['artist_points'] ?? -1,
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(userData['username']),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ProfileHeader(
                      userData: userData,
                      onAvatarTap: _changeAvatar,
                      onEditProfile:
                          () => _showEditDialog(
                            // you provide initial text to be shown in the text fields
                            userData['displayName'],
                            userData['bio'],
                          ),
                      profileUid: _authRepo.currentUser!.uid,
                    ),
                    // Up 'til this point we constructed the Profile Header
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Gallery and Saved Posts Buttons
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Icon(Icons.grid_on, color: Colors.deepPurple)]),
                    const SizedBox(height: 16),

                    // The Posts Gallery
                    // Using StreamBuilder will trigger rebuilding of posts when any new post changes occur
                    StreamBuilder<List<ArtPost>>(
                      stream: _repository.getUserPosts('me'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } // loading animation when waiting for data to come out of the stream
                        // if snapshot has no data, or the data is empty (ex: empty list [])
                        // we return simple text indicating that no art has been uploaded yet
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(padding: EdgeInsets.all(32.0), child: Text("No art uploaded yet."));
                        }

                        final posts = snapshot.data!; // get all posts List<ArtPost>
                        // we return a GridView Widget to display the posts in a grid like manner
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, childAspectRatio: 1, crossAxisSpacing: 10, mainAxisSpacing: 10),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return GestureDetector(
                              // child: will be the area of the onTap Detection
                              // push the UserGalleryScreen on to the stack, indexed on the selected image
                              onTap: () => context.go("/personal_profile/media_reader/$index"),
                              child: ClipRRect(
                                // ClipRRect rounds corners of the wrapped Widget
                                borderRadius: BorderRadius.circular(8), // the roundness
                                child: GalleryArtPost(post: post),
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              // We should add a progression indicator if the users report that the upload button takes
              // to much time to open the UploadDialog

              // Check if user can upload (did not hit the upload limit cap)
              final canUpload = await _repository.canUserUploadToday(user!.uid);

              // We ensure the screen still exists after the database check
              if (!context.mounted) return;

              if (canUpload) {
                _showUploadDialog(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("You cannot upload more than 2 artworks a day.\nNote: This does not apply when uploading artworks for chains."),
                    backgroundColor: Colors.orange.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
              label: const Text("Upload"),
              icon: const Icon(Icons.add),
          ),
        );
      },
    );
  } // end of State build()
}
