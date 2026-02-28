import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';
import '../widgets/art_post_card.dart';

/// The image viewer within the Profile of a User (sligthly different from the one at HomePage)
/// Click on one of the images of one's User Profile to instantiate the [UserGalleryScreen]
class UserGalleryScreen extends StatefulWidget {
  final List<ArtPost> posts; // List of ArtPost Objects
  // the user gallery will be instantiated with the image that is at index "initialIndex" within the User's posts
  // that being said, if you click on user's 4'th post, the user_gallery will open up showing the 4'th post
  // 4'th index within the "posts" list
  final int initialIndex;

  /// Constructor
  /// Feed it the a List<ArtPost> to display that ArtPosts
  /// Feed it the [initialIndex] to determine with what post the Viewer will open up
  const UserGalleryScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<UserGalleryScreen> createState() => _UserGalleryScreenState();
}

class _UserGalleryScreenState extends State<UserGalleryScreen> {
  // Manages the content visible in PageView. Manages transition animations, etc...
  late final PageController _pageController;
  bool _postInformationVisible = true; // Determines wether the information displayed above the ArtPost is visible
  Timer? _hideTimer; // counter for when to hide the information displayed above the ArtPost

  // we configure the PageController and start the HideTimer
  @override
  void initState() {
    super.initState();
    // we feed it the post at index [initialIndex] to display that post
    _pageController = PageController(initialPage: widget.initialIndex);
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel(); // reset the previous timer
    // and start it off again (3 seconds)
    _hideTimer = Timer(const Duration(seconds: 3), () {
      // After 3 seconds
      // if we are still on the viewer widget, and the display information is visible
      // we rebuild the image viewer, this time hiding display information
      if (mounted && _postInformationVisible) {
        setState(() => _postInformationVisible = false);
      }
    });
  }

  // This method gets called when mouse has been moved within the HomeScreen Widget Area
  // If the UI info above the content of the post is invisible, we rebuild the widget with the new state,
  // making the UI info above content visible again
  // This method, resets the "mouse has been moved" timer, regardless of the state of the _postInformationVisible
  void _handleMouseMove() {
    if (!_postInformationVisible) {
      setState(() => _postInformationVisible = true);
    }
    // Mouse has been moved, so start timer again
    _startHideTimer();
  }

  // this is called when the object is permanently removed from the tree

  @override
  void dispose() {
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion( // used to detect mouse activity within the region of it's child
        // The region is the whole region where the post is visible
        onHover: (_) => _handleMouseMove(), // when mouse is moved within the region (not counted if stationary)
        child: GestureDetector(
          onTap: _handleMouseMove, // this is phone case (if you tap), the display information gets visible
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.posts.length,
                itemBuilder: (context, index) {
                  return ArtPostCard(
                    post: widget.posts[index], // the index determines which post is visible
                    postInformationVisible: _postInformationVisible, // bool that will display or not the post information
                  );
                },
              ),

              // This animates the Arrow back button (postInformation...)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                top: _postInformationVisible ? 40 : -60, // determines the position transition
                left: 20,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _postInformationVisible ? 1.0 : 0.0, // determines the visibility
                  child: CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context), // quit User Post Image Viewer
                    ),
                  ),
                ),
              ),

              _buildArrow(
                isLeft: true,
                onTap: () {
                  _startHideTimer();
                  _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                }
              ),
              _buildArrow(
                isLeft: false,
                onTap: () {
                  _startHideTimer();
                  _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // this returns the arrow widgets
  // if isLeft is true, it will draw the left arrow
  // otherwise the right arrow
  // they include transition and opacity animation as well
  Widget _buildArrow({required bool isLeft, required VoidCallback onTap}) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      left: isLeft ? (_postInformationVisible ? 20 : -100) : null,
      right: !isLeft ? (_postInformationVisible ? 20 : -100) : null,
      top: 0,
      bottom: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _postInformationVisible ? 0.5 : 0.0, // determines opacity variation
        child: Center(
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: Icon(
                isLeft ? Icons.chevron_left : Icons.chevron_right, // left or right depending on what provided
                color: Colors.white,
                size: 40,
              ),
              onPressed: onTap,
            ),
          ),
        ),
      ),
    );
  }
}