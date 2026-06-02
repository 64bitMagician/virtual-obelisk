import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/repositories/database_repository.dart';

class ArtPostLikeButton extends StatelessWidget {
  final ArtPost post;
  final bool isVisible;
  final VoidCallback onUserInteracted;

  const ArtPostLikeButton({
    super.key,
    required this.post,
    required this.isVisible,
    required this.onUserInteracted,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final DatabaseRepository repo = DatabaseRepository();

    // Check if the viewer is the owner
    final bool isOwner = currentUid == post.userId;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // We use a StreamBuilder to see if the current user liked it in real-time
            StreamBuilder<bool>(
              stream: currentUid != null ? repo.hasUserLikedPost(post.id, currentUid) : Stream.value(false),
              builder: (context, snapshot) {
                final hasLiked = snapshot.data ?? false;

                return IconButton(
                  iconSize: 36,
                  icon: Icon(
                    hasLiked ? Icons.favorite : Icons.favorite_border,
                    color: hasLiked ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () {
                    onUserInteracted(); // Reset the UI fade timer
                    repo.toggleLike(post.id);
                  },
                );
              },
            ),

            // Only show the number of likes if they are the owner
            if (isOwner)
              Text(
                '${post.likes}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4.0, color: Colors.black)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}