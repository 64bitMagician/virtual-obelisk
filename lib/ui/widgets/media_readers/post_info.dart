import 'package:art_platform/data/models/art_post.dart';
import 'package:flutter/material.dart';

class PostInfo extends StatelessWidget {
  // Data which defines the ArtPostCard object
  final ArtPost post; // contains all data related to the ArtPost
  final bool postInformationVisible; // state variable for the fading and position effects of the post information widgets

  const PostInfo({super.key, required this.post, required this.postInformationVisible});

  @override
  Widget build(BuildContext context) {
    // This sits on top of the image
    // AnimatedPositioned is what creates the smooth sliding motion of your bottom information overlay when isUiVisible changes.
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500), // how much time it takes for the animation to complete
      bottom: postInformationVisible ? 0 : -150, // ? 0 if Ui is visible, -150 otherwise
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: postInformationVisible ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                post.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: post.authorAvatar=="default" ?
                    AssetImage('assets/icons/user-profile-icon.png') : NetworkImage(post.authorAvatar),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "by ${post.authorName}",
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
