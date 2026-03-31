import 'package:art_platform/data/models/art_post.dart';
import 'package:flutter/material.dart';

class ImageFeedWidget extends StatelessWidget {
  // Data which defines the ArtPostCard object
  final ArtPost post; // contains all data related to the ArtPost
  final bool postInformationVisible; // state variable for the fading and position effects of the post information widgets

  /// Constructor requires a [ArtPost] and [bool] to be passed to the [post] and [postInformationVisible] parameters.
  const ImageFeedWidget({super.key, required this.post, required this.postInformationVisible});

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
              post.mediaUrl, // the link to the image
              fit: BoxFit.contain, // this makes the image as large as possible and entirely visible
              width: double.infinity, // max stretch
              height: double.infinity, // max stretch
            ),
          ),
        ],
      ),
    );
  }
}
