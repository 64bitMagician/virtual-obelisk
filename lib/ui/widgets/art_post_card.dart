import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';

class ArtPostCard extends StatelessWidget {
  // Data which defines the ArtPostCard object
  final ArtPost post; // contains all data related to the ArtPost
  final bool isUiVisible; // ? state variable for ...

  /// Constructor requires a [ArtPost] and [bool] to be passed to the [post] and [isUiVisible] parameters.
  const ArtPostCard({super.key, required this.post, required this.isUiVisible});

  // The visual representation of the ArtPostCard
  @override
  Widget build(BuildContext context) {
    // Here is the visible feed. The Container is the available area (stretched to maximum) where posts are displayed.
    return Container( // This container will stretch as much as possible within it's available area
      width: double.infinity, // max stretching on width
      height: double.infinity, // max stretching on height
      color: Colors.black, // Background color will be black
      child: Stack( // This makes widgets set upon each other possible. Like a stack viewed from the top.
        children: [ // ? the stack, order being the first is to the bottom
          Center( // we center the image
            child: Image.network( // we fetch the image over the network
              post.imageUrl, // the link to the image
              fit: BoxFit.contain, // this makes the image as large as possible and entirely visible
              width: double.infinity, // max stretch
              height: double.infinity, // max stretch
            ),
          ),
          // This sits on top of the image
          // AnimatedPositioned is what creates the smooth sliding motion of your bottom information overlay when isUiVisible changes.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500), // how much time it takes for the animation to complete
            bottom: isUiVisible ? 0 : -150, // ? 0 if Ui is visible, -150 otherwise
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