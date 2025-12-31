import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';

class ArtPostCard extends StatelessWidget {
  final ArtPost post;

  const ArtPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black, // Background color for the "bars" of the image
      child: Stack(
        children: [
          // 1. The Full Scale Image
          Center(
            child: Image.network(
              post.imageUrl,
              fit: BoxFit.contain, // Shows 100% of image without cropping
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // 2. Info Overlay (Title/Author at the bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
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
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(post.authorAvatar),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "by ${post.authorName}",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}