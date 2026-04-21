import 'package:art_platform/ui/widgets/profile_screen_widgets/gallery_image.dart';
import 'package:art_platform/ui/widgets/profile_header.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:art_platform/data/models/art_post.dart';
import '../../data/repositories/database_repository.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String username; // We now accept the username from the Web URL!

  const OtherUserProfileScreen({
    super.key,
    required this.username,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final DatabaseRepository _repository = DatabaseRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      // Search the database by the username!
      stream: _repository.getProfileStreamByUsername(widget.username),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data;

        // If someone types a bad username in the URL
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("User Not Found")),
            body: Center(child: Text("The user @${widget.username} does not exist.")),
          );
        }

        // WE EXTRACT THE HIDDEN UID FROM THE DATABASE RESULT
        final String otherProfileUid = data['uid'];

        final Map<String, dynamic> headerMap = {
          'uid': otherProfileUid,
          'username': data['username'] ?? 'Unknown User',
          'displayName': data['displayName'] ?? "Artist",
          'bio': data['bio'] ?? "No bio yet...",
          'avatarUrl': data['avatarUrl'] ?? "default",
          'rank': data['rank'] ?? 'rankless',
          'followers': data['followers'] ?? 0,
          'following': data['following'] ?? 0,
          'likes': data['likes'] ?? 0
        };

        return Scaffold(
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
                    ProfileHeader(
                      userData: headerMap,
                      onEditProfile: null,
                      onAvatarTap: null,
                      profileUid: otherProfileUid,
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    const Icon(Icons.grid_on, color: Colors.deepPurple),
                    const SizedBox(height: 16),

                    // The Posts Gallery
                    StreamBuilder<List<ArtPost>>(
                      // WE PASS THE HIDDEN UID TO FETCH THE POSTS
                      stream: _repository.getUserPosts(otherProfileUid),
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
                              mainAxisSpacing: 10
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return GestureDetector(
                              // Update routing to use the username!
                              onTap: () => context.push("/user/${widget.username}/media_reader/$index", extra: otherProfileUid),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: GalleryImage(post: post),
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
  }
}