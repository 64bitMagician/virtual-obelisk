import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:art_platform/data/models/art_post.dart';
import 'package:art_platform/data/repositories/database_repository.dart';

class ArtPostLikeButton extends StatefulWidget {
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
  State<ArtPostLikeButton> createState() => _ArtPostLikeButtonState();
}

class _ArtPostLikeButtonState extends State<ArtPostLikeButton> {
  final DatabaseRepository _repo = DatabaseRepository();
  late final String? _currentUid;
  late final bool _isOwner;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _isOwner = _currentUid == widget.post.userId;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !widget.isVisible,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<bool>(
              stream: _currentUid != null
                  ? _repo.hasUserLikedPost(widget.post.id, _currentUid)
                  : Stream.value(false),
              builder: (context, snapshot) {
                final hasLiked = snapshot.data ?? false;

                return IconButton(
                  iconSize: 36,
                  icon: Icon(
                    hasLiked ? Icons.favorite : Icons.favorite_border,
                    color: hasLiked ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () {
                    widget.onUserInteracted();
                    _repo.toggleLike(widget.post.id);
                  },
                );
              },
            ),

            if (_isOwner)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('artworks').doc(widget.post.id).snapshots(),
                builder: (context, snapshot) {
                  int currentLikes = widget.post.likes;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null && data.containsKey('likes')) {
                      currentLikes = data['likes'] as int;
                    }
                  }

                  return Text(
                    '$currentLikes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4.0, color: Colors.black)],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}