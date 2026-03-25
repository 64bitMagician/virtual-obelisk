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
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  await _repository.updateUserData(uid: user!.uid, displayName: _nameController.text, bio: _bioController.text);
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
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _repository.getProfileStream(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { // Loading Animation while fetching post list
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;
        // we take the snaphot data (user data document data)
        // and store it in our own variable: headerMap

        final Map<String, dynamic> headerMap = {'uid': user!.uid, 'username': data?['username'], 'profileName': data?['profileName'] ?? defaultName, 'bio': data?['bio'] ?? "No bio yet...", 'avatarUrl': data?['avatarUrl'] ?? "default", 'rank': data?['rank'] ?? 'Beginner', 'followers': data?['followers'] ?? 0, 'following': data?['following'] ?? 0, 'likes': data?['likes'] ?? 0};

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(onPressed: () => _showUploadDialog(context), label: const Text("Create"), icon: const Icon(Icons.add)),
          appBar: AppBar(
            title: Text(headerMap['username']),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    StreamBuilder<Map<String, dynamic>?>(
                      // get user data document
                      // the builder will retrigger everytime changes to that document occur
                      stream: _repository.getProfileStream(user!.uid),
                      builder: (context, snapshot) {
                        return ProfileHeader(
                          userData: headerMap,
                          onAvatarTap: _changeAvatar,
                          onEditProfile:
                              () => _showEditDialog(
                                // you provide initial text to be shown in the text fields
                                headerMap['name'],
                                headerMap['bio'],
                              ),
                        );
                      },
                    ),
                    // Up 'til this point we constructed the Profile Header
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Gallery and Saved Posts Buttons
                    const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Icon(Icons.grid_on, color: Colors.deepPurple), Icon(Icons.bookmark_border, color: Colors.grey)]),
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => UserGalleryScreen(
                                          posts: posts, // Feed it the List of ArtPosts
                                          initialIndex: index, // index at which to display the corresponding image
                                        ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                // ClipRRect rounds corners of the wrapped Widget
                                borderRadius: BorderRadius.circular(8), // the roundness
                                child: Image.network(
                                  // the wrapped Widget, the Image
                                  post.imageUrl, // Pass the URL to the image
                                  // the way the image is inscribed within the available space
                                  // cover makes sure of no blank edges
                                  // but may give up on parts of the image if the right ratio is not met
                                  fit: BoxFit.cover,
                                  // loadingBuilder specifies the widget to display to the user while an image is still loading
                                  // this is within the grid (not the UserGalleryScreen)
                                  loadingBuilder: (contex, child, progress) {
                                    // child parameter represents the complete fetched image
                                    // when progress is null, the image has finished loading
                                    if (progress == null) return child;
                                    // And while the image is not finished loading (is loading)
                                    // we are returning this custom Circular Progress Indicator
                                    return Container(color: Colors.grey[900], child: const Center(child: CircularProgressIndicator()));
                                  },
                                  // The errorBuilder property requires a callback function, that asks to
                                  // return a widget to be displayed instead of the error that has occured,
                                  // only in case an error has occured
                                  // We will simply display a broken image icon
                                  errorBuilder: (context, err, stack) => const Icon(Icons.broken_image),
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
      },
    );
  } // end of State build()
}
