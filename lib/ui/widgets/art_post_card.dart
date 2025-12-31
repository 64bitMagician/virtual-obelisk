import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';

class ArtPostCard extends StatelessWidget {
  final ArtPost post;
  final bool isUiVisible; // Receive visibility state

  const ArtPostCard({super.key, required this.post, required this.isUiVisible});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Image.network(
              post.imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Info Overlay with Animation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            bottom: isUiVisible ? 0 : -150, // Slides down
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isUiVisible ? 1.0 : 0.0,
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
                          backgroundImage: NetworkImage(post.authorAvatar),
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
          ),
        ],
      ),
    );
  }
}