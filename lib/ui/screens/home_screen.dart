import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../data/models/art_post.dart';
import '../../data/repositories/database_repository.dart';
import '../widgets/art_post_card.dart';

/// HomeScreen of the Platform
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseRepository _repository = DatabaseRepository(); // Firestore connection

  // Manages the content visible in PageView. Manages transition animations, etc...
  late final PageController _pageController;

  // This Stream represents the Feed Posts
  late final Stream<List<ArtPost>> _postsStream;

  bool _isUiVisible = true; // starts of true
  Timer? _hideTimer;

  // the initial state of the HomeScreen Widget
  // We use it to configure stuff...
  void initState() {
    super.initState();
    _pageController = PageController();

    _postsStream = _repository.getFeedPosts();

    _startHideTimer();
  }

  // used to set state of _isUiVisible
  // When timer runs out, the fading transition effect takes place for data appearing above the content
  // Timer resets everytime this method is called. It also lasts 3 seconds.
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isUiVisible) { // if data visible, and also exists in the tree
        setState(() => _isUiVisible = false); // rebuild the HomeScreen widget with new state (ui==false)
      }
    });
  }

  // This method gets called when mouse has been moved within the HomeScreen Widget Area
  // If the UI info above the content of the post is invisible, we rebuild the widget with the new state,
  // making the UI info above content visible again
  // This method, resets the "mouse has been moved" timer, regardless of the state of the _isUiVisible
  void _handleMouseMove(PointerEvent details) {
    if (!_isUiVisible) {
      setState(() => _isUiVisible = true);
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

  // The visibal part of the widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion( // used to detect mouse activity within the region of it's child
        // The region is the whole region where the post is visible
        onHover: _handleMouseMove, // when mouse is moved within the region (not counted if stationary)
        // called when mouse enters the widget area (not called again if mouse moves within the region)
        onEnter: (_) => _handleMouseMove(const PointerHoverEvent()),
        child: StreamBuilder<List<ArtPost>>(
          stream: _postsStream, // the stream representing the feed posts
          builder: (context, snapshot) { // this retriggers everytime a new post arrives from stream
            if (snapshot.connectionState == ConnectionState.waiting) { // Loading Animation while fetching post list
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) { // if we have a list containing null, or empty list
              return const Center(
                child: Text(
                  "No art found.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            // if it's not fetching post, and we do actually retreived the list of posts,
            // we store it in this variable
            final posts = snapshot.data!;

            // Now we return (rebuild) with the new post fetched
            return Stack(
              children: [
                PageView.builder( // the tool that acts as a viewable collection of Widgets (ArtPostCard Widgets in our case)
                  controller: _pageController, // the controller which controls the PageView Widget. Responsible for Page Navigation
                  // ammount of posts (does not build all of them, only the current one and maybe previous and next pages to prevent loading times)
                  // it also keeps previously loaded pages built (maybe there is a limit...)
                  itemCount: posts.length, // determine, the size of the
                  // itemBuilder rebuilds itself when the controller calls the methods to go back or forth from the current Page
                  // it only does this for pages that have not already been built
                  itemBuilder: (context, index) { // ? index sure is passed by the controller...?
                    return ArtPostCard(
                      post: posts[index], // shows the post at the determined index
                      isUiVisible: _isUiVisible, // ArtPostCard also has it's own implementation with _isUiVisible for animating the Post information Overlay
                    );
                  },
                ),

                // Retracting Animation
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 600), // retraction animation duration
                  left: _isUiVisible ? 20 : -100, // on the left edge, from 20px right goes out of view -100px
                  top: 0,
                  bottom: 0,
                  child: AnimatedOpacity( // Fading Animation
                    duration: const Duration(milliseconds: 600), // fading animation duration
                    opacity: _isUiVisible ? 0.6 : 0.0, // the fading goes to 0 when ui is no longer visible
                    child: Center(
                      child: _buildNavButton( // method that creates the arrow button and it's function
                        Icons.chevron_left, // left arrow icon
                            () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                ),

                // Retracting Animation
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 600), // retraction animation duration
                  right: _isUiVisible ? 20 : -100, // on the right edge, from 20px left goes out of view -100px
                  top: 0,
                  bottom: 0,
                  child: AnimatedOpacity( // Fading animation
                    duration: const Duration(milliseconds: 600), // fading animation duration
                    opacity: _isUiVisible ? 0.6 : 0.0, // the fading goes to 0 when ui is no longer visible
                    child: Center(
                      child: _buildNavButton( // method that creates the arrow button and it's function
                        Icons.chevron_right, // right arrow icon
                            () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Returns the arrow button, the logic of the button resides within the received argument (the onTap callback function)
  // Here we just create the design of the arrow and throw in the logic received (onTap) within the onPressed: property of the IconButton
  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 48),
        onPressed: onTap,
      ),
    );
  }
}